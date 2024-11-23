---
layout: post
title:  "Exposing the cluster to the internet from a home network"
date:   2024-11-23 00:00:00 +0000
categories: blog news update network
---

# Initial considerations
Since we are talking about a cluster deployed inside a home network, there's a few unorthodox things we have to do to expose the cluster to the world. In a cluster deployed in a cloud provider, what's usually done is using a cloud load balancer to send traffic to the cluster's ingress. In a home network, we would need to mess with the router's config to be able to route external traffic to the cluster, something that not all routers allow (mine for example). To overcome this, we will create a tunnel. I would recommend this approach even if your router is configurable, since it will probably be much easier to set up and is easily automated & reproducible. I think it's also more secure, since you do not have to open up ports in your router and traffic does not leave your cluster, but I'm no network security expert (yet 😉) so don't quote me on that.

# Cloudflared tunnel
The idea is to avoid touching the router at all by using a tunnel. We will use a [cloudflare tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) (formely known as argo tunnel), which we deploy in a pod that runs a small daemon connecting to the cloudflare network. This is a cool piece of technology that is great for small projects like this, as it is completely free and works pretty well.

![cloudflared-tunnel](/assets/images/cloudflared-tunnel.webp)

This works by setting up a cloudflared tunnel and one or more DNS records in the cloudflare portal that point to our tunnel. When a user visits our hostname, cloudflare will send that traffic to the pod running the tunnel, which will then forward everything to the ingress controller of the cluster. With this we leverage the tunnel to expose the cluster to the internet while maintaining the ingress controller as the entrypoint to the rest of the cluster. As a bonus, cloudflared also secures traffic to the tunnel with SSL and does the SSL termination when forwarding from the cloudflared pod to our ingress, so we don't have to worry about any of that.

![cloudflared.png](/assets/images/cloudflared.png)

## Setup
To create a tunnel we will follow the [official docs](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/). First, [install the cloudflared CLI](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/get-started/create-local-tunnel/).

Then, login to cloudflare with:
```bash
cloudflared tunnel login
```
and follow the instructions. Once authenticated, a `cert.pem` file will be generated that allows you to interact with cloudflare with the CLI.

Now create a new tunnel with
```bash
cloudflared tunnel create <tunnel-name>
```

This will generate a new file containing credentials for the tunnel to interact with cloudflare, spitting the location of this file and the tunnels ID in stdout.

Now we need to create the DNS CNAME records that will tell cloudflare to send traffic from the desired hostname to our tunnel. We do so with:
```bash
cloudflared tunnel route dns --overwrite-dns <tunnel-name> "<hostname>"
```
In my case, I want all traffic sent to [lucascajal.com](https://lucascajal.com) and any of its subdomains to be forwarded to the cluster, so I run
```bash
cloudflared tunnel route dns --overwrite-dns k8s-tunnel "lucascajal.com"
cloudflared tunnel route dns --overwrite-dns k8s-tunnel "*.lucascajal.com"
```
> Using the `--overwrite-dns` flag allows overwriting already existing records. This is not needed for a manual test setup, but is crucial when automating via make to make runs reproducible.

We now have defined a tunnel in cloudflare, and defined the DNS so that traffic is routed to it. We also have the credentials file that the daemon needs to talk with cloudflare, and now need to configure and deploy this daemon. 

For the configuration, we create a `config.yaml` file:
```yaml
tunnel: k8s-tunnel # Name of the tunnel
credentials-file: /etc/cloudflared/creds/credentials.json # Path to the credentials file
no-autoupdate: true # Disables tunnel autoupdates, which make no sense in K8s
ingress:
- service: http://ingress-nginx-controller.ingress-nginx
```
The `ingress` block defines how to forward traffic from the tunnel. You can imagine that we can go crazy with this section and start defining rules, so that the tunnel sends traffic to our apps based on hostnames. But, the control that cloudlfared provides is very basic compared to the capabilities of our cluster's ingress controller, so we will simply route all traffic to our ingress controller service (NGINX in this case) and define ingresses in the standard K8s way.

We use a Kustomize `configMapGenerator` to generate a ConfigMap from the file:
```yaml
configMapGenerator:
- name: cloudflared
  files:
  - config.yaml
```

We also need to mount the tunnel credentials file as a secret. For that we will first rename the file to `credentials.json`, since the original filename contains the tunnel ID which varies for each created tunnel, and then use Kustomize's secret generator:
```yaml
secretGenerator:
- name: tunnel-credentials
  files:
  - credentials.json
generatorOptions:
  labels:
    type: generated
  annotations:
    note: generated
```

Finally, we define the deployment for the daemon running the tunnel, which uses both the ConfigMap and the secret with the credentials:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudflared
spec:
  selector:
    matchLabels:
      app: cloudflared
  replicas: 1 # You could also consider elastic scaling for this deployment
  template:
    metadata:
      labels:
        app: cloudflared
    spec:
      containers:
      - name: cloudflared
        image: cloudflare/cloudflared:2024.10.1
        args:
        - tunnel
        # Points cloudflared to the config file, which configures what
        # cloudflared will actually do. This file is created by a ConfigMap
        # below.
        - --config
        - /etc/cloudflared/config/config.yaml
        - run
        livenessProbe:
          httpGet:
            # Cloudflared has a /ready endpoint which returns 200 if and only if
            # it has an active connection to the edge.
            path: /ready
            port: 2000
          failureThreshold: 1
          initialDelaySeconds: 10
          periodSeconds: 10
        volumeMounts:
        - name: config
          mountPath: /etc/cloudflared/config
          readOnly: true
        - name: creds
          mountPath: /etc/cloudflared/creds
          readOnly: true
      volumes:
      - name: creds
        secret:
          secretName: tunnel-credentials
      - name: config
        configMap:
          name: cloudflared
          items:
          - key: config.yaml
            path: config.yaml
```
You can check the whole definition in the [repo's cloudflared folder](https://github.com/lucascajal/k8s-playground/tree/main/cloudflared).

## Automation
This tunnel will be a core component of our cluster, so we need to automate it's setup so that it runs every time we create the cluster. For that we add a target to the makefile:
```make
.PHONY: tunnel
tunnel: ## Set up Cloudflared Tunnel
	$(info $(DATE) - creating cloudflared tunnel)
	@cert_path=$$(cloudflared tunnel create k8s-tunnel | sed -n 's/^Tunnel credentials written to \(.*\.json\).*/\1/p') && \
		mv $$cert_path cloudflared/credentials.json
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - adding DNS record"
	@cloudflared tunnel route dns --overwrite-dns k8s-tunnel "*.lucascajal.com"
	@cloudflared tunnel route dns --overwrite-dns k8s-tunnel "lucascajal.com"
	@echo "$(shell date -u +'%Y-%m-%dT%H:%M:%SZ') - deploying cloudflared tunnel"
	@kubectl apply -k cloudflared
```
This target assumes you already have the cloudflared CLI installed and have run the `cloudflared tunnel login` command. It does the following things:
- Creates a new tunnel and parses the path to the credentials file from `stdout`
- Renames and moves the credentials to the path specified in the secret generator
- Creates the two DNS records to route traffic from the domain name and all subdomains to the tunnel
- Deploys the tunnel using kustomize

We also add a helper target to delete the tunnel, as simply deleting the deployment in K8s will not remove it from cloudflare:
```make
.PHONY: tunnel_delete
tunnel_delete: ## Delete Cloudflared Tunnel
	$(info $(DATE) - deleting cloudflared tunnel)
	@kubectl delete -k cloudflared --ignore-not-found
	@rm -f cloudflared/credentials.json
	@cloudflared tunnel cleanup k8s-tunnel
	@sleep 5
	@cloudflared tunnel delete k8s-tunnel
```

# Securing the cloudflared pod
With the current setup, the pod running the tunnel only forwards traffic to the ingress controller, but it can actually reach any service in the cluster. We want to limit it's connectivity, so that it can only reach the ingress, and treat this pod like a [DMZ](https://en.wikipedia.org/wiki/DMZ_(computing)). We will look into this in a future post and link it here.

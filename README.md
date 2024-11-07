# [blog.lucascajal.com](https://blog.lucascajal.com)
Simple [jekyll](https://jekyllrb.com/) app to host my personal blog. Check it out [here](https://blog.lucascajal.com)! (it may not always be up 😉).

# Kubernetes deployment
The blog is hosted in a K8s cluster. You can see the deployment [here](https://github.com/lucascajal/k8s-playground/tree/main/apps/blog). This cluster uses the image created by the [Dockerfile](./Dockerfile), and mounts a volume with this repo cloned. A comanion container is also created to regularly pull the latest changes from this repo into the volume, so that whenever changes are made to this blog repo, they are reflected in the deployemnt, without needing to restart the pods.

To push the image to the container registry, run:
```bash
docker login registry.gitlab.com
docker build -t registry.gitlab.com/lucascajal1/k8s/blog:latest .
docker push registry.gitlab.com/lucascajal1/k8s/blog:latest
```
> If you update the docker image, the K8s deployment will need to be updated

# Local execution
To bring up the compose deployment, run:
```bash
sudo docker compose up --remove-orphans --force-recreate -d
```
> Add the `--build` flag to force the image rebuild.
> The website takes a few seconds to be available when installing dependencies on runtime

And stop it with:
```bash
sudo docker compose down
```

You can access the logs while the containers are running with:
```bash
sudo docker compose logs -t
```
See more options [in the docs](https://docs.docker.com/reference/cli/docker/compose/logs/)
> It would be cool to use tools like Elasticsearch in the future

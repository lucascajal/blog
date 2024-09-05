# [blog.lucascajal.com](https://blog.lucascajal.com)
Simple [jekyll](https://jekyllrb.com/) app to host my personal blog.

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

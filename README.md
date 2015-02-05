After starting the registry:
```plain
docker run -d -e DOCKER_PASSWORD='password' --link registry:registry -p '80:80' -p '443:443' -v /path/to/ssl/cert.crt:/etc/ssl/certs/docker-registry.crt -v /path/to/ssl/private.key:/etc/ssl/private/docker-registry.key joslynesser/registry-nginx
```

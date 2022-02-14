#!/bin/bash

# Run `certbot renew` to renew the certs in the persistent volume
# We do this via docker because the docker image is what has certbot installed.
docker run -v "/etc/letsencrypt:/etc/letsencrypt" --rm --entrypoint "" certbot/certbot sh -c "certbot renew"

# list the docker containers |
# find the nginx one |
# execute `nginx -s reload` on that container to reload the certs 
docker ps --format '{{.Names}}' | grep "^nginx-" | xargs -I {} docker exec {} "/usr/sbin/nginx" "-s" "reload"

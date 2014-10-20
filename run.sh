#!/bin/bash

ADMIN_PASSWORD=docker
PASSWORD_FILE=/etc/nginx/.htpasswd
NGINX_REGISTRY_URL=${REGISTRY_PORT#tcp://}

# nginx config
cat << EOF > /etc/nginx/sites-available/docker-registry.conf
upstream docker-registry {
  server $NGINX_REGISTRY_URL;
}

server {
  listen 80;

  proxy_set_header  Host              \$http_host;   # required for docker client's sake
  proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
  proxy_set_header  Authorization     "";            # see https://github.com/dotcloud/docker-registry/issues/170

  proxy_read_timeout               900;

  client_max_body_size 0; # disable any limits to avoid HTTP 413 for large image uploads

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
  chunked_transfer_encoding on;

  location / {
    auth_basic "Restricted";
    auth_basic_user_file $PASSWORD_FILE;
    proxy_pass http://docker-registry;
  }

  location /_ping {
    auth_basic off;
    proxy_pass http://docker-registry;
  }

  location /v1/_ping {
    auth_basic off;
    proxy_pass http://docker-registry;
  }
}
EOF

# create password file
if [ ! -e $PASSWORD_FILE ] ; then
    htpasswd -bc $PASSWORD_FILE admin $ADMIN_PASSWORD
fi

# enable site
ln -s /etc/nginx/sites-available/docker-registry.conf /etc/nginx/sites-enabled/docker-registry.conf

# start nginx
nginx

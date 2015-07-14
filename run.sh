#!/bin/bash

PASSWORD_FILE=/etc/nginx/.htpasswd

if [ "$DOCKER_USER" == "" ]; then
  DOCKER_USER="docker"
fi

if [ "$DOCKER_PASSWORD" == "" ] && [ ! -e $PASSWORD_FILE ]; then
  echo "Must set DOCKER_PASSWORD or mount $PASSWORD_FILE"
  exit 1
fi

# nginx config
cat << EOF > /etc/nginx/conf.d/docker-registry.conf
upstream docker-registry {
  server $REGISTRY_PORT_5000_TCP_ADDR:$REGISTRY_PORT_5000_TCP_PORT;
}

upstream docker-registry-debug {
  server $REGISTRY_PORT_5001_TCP_ADDR:$REGISTRY_PORT_5001_TCP_PORT;
}

server {
  listen 80;
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl;

  ssl_protocols TLSv1.1 TLSv1.2;
  ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';
  ssl_prefer_server_ciphers on;
  ssl_session_timeout 5m;
  ssl_session_cache shared:SSL:50m;

  ssl_certificate /etc/ssl/certs/docker-registry.crt;
  ssl_certificate_key /etc/ssl/private/docker-registry.key;

  add_header Strict-Transport-Security max-age=15768000;
  add_header Docker-Distribution-Api-Version: registry/2.0 always;

  proxy_set_header  Host              \$http_host;   # required for docker client's sake
  proxy_set_header  X-Real-IP         \$remote_addr; # pass on real client's IP
  proxy_set_header  X-Forwarded-Proto \$scheme;
  proxy_set_header  X-Forwarded-For   \$proxy_add_x_forwarded_for;
  proxy_set_header Docker-Distribution-Api-Version registry/2.0;
  proxy_read_timeout 900;

  # disable any limits to avoid HTTP 413 for large image uploads
  client_max_body_size 0;

  # required to avoid HTTP 411: see Issue #1486 (https://github.com/dotcloud/docker/issues/1486)
  chunked_transfer_encoding on;

  location /debug/health {
    proxy_pass http://docker-registry-debug;
  }

  location /v2/ {
    auth_basic "Restricted";
    auth_basic_user_file $PASSWORD_FILE;
    proxy_pass http://docker-registry;
  }
}
EOF

# create password file
if [ ! -e $PASSWORD_FILE ] ; then
  htpasswd -bc $PASSWORD_FILE $DOCKER_USER $DOCKER_PASSWORD
fi

# start nginx
exec nginx -g "daemon off;"

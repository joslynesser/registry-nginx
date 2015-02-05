#
# Nginx reverse proxy for library/registry
# based on library/nginx + bshaw/registry-nginx
#
FROM nginx:1.7.9
MAINTAINER Joslyn Esser <jesser@salesforce.com>

RUN \
  apt-get update && \
  apt-get install -y \
    apache2-utils \
    ca-certificates && \
  apt-get clean && \
  rm -r /var/lib/apt/lists/* && \
  rm /etc/nginx/conf.d/default.conf

COPY run.sh /usr/local/bin/run

WORKDIR /etc/nginx

EXPOSE 80
EXPOSE 443

CMD ["/usr/local/bin/run"]

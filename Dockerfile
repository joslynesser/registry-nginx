#
# Nginx reverse proxy for library/registry
# based on bshaw/registry-nginx
#

FROM ubuntu:14.04
MAINTAINER Joslyn Esser <jesser@salesforce.com>
RUN \
  add-apt-repository -y ppa:nginx/stable && \
  apt-get update && \
  apt-get install -y apache2-utils nginx && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx
RUN rm -f /etc/nginx/sites-enabled/default
ADD run.sh /usr/local/bin/run
VOLUME ["/data", "/etc/nginx/sites-enabled", "/var/log/nginx"]
WORKDIR /etc/nginx
CMD ["/usr/local/bin/run"]
EXPOSE 80
EXPOSE 443

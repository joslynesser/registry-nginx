#
# Nginx reverse proxy for docker-registry
# based on https://github.com/dockerfile/nginx
#

FROM dockerfile/ubuntu
MAINTAINER Brian Shaw <bshaw@appartus.net>
RUN \
  add-apt-repository -y ppa:nginx/stable && \
  apt-get update && \
  apt-get install -y nginx && \
  echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
  chown -R www-data:www-data /var/lib/nginx
RUN rm -f /etc/nginx/sites-enabled/default
ADD run.sh /usr/local/bin/run
ADD htpasswd /etc/nginx/.htpasswd
VOLUME ["/data", "/etc/nginx/sites-enabled", "/var/log/nginx"]
WORKDIR /etc/nginx
CMD ["/usr/local/bin/run"]
EXPOSE 80
EXPOSE 443

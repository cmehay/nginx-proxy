# Pull base image.
FROM onlinelabs/ubuntu
MAINTAINER Christophe Mehay cmehay@online.net

# Expose ports.
EXPOSE 80
EXPOSE 443

# Install port
ADD     sources.list    /etc/apt/sources.list.d/port.conf

# Install Nginx.
RUN \
  apt-get update && \
  apt-get install -y nginx && \
  rm -rf /var/lib/apt/lists/* && \
  chown -R www-data:www-data /var/lib/nginx

# Define mountable directories.
VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx"]

# Define working directory.
WORKDIR /etc/nginx

# Install/updates certificates
RUN apt-get update \
 && apt-get install -y -q --no-install-recommends \
    ca-certificates \
 && apt-get clean \
 && rm -r /var/lib/apt/lists/*

# Configure Nginx and apply fix for long server names
RUN echo "daemon off;" >> /etc/nginx/nginx.conf \
 && sed -i 's/# server_names_hash_bucket/server_names_hash_bucket/g' /etc/nginx/nginx.conf

# Install go
ENV GOPATH /tmp/go
RUN mkdir /tmp/go
RUN apt-get update && apt-get install -y -q golang git mercurial

# Build Forego
RUN go get -u github.com/ddollar/forego
# Install Forego
RUN cp /tmp/go/bin/forego /usr/local/bin/forego

ENV DOCKER_GEN_VERSION 0.3.6

# Build docker-gen
RUN go get -u github.com/jwilder/docker-gen
# Install docker-gen
RUN cp /tmp/go/bin/docker-gen /usr/local/bin/docker-gen

# Clean go build
RUN rm -rf /tmp/go

COPY . /app/
WORKDIR /app/

ENV DOCKER_HOST unix:///tmp/docker.sock

VOLUME ["/etc/nginx/certs"]

CMD ["forego", "start", "-r"]

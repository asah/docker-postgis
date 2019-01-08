#--------- Generic stuff all our Dockerfiles should start with so we get caching ------------
FROM debian:stable
MAINTAINER Tim Sutton<tim@kartoza.com>

RUN  export DEBIAN_FRONTEND=noninteractive
ENV  DEBIAN_FRONTEND noninteractive
RUN  dpkg-divert --local --rename --add /sbin/initctl

RUN apt-get -y update; apt-get -y install gnupg2 wget ca-certificates rpl pwgen
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
RUN wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

#-------------Application Specific Stuff ----------------------------------------------------

# We add postgis as well to prevent build errors (that we dont see on local builds)
# on docker hub e.g.
# The following packages have unmet dependencies:
RUN apt-get update; apt-get install -y postgresql-client-10 postgresql-common postgresql-10 postgresql-10-postgis-2.4 postgresql-10-pgrouting netcat

RUN apt-get install -y postgresql-server-dev-10 libedit-dev libselinux1-dev \
      libxslt-dev libpam0g-dev git flex make libssl-dev libkrb5-dev libcurl4-openssl-dev


# Open port 5432 so linked containers can see them
EXPOSE 5432

# Run any additional tasks here that are too tedious to put in
# this dockerfile directly.
ADD env-data.sh /env-data.sh
ADD setup.sh /setup.sh
RUN chmod +x /setup.sh
RUN /setup.sh

# We will run any commands in this when the container starts
ADD setup-conf.sh /
ADD setup-database.sh /
ADD setup-pg_hba.sh /
ADD setup-replication.sh /
ADD setup-ssl.sh /
ADD setup-user.sh /
ADD setup-end.sh /
ADD postgresql.conf /tmp/postgresql.conf

#---------------------------------------------------------------------------
# Citus
#
ENV CITUS_VERSION 8.1.0

RUN wget https://github.com/citusdata/citus/archive/v${CITUS_VERSION}.tar.gz && \
    tar xzf "v${CITUS_VERSION}.tar.gz" && \
    cd "citus-${CITUS_VERSION}" && \
    ./configure && \
    make install

RUN cd .. && \
    rm -rf "citus-${CITUS_VERSION}" "v${CITUS_VERSION}.tar.gz"

COPY 000-configure-stats.sh 001-create-citus-extension.sql /docker-entrypoint-initdb.d/
COPY pg_healthcheck /

HEALTHCHECK --interval=4s --start-period=6s CMD ./pg_healthcheck

RUN echo "shared_preload_libraries='citus'" >> /tmp/postgresql.conf

#---------------------------------------------------------------------------


RUN chmod +x /setup-end.sh
RUN /setup-end.sh

# Optimise postgresql
RUN echo "kernel.shmmax=543252480" >> /etc/sysctl.conf
RUN echo "kernel.shmall=2097152" >> /etc/sysctl.conf


ADD docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh
ENTRYPOINT /docker-entrypoint.sh


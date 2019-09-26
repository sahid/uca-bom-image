FROM ubuntu

## For apt to be noninteractive
ENV DEBIAN_FRONTEND noninteractive
ENV DEBCONF_NONINTERACTIVE_SEEN true

RUN apt-get update
RUN apt-get install software-properties-common apt-transport-https -y
RUN add-apt-repository ppa:ubuntu-cloud-archive/tools -y
RUN apt-get update
RUN apt-get install schroot cloud-archive-utils -y

## Preesed tzdata, update package index, upgrade packages and install needed software
RUN echo "tzdata tzdata/Areas select Europe" > /tmp/preseed.txt; \
    echo "tzdata tzdata/Zones/Europe select Paris" >> /tmp/preseed.txt; \
    debconf-set-selections /tmp/preseed.txt && \
    rm -f /etc/timezone && \
    rm -f /etc/localtime && \
    apt-get update && \
    apt-get install -y tzdata

# Used by mk-sbuilds
COPY .sbuildrc /root/
RUN usermod -g sbuild root

# Unable to build this docker image with enough priv so the mk-build
# will be done in-fly in jenkins conf with priviledged container..
#RUN mk-sbuild bionic
#RUN mk-sbuild xenial

COPY bom.sh /home/ubuntu/workdir/

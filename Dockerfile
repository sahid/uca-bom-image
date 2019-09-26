FROM ubuntu

RUN apt-get update
RUN apt-get install software-properties-common apt-transport-https -y
RUN add-apt-repository ppa:ubuntu-cloud-archive/tools -y
RUN apt-get update
RUN apt-get install schroot cloud-archive-utils -y

COPY .sbuildrc /root/
RUN usermod -g sbuild root

# Unable to build this docker image with enough priv so the mk-build
# will be done in-fly in jenkins conf with priviledged container..
#RUN mk-sbuild bionic
#RUN mk-sbuild xenial

COPY bom.sh /home/ubuntu/workdir/

FROM ubuntu

RUN apt-get update
RUN apt-get install software-properties-common apt-transport-https -y
RUN add-apt-repository ppa:ubuntu-cloud-archive/tools -y
RUN apt-get update
RUN apt-get install schroot cloud-archive-utils -y

COPY sbuild-bionic-amd64 /etc/schroot/chroot.d/
COPY bom.sh /home/ubuntu/workdir/

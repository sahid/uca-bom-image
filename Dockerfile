FROM ubuntu

RUN apt-get update
RUN apt-get install software-properties-common apt-transport-https -y
RUN add-apt-repository ppa:ubuntu-cloud-archive/tools -y
RUN apt-get update
RUN apt-get install cloud-archive-utils -y

COPY . /home/ubuntu/workdir

FROM ubuntu:latest
RUN apt update 
RUN apt install sudo git zip unzip wget subversion curl python nano dos2unix -y
RUN mkdir /root/.ssh
ADD ./provision/build_labkey.sh /tmp
RUN dos2unix /tmp/build_labkey.sh

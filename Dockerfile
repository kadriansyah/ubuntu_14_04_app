# image name: kadriansyah/ubuntu_14_04_app:v1
FROM ubuntu:14.04
MAINTAINER Kiagus Arief Adriansyah <kadriansyah@gmail.com>

ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# creating user grumpycat
RUN useradd -ms /bin/bash grumpycat
RUN gpasswd -a grumpycat sudo

# Enable passwordless sudo for users under the "sudo" group
RUN sed -i.bkp -e 's/%sudo\s\+ALL=(ALL\(:ALL\)\?)\s\+ALL/%sudo ALL=NOPASSWD:ALL/g' /etc/sudoers

# su as grumpycat
USER grumpycat
WORKDIR /home/grumpycat

# Add Public Key to New Remote User
RUN mkdir .ssh && chmod 700 .ssh
RUN echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDfji/gkqLV5YAC2UFuE4OK3XeGtCGzWdRUYpByVVk4MHiVseLq2gmi5MN+A8k6a4xYX4knse2Ps94Md4WfcA2dHjykLs5vqmK+CqLa+OI7Ls4C9LmY/S0RgQz+Fq4WO28vVwDjje3yG+1q5mP42y45sR5i9U0sF4KOVXI+gsysOZqJPmKEFBuFYrM7qxrMMj2raKw00Mqfw0e9o/n+5ycl/YPr7gN9OqzDAmI0Wkr1441zjpk7ygrjsW7tSKeP0HXRCb8yeE0rLXEmhO1HVa7NEzkCEknZT9GlqkxM1ZcBFZszOCsy2x2ZRuIcccFNYUDhdKAgv0xJNOyqpl3tvxPN kadriansyah@192.168.1.7" > /home/grumpycat/.ssh/authorized_keys
RUN chmod 600 .ssh/authorized_keys

# configure sshd
RUN sudo apt-get update && sudo apt-get install -y openssh-server
RUN sudo sed -i 's/Port 22/Port 3006/' /etc/ssh/sshd_config
RUN sudo sed -i 's/PermitRootLogin without-password/PermitRootLogin no/' /etc/ssh/sshd_config

# install wget
RUN sudo apt-get update && sudo apt-get install -y wget

# install anaconda
USER root
WORKDIR /home/grumpycat
RUN echo 'export PATH=/opt/conda/bin:$PATH' > /etc/profile.d/conda.sh && \
    wget https://repo.continuum.io/archive/Anaconda3-4.2.0-Linux-x86_64.sh -O /home/grumpycat/anaconda.sh && \
    /bin/bash /home/grumpycat/anaconda.sh -b -p /opt/conda && \
    rm /home/grumpycat/anaconda.sh
USER grumpycat
WORKDIR /home/grumpycat

# Configure NTP Synchronization, htop, git, curl
RUN sudo apt-get update && sudo apt-get install -y ntp && sudo apt-get install -y htop && sudo apt-get install -y git && sudo apt-get install -y curl libcurl3 libcurl3-dev

# NodeJS Debian and Ubuntu based Linux distributions
RUN sudo sudo apt-get update && sudo apt-get install -y build-essential
RUN sudo curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
RUN sudo apt-get install -y nodejs

# Installing Java 8
RUN sudo apt-get update && sudo apt-get install -y software-properties-common
RUN sudo \
    echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && \
    sudo add-apt-repository -y ppa:webupd8team/java && \
    sudo apt-get update && \
    sudo apt-get install -y oracle-java8-installer && \
    sudo rm -rf /var/lib/apt/lists/* && \
    sudo rm -rf /var/cache/oracle-jdk8-installer

# install passenger
RUN sudo apt-get update && sudo apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 561F9B9CAC40B2F7
RUN sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates
RUN sudo sh -c 'echo deb https://oss-binaries.phusionpassenger.com/apt/passenger trusty main > /etc/apt/sources.list.d/passenger.list'
RUN sudo apt-get update && sudo apt-get install -y nginx-extras passenger

# install rvm
# RUN sudo apt-get update && sudo gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
RUN curl -#LO https://rvm.io/mpapis.asc && gpg --import mpapis.asc
RUN \curl -sSL https://get.rvm.io | bash -s stable
RUN /bin/bash -c "source ~/.rvm/scripts/rvm"
RUN /bin/bash -l -c "rvm install 2.3.3"
RUN /bin/bash -l -c "rvm use 2.3.3 --default"

# Install Elasticsearch.
ENV DEB_PACKAGE elasticsearch-5.1.1.deb
RUN wget https://artifacts.elastic.co/downloads/elasticsearch/$DEB_PACKAGE && sudo dpkg -i $DEB_PACKAGE
RUN sudo update-rc.d elasticsearch defaults 95 10

# Installing Redis
RUN sudo apt-get install -y gcc
RUN sudo apt-get update && sudo apt-get install -y build-essential && sudo apt-get install -y tcl8.5
RUN wget http://download.redis.io/releases/redis-stable.tar.gz
RUN tar xvzf redis-stable.tar.gz
RUN cd redis-stable && make && sudo make install && cd utils && sudo ./install_server.sh

# forward request and error logs to docker log collector
RUN sudo ln -sf /dev/stdout /var/log/nginx/access.log && sudo ln -sf /dev/stderr /var/log/nginx/error.log

# Expose port 80 from the container to the host
EXPOSE 80 443
CMD ["sudo","nginx", "-g", "daemon off;"]

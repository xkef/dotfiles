FROM ubuntu:18.04


RUN apt-get update && apt-get install -y \
	openssl \
	net-tools \
	git \
	locales \
	sudo \
	dumb-init \
	vim \
	curl \
	wget \
	nmap \
	tmux \
	lsof \
	unzip \
	fontconfig

RUN apt-get install -y \
	apt-transport-https \
	ca-certificates \
	gnupg-agent \
	software-properties-common

RUN curl --silent -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
RUN add-apt-repository \
	"deb [arch=amd64] https://download.docker.com/linux/ubuntu \
	$(lsb_release -cs) \
	stable"
RUN apt-get update

RUN apt-get install -y docker-ce docker-ce-cli containerd.io

RUN locale-gen en_US.UTF-8
# We cannot use update-locale because docker will not use the env variables
# configured in /etc/default/locale so we need to set it manually.
ENV LC_ALL=en_US.UTF-8 \
	SHELL=/bin/bash


ENV DOCKER_HOST=unix:///var/run/docker.sock
RUN adduser --gecos '' --disabled-password coder && \
	echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

# replace shell with bash so we can source files
RUN rm /bin/sh && ln -s /bin/bash /bin/sh

# update the repository sources list
# and install dependencies
RUN apt-get update \
	&& apt-get install -y curl \
	&& apt-get -y autoclean

# nvm environment variables
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 6.11.0

RUN apt-get update && apt-get install -y build-essential libssl-dev \
	python python3 gnupg2

# install nvm
# https://github.com/creationix/nvm#install-script
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash

# install node and npm LTS
RUN source $NVM_DIR/nvm.sh \
	&& nvm install $NODE_VERSION \
	&& nvm alias default $NODE_VERSION \
	&& nvm use default \
	&& nvm install 10.16 \
	&& nvm use 10.16

# add node and npm to path so the commands are available
ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# confirm installation of node
RUN node -v
RUN npm -v





RUN npm i -g yarn \
	typescript \
	eslint \
	tslint \
	prettier \
	pm2 \
	serve

RUN wget https://github.com/cdr/code-server/releases/download/2.1665-vsc1.39.2/code-server2.1665-vsc1.39.2-linux-x86_64.tar.gz
RUN tar xzvf code-server2.1665-vsc1.39.2-linux-x86_64.tar.gz
RUN cp code-server2.1665-vsc1.39.2-linux-x86_64/code-server /bin
RUN mkdir -p /home/coder/.fonts
RUN wget https://github.com/ryanoasis/nerd-fonts/raw/master/patched-fonts/SourceCodePro/Regular/complete/Sauce%20Code%20Pro%20Nerd%20Font%20Complete%20Mono.ttf

RUN cp 'Sauce Code Pro Nerd Font Complete Mono.ttf' /home/.fonts
RUN fc-cache -f -v


USER coder


# RUN wget https://github.com/adobe-fonts/source-code-pro/archive/2.030R-ro/1.050R-it.zip

RUN mkdir -p /home/coder/dev1
RUN mkdir -p /home/coder/dev2
RUN mkdir -p /home/coder/dev3
RUN mkdir -p /home/coder/container_data/portainer
RUN mkdir -p /home/coder/container_data/pgadmin
RUN mkdir -p /home/coder/backend
RUN mkdir -p /home/coder/frontend
RUN echo 'sudo chmod 755 /var/run/docker.sock' >> /home/coder/.bashrc
EXPOSE 8080

ENTRYPOINT ["code-server", "--no-auth", "--host", "0.0.0.0", "--port", "8080"]

#!/bin/bash

check_package() {
    type $1 >/dev/null 2>/dev/null
    if [ $? -eq 0 ]; then
        echo $1 instalada
        return 1
    fi
    if [ 1 -eq $(dpkg -l | awk ' { print $2 }' | grep -w $1 | wc -l) ]; then 
        echo "$(dpkg -l | awk ' { print $2 }' | grep -w $1 | awk '{ print $2 }') instalada"
               return 1
    else 
        echo $1 "nao encontrada" 
        return 0 
    fi
}

setup_package() {
    check_package $1
    if [ $? -eq 0 ]; then 
        sudo apt update
        sudo apt install -y $1
    fi 
}

setup_aws() {
    setup_package awscli
    aws configure
}

setup_git() {
    setup_package git
    if [ ! -f ~/.ssh/id_ed25519.pub ]; then
        read -e -r -p "Qual seu usuário do github? : " gituser 
        ssh-keygen -t ed25519 -C $gituser
        git config --global $gituser
    fi

    echo "Cole a linha abaixo no github"
    cat ~/.ssh/id_ed25519.pub
    read -n1 -r -p "Pressione <ENTER> quando terminar"
}

setup_docker() {
    check_package docker
    if [ $? = 0 ]; then
        sudo apt-get remove -y docker docker-engine docker.io containerd runc
        sudo apt-get update
        sudo apt-get -y install \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg-agent \
        software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo apt-key fingerprint 0EBFCD88
        sudo add-apt-repository \
        "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
        stable"
        sudo apt-get update
        sudo apt-get -y install docker-ce docker-ce-cli containerd.io 
    fi
    #Para rodar o docker sem o sudo    
    if [ $(groups $USER | grep docker | wc -l) -eq 0 ]; then
        echo "setting up docker group"
        sudo groupadd docker
        sudo usermod -aG docker $USER
        newgrp docker
    fi
    if [ $(docker network ls | grep -w development | wc -l) -eq 0 ]; then
        docker network create --gateway 172.28.0.1 --subnet 172.28.0.0/16 development
    fi
    #Instalando docker-compose
    check_package docker-compose
    if [ $? = 0 ]; then
        echo "installing docker-compose" 
        local last_version=$(curl -s -L "https://github.com/docker/compose/releases/latest"|grep 'tag_name'|sed -E 's/.*=([^;]+)&.*/\1/' | head -1) 
        sudo curl -L "https://github.com/docker/compose/releases/download/$last_version/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose
    fi

}

setup_make() {
        setup_package make
}

setup_asdf() {
    if [ ! -f ~/.asdf ]; then
        cd
        git clone https://github.com/asdf-vm/asdf.git ~/.asdf
        cd ~/.asdf
        git checkout "$(git describe --abbrev=0 --tags)"
        if [ $(grep asdf.sh ~/.bashrc | wc -l) -eq 0 ]; then
            echo ". \$HOME/.asdf/asdf.sh" >>~/.bashrc
            echo ". \$HOME/.asdf/completions/asdf.bash">>~/.bashrc
            . ~/.profile
        fi
    fi
}

setup_code() {
    sudo snap install code --classic
}

setup_dbeaver() {
    sudo snap install dbeaver-ce
}

setup_flameshot() {
    sudo snap install flameshot
}

setup_basics() {
    sudo apt update
    sudo apt install -y xclip gnupg2 vim git autojump xvfb silversearcher-ag make awscli git nodejs npm curl openjdk-8-jre jq
}

setup_slack() {
    sudo snap install slack --classic
}

setup_discord() {
    sudo snap install discord
}

setup_npm() {
    check_package n
    if [ $? -eq 0 ]; then
        sudo npm install -g n nodemon
        sudo n 11.13.0
        if [ $(grep -e '^fs.inotify.max_user_watches' /etc/sysctl.conf | wc -l) -eq 0 ]; then
            sudo echo fs.inotify.max_user_watches=524288 >>/etc/sysctl.conf
            sudo sysctl -p
        fi
    fi
}



setup_zsh() {   
    cd
    echo "instalando Zsh" 
    sudo apt install zsh
    echo "instalando Oh My Zsh" 
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    cd
    echo "instalando Dracula Theme Gnome Terminal"
    sudo apt-get install dconf-cli
    if [ ! -d ~/gnome-terminal ]; then 
       cd 
       git clone https://github.com/dracula/gnome-terminal
       cd gnome-terminal 
       bash ./install.sh
       cd -
    fi
    cd
    echo "Instalando Spaceship"
    git clone https://github.com/denysdovhan/spaceship-prompt.git ~/.oh-my-zsh/custom/themes/spaceship-prompt
    ln -s ~/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme ~/.oh-my-zsh/custom/themes/spaceship.zsh-theme
    cd
    echo "Plugins do ZSH"
    git clone https://github.com/zdharma-continuum/zinit.git
    cd zinit/scripts
    bash ./install.sh
    cd
    echo "Adiciona syntax highlighting "
    git clone https://github.com/z-shell/F-Sy-H.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/F-Sy-H
    cd
    echo "Sugere comandos baseados no histórico"
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
    cd
    echo "Adiciona milhares de completition"
    git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:-${ZSH:-~/.oh-my-zsh}/custom}/plugins/zsh-completions
    cd
    echo "https://guinuxbr.com/en/posts/zsh+oh-my-zsh+starship/"
    echo "Instalando starship no Zsh"
    curl -sS https://starship.rs/install.sh | sh
}
setup_java_maven_node(){
   echo "Instalando java"
   asdf plugin-add java https://github.com/halcyon/asdf-java.git
   asdf install java adoptopenjdk-8.0.352+8
   asdf install java adoptopenjdk-17.0.5+8
   asdf install java adoptopenjdk-11.0.17+8
   asdf global java adoptopenjdk-11.0.17+8
   echo "Instalando maven"
   asdf plugin-add maven
   asdf install maven 3.5.4
   asdf install maven 3.8.6
   asdf global maven 3.8.6
   echo "Instalando Node"
   asdf plugin-add nodejs https://github.com/asdf-vm/asdf-nodejs.git
   asdf install nodejs 18.12.1
   asdf global nodejs 18.12.1
}

setup_portainer(){
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9443:9443 --name portainer --restart=always -v /var/run/docker.sock:/var/run/docker.sock -v portainer_data:/data portainer/portainer-ce:latest
}

setup_docker_compose(){
    cd
    sudo
    echo "Instalando Docker-compose"
    mkdir -p ~/.docker/cli-plugins/
    curl -SL https://github.com/docker/compose/releases/download/v2.14.2/docker-compose-linux-x86_64 -o ~/.docker/cli-plugins/docker-compose
    chmod +x ~/.docker/cli-plugins/docker-compose
}

setup_final(){
    cd
    echo "copiando zsh template para home"
    cp ~/Downloads/.zshrc ~/
    zinit self-update
}


setup_basics
setup_aws
setup_git
setup_docker
#setup_code
#setup_dbeaver
setup_asdf
#setup_npm
setup_slack
setup_discord
setup_flameshot
setup_zsh
setup_java_maven_node
setup_portainer
setup_docker_compose

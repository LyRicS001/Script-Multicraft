#!/bin/bash

output(){
    echo -e '\e[36m'$1'\e[0m';
}

warn(){
    echo -e '\e[31m'$1'\e[0m';
}

preflight(){
    output "Multicraft Installation Script Ubunto . . ."
    output "Script Em Construção V0.1"
    output "Copyright © 2022 By @LyRicS_."
    output ""
}

install_options(){
    output "Selecionar Qual Instalação que você deseja:"
    output "[1] Instalar Painel Sem FireWall."
    output "[2] Instalar Painel Com FireWall (Manutenção)."
    output "[3] Instalar Versões PocketMine (Manutenção)."
    output "[4] Instalar Versões Minecraft Java (Manutenção)."
    read -r choice
    case $choice in
        1 ) installoption=1
            output "Você selecionou a opção de instalação completo."
            ;;
        2 ) installoption=2
            output "Infelizmente este comando está em manutenção."
            ;;
        3 ) installoption=3
            output "Infelizmente este comando está em manutenção."
            ;;      
        4 ) installoption=4
            output "Infelizmente este comando está em manutenção."
            ;;                               
        * ) output "Modelo não selecionado, favor escolher alguma opção."
            install_options
    esac
}

senha_ft() {
    output "Inserir Uma Senha Segura De Nivél 3:"
    read -r senhanv3
    requerir_info
}

requerir_info() {
    output "Inserir Endereço De E-mail:"
    read -r email
    dns_check
}


dns_check(){
    output "Colocar Seu Dominio/FQDN (panel.domain.tld):"
    read -r FQDN

    output "DNS..."
    SERVER_IP=$(dig +short myip.opendns.com @resolver1.opendns.com -4)
    DOMAIN_RECORD=$(dig +short ${FQDN})
    if [ "${SERVER_IP}" != "${DOMAIN_RECORD}" ]; then
        output ""
        output "The entered domain does not resolve to the primary public IP of this server."
        output "Please make an A record pointing to your server's IP. For example, if you make an A record called 'panel' pointing to your server's IP, your FQDN is panel.domain.tld"
        output "If you are using Cloudflare, please disable the orange cloud."
        output "If you do not have a domain, you can get a free one at https://freenom.com"
        dns_check
    else
        output "Domain Correto. Continuando Trabalho..."
    fi
}

instalar_pacote1(){
    output "Atualizando Sistema/Pacote"
    apt-get update
    apt upgrade -y
    output "Instalando Dependencias De Pacotes"
    apt install -y apache2 apt-transport-https certbot python3-certbot-apache mysql-server php libapache2-mod-php php-mysql php-gd php-cli php-common php-mbstring php-ldap php-odbc php-pear php-xml php-xmlrpc php-bcmath php-pdo default-jdk git zip unzip
    output "Apache Mod. . ."
    a2enmod rewrite 

    apache2 
}

apache2() {
     output "Mudando Conexão Default..."
     sed -i '172s/None/All/' /etc/apache2/apache2.conf
     output "Configurando Arquivo De VirtualHost..."
     cd /etc/apache2/sites-available/
     echo "<VirtualHost *:80>
	ServerAdmin ${email}
	ServerName ${FQDN}
	DocumentRoot /var/www/html/multicraft
	ErrorLog ${APACHE_LOG_DIR}/error.log
	CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost> " > multicraft.conf

instalar_pacote2

}

instalar_pacote2(){
    output "Ativando Dominio VM Apache2"
    a2ensite multicraft.conf
    output "Desabilitando Config Default Apache2"
    a2dissite 000-default.conf
    output "Apache Reiniciando..."
    systemctl restart apache2 

    ssl_cerbot

}

ssl_cerbot(){
    output "Instalando certificado SSL..."
    cd /root || exit
    if [ "$installoption" = "2" ]; then
	certbot --apache --redirect --no-eff-email --email "$email" --agree-tos -d "$FQDN"
    fi
    instalar_painel
}

instalar_painel() {
    output "Gerando databases e refazendo root password..."
    password=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    adminpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    rootpassword=`cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1`
    Q0="CREATE DATABASE multicraft_panel CHARACTER SET utf8 COLLATE utf8_general_ci;"
    Q1="CREATE USER 'multicraftpaneldbuser'@'localhost' IDENTIFIED BY '${senhanv3}';"
    Q2="GRANT ALL ON multicraft_panel.* TO 'multicraftpaneldbuser'@'localhost';"
    Q3="CREATE DATABASE multicraft_daemon CHARACTER SET utf8 COLLATE utf8_general_ci;"
    Q4="CREATE USER 'multicraftdaemondbuser'@'localhost' IDENTIFIED BY '${senhanv3}';"
    Q5="SET PASSWORD FOR 'root'@'localhost' = PASSWORD('$rootpassword');"
    Q6="GRANT ALL ON multicraft_daemon.* TO 'multicraftdaemondbuser'@'localhost';"
    Q7="FLUSH PRIVILEGES;"
    SQL="${Q0}${Q1}${Q2}${Q3}${Q4}${Q5}${Q6}${Q7}"
    mysql -u root -e "$SQL"

    output "Baixando Multicraft..."

    wget http://www.multicraft.org/download/linux64 -O multicraft.tar.gz
    tar xvzf multicraft.tar.gz
    cd multicraft

    output "Instalando Multicraft..."
 
    ./setup.sh

}

harden_linux(){
    curl https://raw.githubusercontent.com/Whonix/security-misc/master/etc/modprobe.d/30_security-misc.conf >> /etc/modprobe.d/30_security-misc.conf
    curl https://raw.githubusercontent.com/Whonix/security-misc/master/etc/sysctl.d/30_security-misc.conf >> /etc/sysctl.d/30_security-misc.conf
    sed -i 's/kernel.yama.ptrace_scope=2/kernel.yama.ptrace_scope=3/g' /etc/sysctl.d/30_security-misc.conf
    curl https://raw.githubusercontent.com/Whonix/security-misc/master/etc/sysctl.d/30_silent-kernel-printk.conf >> /etc/sysctl.d/30_silent-kernel-printk.conf
}

#Execution
preflight
install_options
case $installoption in 
    1)  senha_ft
	    harden_linux
        instalar_pacote1
        ;;
esac

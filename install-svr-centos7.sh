#!/bin/sh
# 
# Install script for game servers of The-games.be pour CentOS 7
# Script d'installation des serveurs jeux du Games
# 
# version 1.1 
# 20/02/2015 
# 
# Auteur : Touffu - zero.sur.zero@gmail.com
# 
# USERS
# 
# Créer ici les utilisateurs à créer pour chaque serveurs
# srvUsers = (user1 user2 user3 ...)
# srvProgs = (prog1 prog2 ...)
# Pour les programmes uniquement (en mm nombre que les srvProgs !)
# srvPassword = (pass1 pass2 ...)
# 
adminsUsers=(admin admin)

# Minecraft
mcUsers=(user user) 
mcProgs=(prog) 
mcPassword=(password)

# Counter Strike GO
csUsers=(user user)
csProgs=(prog)
csPassword=(password)

# Trackmania Stadium
tmUsers=(user user)
tmProgs=(prog)
tmPassword=(password)

# Team Fortress
tfUsers=(user user)
tfProgs=(prog)
tfPassword=(password)

# 
utUsers=(user user)
utProgs=(prog)
utPassword=(password)

url="http://..."

# ################################
# NE PAS MODIFIER A PARTIR D'ICI !
# ################################


# FUNCTIONS
function repos() # étape 1
{
	echo -en "NETWORKING=yes" > /etc/sysconfig/network
	echo -en "\n"
	yum -y update
	echo -en "\n####################"
	echo -en "\n#                  #"
	echo -en "\n#       Repos      #"
	echo -en "\n#                  #"
	echo -en "\n####################" 
	echo -en "\n"
	echo -en "\n### Remi ###\n"
	yum -y install epel-release
	rpm --import http://rpms.famillecollet.com/RPM-GPG-KEY-remi
	rpm -ivh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
	echo -en ""
	echo -en "\n### Fish ###\n"
	yum -y install wget
	wget -O /etc/yum.repos.d/shells:fish:release:2.repo http://download.opensuse.org/repositories/shells:fish:release:2/CentOS_7/shells:fish:release:2.repo
	yum -y update
}

function install() #étape 2
{
	echo -en "\n####################"
	echo -en "\n#                  #"
	echo -en "\n#      Install     #"
	echo -en "\n#                  #"
	echo -en "\n####################" 
	echo -en "\n"
	echo -en "\n### AUTRES ###\n"
	yum -y install less man vim-enhanced screen  unzip htop fish bzip2 #bind-utils rsync
	yum -y install expect #pour les mots de passe
	wget -O /etc/issue.net  $url/issue.net #--no-check-certificate

	echo -en "\n### NTP ###\n"

	yum -y install ntp ntpdate 

	
	echo -en "\n### SSH ###\n"
	yum -y install openssh-clients 
	wget -O /etc/ssh/sshd_config  $url/sshd_config
	chmod 600 /etc/ssh/sshd_config
	chkconfig sshd on
	service sshd restart
	
	echo -en "\n### MYSQL ###\n"
	yum -y install mysql
	
	echo -en "\n### NRPE ###\n"
	yum -y install nrpe nagios-plugins nagios-plugins-check-updates nagios-plugins-disk nagios-plugins-load nagios-plugins-users nagios-plugins-procs nagios-plugins-swap
	ARCH=$(uname -m)
	if [ ${ARCH} == 'x86_64' ]; then
  		wget -O /etc/nagios/nrpe.cfg  $url/nrpe64.cfg
	else
  		wget -O /etc/nagios/nrpe.cfg  $url/nrpe32.cfg
	fi
	firewall-cmd --zone=public --add-port=5666/tcp --permanent
	firewall-cmd --reload
	chkconfig nrpe on
	service nrpe restart
	
	echo -en "\n### SNMP ###\n"
	yum -y install net-snmp
	wget -O /etc/snmp/snmpd.conf  $url/snmpd.conf
	firewall-cmd --zone=public --add-port=161/udp --permanent
 	firewall-cmd --reload
	chkconfig snmpd on
	service snmpd start

	echo -en "\n### IPS FAIL2BAN ###\n"
	yum -y install fail2ban
	chkconfig fail2ban on
	service fail2ban start
	
	echo -en "\n### NTP ###\n"	
	yum -y install ntp
	wget -O /etc/ntp.conf url/ntp.conf
	chkconfig ntpd on
	service ntpd start
}
function config()
{
	echo -en "\n####################"
	echo -en "\n#                  #"
	echo -en "\n#   Configuration  #"
	echo -en "\n#                  #"
	echo -en "\n####################" 
	echo -en "\n"
	echo -en "\n### SELINUX ###\n"
	sed -i 's/enforcing/disabled/g' /etc/selinux/config /etc/selinux/config
}
function createRealUser()
{
	echo -en "\n####################"
	echo -en "\n#                  #"
	echo -en "\n#      USERS       #"
	echo -en "\n#                  #"
	echo -en "\n####################" 
	echo -en "\n"
	for name in $users
	do
		echo -en "\n### $name ###\n"
		groupadd -g $id $name 
		useradd -g $id -u $id -s /usr/bin/fish $name 
		chage -d 0 $name
		passwd -fu $name
		usermod -G wheel $name
		mkdir /home/$name/.ssh/
		wget -O /home/$name/.ssh/authorized_keys  $url/users/$name
		chown -R $name:$name /home/$name/.ssh/
		chmod 700 /home/$name/.ssh/
		chmod 600 /home/$name/.ssh/authorized_keys
		let id++
	done
}
function createProgUser()
{
	for prog in $progs
	do
		echo -en "\n### $prog ###\n"
		password=${passwords[$i]}
		groupadd -g $id $prog
		useradd -g $id -u $id $prog
		echo -en $password | passwd --stdin $prog
		let id++
	done
}


# TEST USER = ROOT
if [ "$USER" != "root" ]; then
	echo -en "Script à lancer avec l'utilisateur root"
	exit 0
fi

# INIT
cd /root
id=1000



# MENU
echo -en "\n###############################################"
echo -en "\n#                                             #"
echo -en "\n#   Script d'installation des serveurs jeux   #"
echo -en "\n#                 by Touffu                   #"
echo -en "\n#                                             #"
echo -en "\n#                Version 1.1                  #"
echo -en "\n#                                             #"
echo -en "\n#                the-games.be                 #"
echo -en "\n#                                             #"
echo -en "\n###############################################"
echo -en "\n"
echo -en "\n--- Nouvelle machine ---"
echo -en "\n"
echo -en "\nVeuillez choisir le serveur qui sera installer sur cette machine : "
echo -en "\n1. Counter Strike GO"
echo -en "\n2. Track Mania Stadium"
echo -en "\n3. Unreal Tournament 2004"
echo -en "\n4. Team Fortress"
echo -en "\n5. Minecraft"
echo -en "\n6. Faire une machine générique"
echo -en "\n"
echo -en "\n--- Machine existante ---"
echo -en "\n"
echo -en "\n7. Faire un utilisateur\n"
read -p ">" choix

case $choix in
	# Counter Strike GO
	1)
		repos
		install
		# Crée les Admins 
		users=("${adminsUsers[*]}")
		createRealUser
		# Crée les responsables Tournois
		users=("${csUsers[*]}")
		createRealUser
		# Crée les utilisateurs serveur
		progs=("${csProgs[*]}")
		passwords=("${csPassword[*]}")
		createProgUser
		;;
	# Track Mania Stadium
	2)
		repos
		install
		# Crée les Admins 
		users=("${adminsUsers[*]}")
		createRealUser
		# Crée les responsables Tournois
		users=("${tmUsers[*]}")
		createRealUser
		# Crée les utilisateurs serveur
		progs=("${tmProgs[*]}")
		passwords=("${tmPassword[*]}")
		createProgUser
		;;
	# Unreal Tournament 2004
	3)
		repos
		install
		# Crée les Admins 
		users=("${adminsUsers[*]}")
		createRealUser
		# Crée les responsables Tournois
		users=("${utUsers[*]}")
		createRealUser
		# Crée les utilisateurs serveur
		progs=("${utProgs[*]}")
		passwords=("${utPassword[*]}")
		createProgUser
		;;
	# Team Fortress
	4)
		repos
		install
		# Crée les Admins 
		users=("${adminsUsers[*]}")
		createRealUser
		# Crée les responsables Tournois
		users=("${tfUsers[*]}")
		createRealUser
		# Crée les utilisateurs serveur
		progs=("${tfProgs[*]}")
		passwords=("${tfPassword[*]}")
		createProgUser
		;;
	# Minecraft
	5)
		repos
		install
		# Crée les Admins 
		users=("${adminsUsers[*]}")
		createRealUser
		# Crée les responsables Tournois
		users=("${mcUsers[*]}")
		createRealUser		
		# Crée les utilisateurs serveur
		progs=("${mcProgs[*]}")
		passwords=("${mcPassword[*]}")
		createProgUser
		;;
	# Machine Générique
	6)
		repos
		insta
ll		users=("${adminsUsers[*]}")
		createRealUser
		;;
	# Créer un user
	7)
		echo -en ""
		read -p "Entrer le pseudo de l'utilisateur : " theUser
		wget --no-check-certificate $url/users/$theUser
		if [ $? != 0 ]; then 
			echo "Pas de clé SSH sur hosting trouvée ... (/.../users)"
			exit 0
		fi
		useradd -s /usr/bin/fish $theUser
		chage -d 0 $theUser
		passwd -fu $theUser
		usermod -G wheel $theUser
		mkdir /home/$theUser/.ssh/
		mv $theUser /home/$theUser/.ssh/authorized_keys
		chown -R $theUser:$theUser /home/$theUser/.ssh/
		chmod 700 /home/$theUser/.ssh/
		chmod 600 /home/$theUser/.ssh/authorized_keys
		;;
	*)
		echo -en "\nMerci de repéciser votre choix\n"
		menu
		;;
esac

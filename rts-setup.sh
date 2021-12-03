#!/bin/bash

echo "#### NIWC Pacific Adversarial Cyber Team - Red Team Server Setup Script ####"
echo
echo "[*]   = Status"
echo "[**]  = Completed"
echo "[***] = Warning"
echo "[!!!] = Error"
echo

nextcloud_db_user=nextcloud
nextcloud_db_host=nextcloud-db
nextcloud_d_pass=rts_passw0rd
gitea_db_host=gitea-db
gitea_db_type=postgres
gitea_db_user=gitea
gitea_db_pass=gitea



echo "Starting sanity checks and initial setup"

echo "[*] Checking root status..."
# check to see if I am root
if [ "$EUID" -ne 0 ]; then
  echo "[!!!] Effective UID is $EUID"
  echo "[!!!] Please run as root"
  exit
else
  echo "[*] Effective UID is $EUID"
  echo "[**] Running as root"
fi
echo
sleep 3

echo "[*] Checking hostname status..."
# check to see if hostname is set correctly
check_hostname="$(hostname -f)"
if [ "${check_hostname}" != "rts.lan" ]; then
    echo "[!!!] Hostname is not set correctly (currently set to $check_hostname), setting to rts.lan"
    hostnamectl set-hostname rts.lan
    # verify hostname changed
    if [ "$HOSTNAME" -ne "rts.lan"]; then
        echo "[!!!] Hostname change did not work, you need to do it manually. Exiting."
        exit
    fi
    else echo "[**] Hostname ($check_hostname) is correct."
fi
# ensure ssh is enabled
echo
sleep 3

echo "[*] Checking SSHd status..."
check_sshd="$(systemctl is-active ssh)"
if [ "${check_sshd}" = "inactive" ]; then
  echo "[***] SSHd is not running, starting."
  systemctl start ssh
  sleep 3
  check_new_sshd="$(systemctl is-active ssh)"
  if [ "${check_new_sshd}" = "inactive" ]; then
      echo "[!!!] SSHD is not starting, check your configuration. Exiting."
  else echo "[*] SSHd successfully started."
  fi
else echo "[**] SSH is running."
fi
echo
# check to see if docker.io is installed
echo "[*] Checking if 'docker' is installed..."
dpkg -s docker.io &> /dev/null
if [ $? -eq 0 ]; then
    echo "[**] docker is installed, moving on."
else
    echo "[***] docker is not installed, installing from repo."
    apt install docker.io -y &> /dev/null
    # Verify docker is now installe
    dpkg -s docker.io &> /dev/null
    if [ $? -eq 0 ]; then
       echo "[*] docker is now installed."
    else
       echo "[!!!] docker installation failed, check logs. Exiting."
        exit
    fi
fi


# check to see if docker-compose is  installed
echo "[*] Checking if 'docker-compose' is installed..."
dpkg -s docker-compose &> /dev/null
if [ $? -eq 0 ]; then
    echo "[**] docker-compose is installed, moving on."
else
    echo "[***] docker-compose is not installed, installing from repo."
    apt install docker-compose -y &> /dev/null
    # Verify docker-compose is now installe
    dpkg -s docker-compose &> /dev/null
    if [ $? -eq 0 ]; then
       echo "[*] docker-compose is now installed."
    else
       echo "[!!!] docker-compose installation failed, check logs. Exiting."
        exit
    fi
fi
echo
#ensure rts user exists on the system, and if not create it. 
echo "[*] Checking to see if rts user exists..."
getent passwd rts > /dev/null
if [ $? -eq 0 ]; then
    echo "[*] 'rts' user  exists"
else
    echo "[***] 'rts' user does not exist, creating.."
fi


echo
# check to make sure root belongs to docker group
echo "[*] Checking root and rts user permissions for docker..."
check_USER="root"
check_GROUP="docker"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    echo "[*] $check_USER belongs to $check_GROUP"
else
    echo "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod –aG $check_GROUP $check_USER
    echo "[*] $check_USER added to $check_GROUP group"
fi

check_USER="rts"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    echo "[*] $check_USER belongs to $check_GROUP"
else
    echo "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod -aG $check_GROUP $check_USER
    echo "[*] $check_USER added to $check_GROUP group."
fi


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
initial_working_dir=$(pwd)
initial_user=$(whoami)
install_path="/opt/rts"
ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')

function rawurlencode() {
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p

}

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

echo "rts_ip_address=${ip_address}" > ./.env

echo
sleep 3
read -p "[*] Enter the password you want to use for Gitea and Nextcloud (default is rtsPassw0rd! )-> " web_password
if [ -z "${web_password}" ]
then
   web_password="rtsPassw0rd!"
fi
url_encoded_pass=$( rawurlencode "$web_password" )

echo
read -p "[*] Enter the path to install the redteamserver (default /home/rts/redteamserver) -> " install_path
if [ -z "${install_path}" ]
then
  install_path="/opt/rts"
fi

echo
echo "[*] Checking hostname status..."
# check to see if hostname is set correctly
check_hostname="$(hostname)"
hosts_line="127.0.1.1	rts.lan	  rts"
if [ "${check_hostname}" != "rts" ]; then
    echo "[!!!] Hostname is not set correctly (currently set to $check_hostname), setting to rts.lan"
    hostnamectl set-hostname rts
    sed -i".bak" "/$check_hostname/d" /etc/hosts
    echo ${hosts_line} >> /etc/hosts
    # verify hostname changed
    if [ "`(hostname -f)`" != "rts.lan" ]; then
        echo "[!!!] Hostname change did not work, you need to do it manually. Exiting."
        exit
    fi
    else echo "[**] Hostname (${check_hostname}) is correct."
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
# check to see if golang-go is installed
echo "[*] Checking if 'golang' is installed..."
dpkg -s golang &> /dev/null
if [ $? -eq 0 ]; then
    echo "[**] golang is installed, moving on."
else
    echo "[***] golang is not installed, installing from repo."
    apt install golang-go -y &> /dev/null
    # Verify golang is now installed
    dpkg -s golang &> /dev/null
    if [ $? -eq 0 ]; then
       echo "[*] golang is now installed."
    else
       echo "[!!!] golang installation failed, check logs. Exiting."
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
    echo "[**] 'rts' user  exists"
else
    echo "[***] 'rts' user does not exist, creating.."
    echo "[*] The 'rts' user will be the primary *SHARED* account that your team uses to access this instance of kali. Make sure you use a generic team password."
    read -r -s -p "[*] What password would you like for the 'rts' account? -> " rtspassword
    useradd rts -s /bin/bash -m -g adm -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,wireshark,scanner,kaboxer,docker
    echo "rts:$rtspassword" | chpasswd
    echo "[**] User created."
fi


echo
# check to make sure root belongs to docker group
echo "[*] Checking root and rts user permissions for docker..."
check_USER="root"
check_GROUP="docker"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    echo "[**] $check_USER belongs to $check_GROUP"
else
    echo "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod –aG $check_GROUP $check_USER
    echo "[*] $check_USER added to $check_GROUP group"
fi

check_USER="rts"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    echo "[**] $check_USER belongs to $check_GROUP"
else
    echo "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod -aG $check_GROUP $check_USER
    echo "[*] $check_USER added to $check_GROUP group."
fi
echo
sleep 2
# If script was run by non-rts user in non /home/rts/rts/ directory this is a problem that we will now fix"
if [ "${initial_user}" != "rts" ] || [ "${initial_working_dir}" != "${install_path}" ]; then
	echo "[*] Copying files from current location to ${install_path}"
        if [ ! -d "${install_path}" ]
           then
               mkdir ${install_path}
               chown ${install_path} rts:rts
        fi
#        sudo -u rts cp -R ${initial_working_dir}/. ${install_path}
	sudo -u rts cp -R ${initial_working_dir}/covenant ${install_path}
	sudo -u rts cp -R ${initial_working_dir}/hastebin ${install_path}
	sudo -u rts cp ${initial_working_dir}/{agent-dockerfile,config.json,docker-compose.yml,environment.js,homeserver.yml,nuke-docker.sh} ${install_path}
        echo "[*] Changing working directory to ${install_path}"
        cd ${install_path}
        pwd
        echo "[**] Assuming rts user level."
else echo "[**] User and path look good to go."
fi
echo

#lets start crack-a-lackin

#check for internet access
echo "[*] Checking for Internet access"
if nc -zw1 google.com 443; then
  echo "[**] Internet Connectivity checks successful."
else echo "[!!!] Internet connectivity is *REQUIRED* to build RTS. Fix, and restart script."
fi
echo
sleep 2
sudo_1=$(sudo -u rts whoami)
sudo_2=$(sudo -u rts pwd)
#echo "sudo_1 test = $sudo_1"
#echo "sudo_2 test = $sudo_2"
echo "[*] Dropping priveleges down to rts user account."
if [ "${sudo_1}" = "rts" ]; then
   echo "[*] User Privs look good, continuing."
   if [ "${sudo_2}" = "${install_path}" ]; then
      echo "[*] Build path looks good, continuing with the build."
   else
        echo "[!!!] Something is wrong and we are not in the right path. Exiting."
        exit
   fi
else
   echo "[!!!] Something is wrong and we are not the right user. Exiting."
   exit
fi
echo
echo "[*] Cloning Reconmap..."
sudo -u rts git clone https://github.com/reconmap/reconmap.git ${install_path}/reconmap >/dev/null
sudo -u rts git clone https://github.com/reconmap/agent.git ${install_path}/reconmap-agent >/dev/null
sudo -u rts git clone https://github.com/reconmap/cli.git ${install_path}/reconmap-cli >/dev/null
#sudo -u rts cp ./agent-dockerfile ${install_path}/reconmap-agent/Dockerfile >/dev/null
sudo -u rts cp ./config.json ${install_path}/reconmap/ >/dev/null
sudo -u rts cp ./environment.js ${install_path}/reconmap/ >/dev/null
if [ $? -eq 0 ]; then
   echo "[**] Clone successful, movin' on."
else
   echo "[!!!] Clone failed, exiting. Check your internet connectivity or github access."
   exit
fi
echo
echo "[*] Starting reconmap-agent build"
sudo -u rts make -C ${install_path}/reconmap-agent/
if [ $? -eq 0 ]; then
   echo "[**] Reconmap-agent build successful, movin' on."
else
   echo "[!!!] Reconmap-agent build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
echo "[*] Starting reconmap-cli build"
sudo -u rts make -C ${install_path}/reconmap-cli/
if [ $? -eq 0 ]; then
   echo "[**] Reconmap-cli build successful, movin' on."
else
   echo "[!!!] Reconmap-cli build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
echo "[*] Copying reconmapd & rmap to install path."
sudo -u rts cp ${install_path}/reconmap-agent/reconmapd ${install_path}/
sudo -u rts cp ${install_path/reconmap-cli/rmap ${install_path}/
echo

echo "[*] Starting Docker Compose Build"
read -p "[**] Everything seems good to go to continue the docker-compose build. Continue? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
   echo "[*] DO EET DO EET"
   sleep 3
else
   echo "[*] Not Cool!"
   exit
fi

echo
echo "[*] Starting stage 1 of build"
sleep 5
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build
if [ $? -eq 0 ]; then
   echo "[**] Stage 1 complete, moving to stage 2."
else
   echo "[!!!] Stage 1 failure, please post an issue on the RTS github. Exiting."
   exit
fi
sleep 5
echo "[*] Starting stage 2 of build"
sleep 5
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d
if [ $? -eq 0 ]; then
   echo "[**] Stage 2 complete, finalizing."
else
   echo "[!!!] Stage 2 failure, please post an issue on the RTS github. Exiting."
   exit
fi
echo
sleep 5
echo "[*] Generating Matrix/Synapse configuration and restarting."
sudo -u rts docker-compose run --rm -e SYNAPSE_SERVER_NAME=matrix.rts.lan synapse generate >/dev/null
if [ $? -eq 0 ]; then
    echo "[**] Matrix/Synapse configuration generated."
else
   echo "[!!!] Matrix/Synapse configuration failed. Please post an issue on the RTS github. Exiting."
   exit
fi
echo
sleep 5
sudo -u rts docker-compose restart
if [ $? -eq 0 ]; then
   echo "[**] Docker Compose restart complete, finalizing."
else
   echo "[!!!] Docker Compose restart failed, please post an issue on the RTS github. Exiting."
   exit
fi
echo
echo "[*] Adding in services to /etc/hosts"
if grep -qF "${ip_address} www.rts.lan" /etc/hosts; then
  echo "[**] www.rts.lan found."
else
  echo "[***] adding in www.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} www.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} gitea.rts.lan" /etc/hosts; then
  echo "[**] gitea.rts.lan found."
else
  echo "[***] adding in gitea.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} gitea.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} nextcloud.rts.lan" /etc/hosts; then
  echo "[**] nextcloud.rts.lan found."
else
  echo "[***] adding in nextcloud.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} nextcloud.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} ivre.rts.lan" /etc/hosts; then
  echo "[**] ivre.rts.lan found."
else
  echo "[***] adding in ivre.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} ivre.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} hastebin.rts.lan" /etc/hosts; then
  echo "[**] hastebin.rts.lan found."
else
  echo "[***] adding in hastebin.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} hastebin.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} matrix.rts.lan" /etc/hosts; then
  echo "[**] matrix.rts.lan found."
else
  echo "[***] adding in matrix.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} matrix.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} element.rts.lan" /etc/hosts; then
  echo "[**] element.rts.lan found."
else
  echo "[***] adding in element.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} element.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} reconmap.rts.lan" /etc/hosts; then
  echo "[**] reconmap.rts.lan found."
else
  echo "[***] adding in reconmap.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} reconmap.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} ssh.rts.lan" /etc/hosts; then
  echo "[**] ssh.rts.lan found."
else
  echo "[***] adding in ssh.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} ssh.rts.lan" >> /etc/hosts
fi
echo "[**] Finished updating /etc/hosts."
echo
echo "[*] Sleeping 30 seconds to allow services to initialize."
sleep 30
echo "[*] Starting Configuration of webservices..."
### GITEA config CURL ####
echo "[*] Congifuring Gitea"
curl -s 'http://gitea.rts.lan/' \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'Origin: null' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'DNT: 1' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36 Edg/96.0.1054.41' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: i_like_gitea=c213e135068e43fa' \
  --data-raw "db_type=PostgreSQL&db_host=gitea-db%3A5432&db_user=gitea&db_passwd=gitea&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=RTS+The+Red+Team+Server&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=localhost&ssh_port=22&http_port=3000&app_url=http%3A%2F%2Fgitea.rts.lan&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&enable_open_id_sign_in=on&enable_open_id_sign_up=on&default_allow_create_organization=on&default_enable_timetracking=on&no_reply_address=noreply.localhost&password_algorithm=pbkdf2&admin_name=rts&admin_passwd=$url_encoded_pass&admin_confirm_passwd=$url_encoded_pass&admin_email=root%40localhost" \
  --compressed \
  --insecure > /dev/null
if [ $? -eq 0 ]; then
   echo "[**] Gitea Configured."
else
  echo "[!!!] Gitea configuration failed, please post an issue on the RTS github. Exiting."
  exit
fi
echo
echo "[*] Configuring Nextcloud"
curl -s 'http://nextcloud.rts.lan/index.php' \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'Origin: null' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'DNT: 1' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36 Edg/96.0.1054.41' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: oc_sessionPassphrase=TW1ohzxK%2F%2BlaWyuMxN10G30%2BKZSH9YcDelpA%2FO7ncW7i2cGitpSwsqc5d5yNUnvcqj2xHo7bx%2FqLQQX2yDggDJZYBrZ6TUmfwe582pJ7m1fyFvAH9Jfw%2FUAbjsjPHVDz; nc_sameSiteCookielax=true; nc_sameSiteCookiestrict=true; ocuu9t7omn5d=38cf0357ac05e30828f9d6dcb39e1d82; ocrd4rn7yqen=7ce9f122acf91070eb391860acac1b11; ocgourudt1gn=6acb12044fd9615cc3d83cf3742559c8; octp6wai7af2=ddac7c044bc04517cacf9a2fcf6644fd' \
  --data-raw "install=true&adminlogin=rts&adminpass=$url_encoded_pass&adminpass-clone=$url_encoded_pass&directory=%2Fvar%2Fwww%2Fhtml%2Fdata&dbtype=mysql&dbuser=nextcloud&dbpass=rts_passw0rd&dbpass-clone=rts_passw0rd&dbname=nextcloud&dbhost=nextcloud_db&install-recommended-apps=on" \
  --compressed \
  --insecure \
  --keepalive-time 300 > /dev/null
if [ $? -eq 0 ]; then
   echo "[**] NextCloud Configured."
else
   echo "[!!!] NextCloud configuration failed, please post an issue on the RTS github. Exiting."
   exit
fi
echo
echo "[*] Configuring and starting reconmapd agent service in the background."
REDIS_HOST=localhost REDIS_PORT=6397 REDIS_PASSWORD=REconDIS ${install_path}/reconmapd &>/dev/null
echo
echo "[*] Configuring rmap."
${install_path}/rmap config --api-url http://rts.lan:5510
${install_path}/rmap login -u admin -p admin123
echo
echo "[****************************************************]"
echo "[****************Service Information ****************]"
echo "[****************************************************]"
echo
echo "Linux hosts file:"
echo "/etc/hosts"
echo "Windows hosts file:"
echo "c:\windows\system32\drivers\etc\hosts"
echo
echo "Copy and Paste the following into your respective systems hosts file:"
echo
ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')
for whatever in ip_address
do
  echo $ip_address rts.lan
  echo $ip_address www.rts.lan
  echo $ip_address gitea.rts.lan
  echo $ip_address nextcloud.rts.lan
  echo $ip_address ivre.rts.lan
  echo $ip_address hastebin.rts.lan
  echo $ip_address matrix.rts.lan
  echo $ip_address element.rts.lan
  echo $ip_address reconmap.rts.lan
  echo $ip_address ssh.rts.lan
done
echo
echo "[***] Convenant is accessible at http://rts.lan:7443"

# Some quick configuration for reconmap
chmod -R 777 ${install_path}/reconmap/logs
chmod -R 777 ${install_path}/reconmap/data/attachments
echo "[*] The username and password for Gitea and Nextcloud are:"
echo "rts/$web_password"
echo "[*] The username and password for Reconmap is:"
echo "admin/admin123"
echo "[*] Be sure to visit http://nextcloud.rts.lan/index.php/core/apps/recommended in your browser to install recommended applications."
echo "[***] This concludes RTS installation."
echo "Hack the Planet!"

# Also need to get nginx server up and operational for the rest of the website. Then we're done.

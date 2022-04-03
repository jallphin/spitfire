#!/bin/bash
echo
echo
cat << EOF
    '########::'########::'######::
    ##.... ##:... ##..::'##... ##:
    ##:::: ##:::: ##:::: ##:::..::
    ########::::: ##::::. ######::
    ##.. ##:::::: ##:::::..... ##:
    ##::. ##::::: ##::::'##::: ##:
    ##:::. ##:::: ##::::. ######::
    ..:::::..:::::..::::::......:::
EOF
echo      "#### Red Team Server Setup Script ####"
echo
echo "[*]   = Status"
echo "[**]  = Completed"
echo "[***] = Warning"
echo "[!!!] = Error"
echo "Log file is at /tmp/rts.log for any issues."
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
log="/tmp/rts.log"
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

function ee() {
echo "$1" | tee -a $log
}

ee "Starting sanity checks and initial setup"

ee "[*] Checking root status..."
# check to see if I am root
if [ "$EUID" -ne 0 ]; then
  ee "[!!!] Effective UID is $EUID"
  ee "[!!!] Please run as root"
  exit
else
  ee "[*] Effective UID is $EUID"
  ee "[**] Running as root"
fi

echo "rts_ip_address=${ip_address}" > ./.env
echo "[*] added rts_ip_address=${ip_address} to ./env" | tee -a $log > /dev/null

echo
sleep 3
read -p "[*] Enter the password you want to use for Gitea and Nextcloud (default is rtsPassw0rd!) -> " web_password
if [ -z "${web_password}" ]
then
   web_password="rtsPassw0rd!"
fi
url_encoded_pass=$( rawurlencode "$web_password" )

echo
read -p "[*] Enter the path to install the redteamserver (default /opt/rts) -> " install_path
if [ -z "${install_path}" ]
then
  install_path="/opt/rts"
fi

echo
ee "[*] Checking hostname status..."
# check to see if hostname is set correctly
check_hostname="$(hostname)"
hosts_line="127.0.1.1	rts.lan	  rts"
if [ "${check_hostname}" != "rts" ]; then
    ee "[!!!] Hostname is not set correctly (currently set to $check_hostname), setting to rts.lan"
    hostnamectl set-hostname rts | tee -a $log
    sed -i".bak" "/$check_hostname/d" /etc/hosts | tee -a $log
    echo ${hosts_line} >> /etc/hosts
    # verify hostname changed
    if [ "`(hostname -f)`" != "rts.lan" ]; then
        ee "[!!!] Hostname change did not work, you need to do it manually. Exiting."
        exit
    fi
    else ee "[**] Hostname (${check_hostname}) is correct."
fi

# ensure ssh is enabled
echo
sleep 3

ee "[*] Checking SSHd status..."
check_sshd="$(systemctl is-active ssh)"
if [ "${check_sshd}" = "inactive" ]; then
  ee "[***] SSHd is not running, starting."
  systemctl start ssh | tee -a $log
  sleep 3
  check_new_sshd="$(systemctl is-active ssh)"
  if [ "${check_new_sshd}" = "inactive" ]; then
      ee "[!!!] SSHD is not starting, check your configuration. Exiting."
  else ee "[*] SSHd successfully started."
  fi
else ee "[**] SSH is running."
fi
echo
sleep 3

# check to see if docker.io is installed
ee "[*] Checking if 'docker' is installed..."
dpkg -s docker.io | tee -a $log > /dev/null
if [ $? -eq 0 ]; then
    ee "[**] docker is installed, moving on."
else
    ee "[***] docker is not installed, installing from repo."
    apt install docker.io -y | tee -a $log > /dev/null
    # Verify docker is now installe
    dpkg -s docker.io | tee -a $log > /dev/null
    if [ $? -eq 0 ]; then
       ee "[*] docker is now installed."
    else
       ee "[!!!] docker installation failed, check logs. Exiting."
        exit
    fi
fi
echo
sleep 3
# check to see if golang-go is installed
ee "[*] Checking if 'golang' is installed..."
for go_pkgs in golang golang-go
do
   dpkg -s $go_pkgs | tee -a $log &> /dev/null
if [ $? -eq 0 ]; then
    ee "[**] golang packge $go_pkgs is installed, moving on."
else
    ee "[***] golang package $go_pkgs is not installed, installing from repo."
    apt install $go_pkgs -y | tee -a $log &> /dev/null
    # Verify golang is now installed
    dpkg -s $go_pkgs | tee -a $log &> /dev/null
    if [ $? -eq 0 ]; then
       ee "[*] golang package $go_pkgs is now installed."
    else
       ee "[!!!] golang package $go_pkgs installation failed, check logs. Exiting."
        exit
    fi
fi
done

echo
sleep 3
# check to see if docker-compose is  installed
ee "[*] Checking if 'docker-compose' is installed..."
dpkg -s docker-compose | tee -a $log &> /dev/null
if [ $? -eq 0 ]; then
    ee "[**] docker-compose is installed, moving on."
else
    ee "[***] docker-compose is not installed, installing from repo."
    apt install docker-compose -y | tee -a $log &> /dev/null
    # Verify docker-compose is now installe
    dpkg -s docker-compose | tee -a $log &> /dev/null
    if [ $? -eq 0 ]; then
       ee "[*] docker-compose is now installed."
    else
       ee "[!!!] docker-compose installation failed, check logs. Exiting."
        exit
    fi
fi
echo
sleep 3
# check to see if jq is  installed # needed for API processing
ee "[*] Checking if 'jq' is installed..."
dpkg -s jq | tee -a $log &> /dev/null
if [ $? -eq 0 ]; then
    ee "[**] jq is installed, moving on."
else
    ee "[***] jq is not installed, installing from repo."
    apt install jq -y | tee -a $log &> /dev/null
    # Verify docker-compose is now installe
    dpkg -s jq | tee -a $log &> /dev/null
    if [ $? -eq 0 ]; then
       ee "[*] jq is now installed."
    else
       ee "[!!!] jq installation failed, check logs. Exiting."
        exit
    fi
fi

echo
sleep 3
#ensure rts user exists on the system, and if not create it.
ee "[*] Checking to see if rts user exists..."
getent passwd rts | tee -a $log > /dev/null
if [ $? -eq 0 ]; then
    ee "[**] 'rts' user  exists"
else
    ee "[***] 'rts' user does not exist, creating.."
    ee "[*] The 'rts' user will be the primary *SHARED* account that your team uses to access this instance of kali. Make sure you use a generic team password."
    read -r -s -p "[*] What password would you like for the 'rts' account? -> " rtspassword
    useradd rts -s /bin/bash -m -g adm -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,wireshark,scanner,kaboxer,docker | tee -a $log
    echo "rts:$rtspassword" | chpasswd | tee -a $log
    ee "[**] User created."
fi
echo
sleep 3
# check to make sure root belongs to docker group
ee "[*] Checking root and rts user permissions for docker..."
check_USER="root"
check_GROUP="docker"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    ee "[**] $check_USER belongs to $check_GROUP"
else
    ee "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod –aG $check_GROUP $check_USER | tee -a $log
    ee "[*] $check_USER added to $check_GROUP group"
fi

check_USER="rts"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    ee "[**] $check_USER belongs to $check_GROUP"
else
    ee "[***] $check_USER does not belong to $check_GROUP, adding."
    usermod -aG $check_GROUP $check_USER | tee -a $log
    ee "[*] $check_USER added to $check_GROUP group."
fi
echo
sleep 2
# If script was run by non-rts user in non /home/rts/rts/ directory this is a problem that we will now fix"
if [ "${initial_user}" != "rts" ] || [ "${initial_working_dir}" != "${install_path}" ]; then
	ee "[*] Copying files from current location to ${install_path}"
        if [ ! -d "${install_path}" ]
           then
               mkdir ${install_path} | tee -a $log
               chown -R rts:adm ${install_path} | tee -a $log
	   else
	       rm -rf ${install_path} | tee -a $log # I understand this clobbers a previous install directory - but if you already have it installed, why are you running this again? Clean install? 
               mkdir ${install_path} | tee -a $log 
               chown -R rts:adm ${install_path} | tee -a $log
        fi
#        sudo -u rts cp -R ${initial_working_dir}/. ${install_path}
	sudo -u rts cp -R ${initial_working_dir}/covenant ${install_path} | tee -a $log
	sudo -u rts cp -R ${initial_working_dir}/hastebin ${install_path} | tee -a $log
	sudo -u rts cp ${initial_working_dir}/{.env,config.json,docker-compose.yml,environment.js,homeserver.yaml,nuke-docker.sh} ${install_path} | tee -a $log
        ee "[*] Changing working directory to ${install_path}"
        cd ${install_path}
        pwd
        ee "[**] Assuming rts user level."
else ee "[**] User and path look good to go."
fi
echo
sleep 3
#lets start crack-a-lackin

#check for internet access
ee "[*] Checking for Internet access"
if nc -zw1 google.com 443; then
  ee "[**] Internet Connectivity checks successful."
else ee "[!!!] Internet connectivity is *REQUIRED* to build RTS. Fix, and restart script."
fi
echo
sleep 2
sudo_1=$(sudo -u rts whoami)
sudo_2=$(sudo -u rts pwd)
#echo "sudo_1 test = $sudo_1"
#echo "sudo_2 test = $sudo_2"
ee "[*] Dropping priveleges down to rts user account."
if [ "${sudo_1}" = "rts" ]; then
   ee "[*] User Privs look good, continuing."
   if [ "${sudo_2}" = "${install_path}" ]; then
      ee "[*] Build path looks good, continuing with the build."
   else
        ee "[!!!] Something is wrong and we are not in the right path. Exiting."
        exit
   fi
else
   ee "[!!!] Something is wrong and we are not the right user. Exiting."
   exit
fi
echo
ee "[*] Cloning Reconmap..."
sudo -u rts git clone https://github.com/reconmap/reconmap.git ${install_path}/reconmap | tee -a $log &>/dev/null
sudo -u rts git clone https://github.com/reconmap/agent.git ${install_path}/reconmap-agent | tee -a $log &>/dev/null
sudo -u rts git clone https://github.com/reconmap/cli.git ${install_path}/reconmap-cli | tee -a $log &>/dev/null
#sudo -u rts cp ./agent-dockerfile ${install_path}/reconmap-agent/Dockerfile >/dev/null
sudo -u rts cp ./config.json ${install_path}/reconmap/ | tee -a $log &>/dev/null
sudo -u rts cp ./environment.js ${install_path}/reconmap/ | tee -a $log &>/dev/null
sudo -u rts rm ${install_path}/config.json | tee -a $log &> /dev/null
sudo -u rts rm ${install_path}/environment.js | tee -a $log &> /dev/null
# copy in patched terminal_handler for kali linux
sudo -u rts cp ${initial_working_dir}/terminal_handler.go ${install_path}/reconmap-agent/internal/ | tee -a $log &>/dev/null

if [ $? -eq 0 ]; then
   ee "[**] Clone successful, movin' on."
else
   ee "[!!!] Clone failed, exiting. Check your internet connectivity or github access."
   exit
fi
echo
ee "[*] Starting reconmap-agent build"
sudo -u rts make -C ${install_path}/reconmap-agent/ | tee -a $log &> /dev/null
if [ $? -eq 0 ]; then
   ee "[**] Reconmap-agent build successful, movin' on."
else
   ee "[!!!] Reconmap-agent build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
ee "[*] Starting reconmap-cli build"
sudo -u rts make -C ${install_path}/reconmap-cli/ | tee -a $log &> /dev/null
if [ $? -eq 0 ]; then
   ee "[**] Reconmap-cli build successful, movin' on."
else
   ee "[!!!] Reconmap-cli build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
ee "[*] Copying reconmapd & rmap to install path."
sudo -u rts cp ${install_path}/reconmap-agent/reconmapd ${install_path}/ | tee -a $log &> /dev/null
sudo -u rts cp ${install_path}/reconmap-cli/rmap ${install_path}/ | tee -a $log &> /dev/null
echo

ee "[*] Copying website data to install path."
sudo -u rts cp -R ${initial_working_dir}/website  ${install_path}/ | tee -a $log &> /dev/null
echo

ee "[*] Starting Docker Compose Build"
read -p "[**] Everything seems good to go to continue the docker-compose build. Continue? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
   ee "[*] DO EET DO EET"
   sleep 3
else
   ee "[*] Not Cool!"
   exit
fi

echo
ee "[*] Starting stage 1 of build"
sleep 5
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build | tee -a $log
if [ $? -eq 0 ]; then
   ee "[**] Stage 1 complete, moving to stage 2."
else
   ee "[!!!] Stage 1 failure, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
sleep 5
ee "[*] Starting stage 2 of build"
sleep 5
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d | tee -a $log
if [ $? -eq 0 ]; then
   ee "[**] Stage 2 complete, finalizing."
else
   ee "[!!!] Stage 2 failure, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
sleep 5
ee "[*] Generating Matrix/Synapse configuration and restarting."
sudo -u rts docker-compose run --rm -e SYNAPSE_SERVER_NAME=matrix.rts.lan synapse generate | tee -a $log >/dev/null
if [ $? -eq 0 ]; then
    ee "[**] Matrix/Synapse configuration generated."
else
   ee "[!!!] Matrix/Synapse configuration failed. Please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
sleep 5
sudo -u rts docker-compose restart | tee -a $log
if [ $? -eq 0 ]; then
   ee "[**] Docker Compose restart complete, finalizing."
else
   ee "[!!!] Docker Compose restart failed, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
ee "[*] Adding in services to /etc/hosts"
if grep -qF "${ip_address} www.rts.lan" /etc/hosts; then
  ee "[**] www.rts.lan found."
else
  ee "[***] adding in www.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} www.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} gitea.rts.lan" /etc/hosts; then
  ee "[**] gitea.rts.lan found."
else
  ee "[***] adding in gitea.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} gitea.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} nextcloud.rts.lan" /etc/hosts; then
  ee "[**] nextcloud.rts.lan found."
else
  ee "[***] adding in nextcloud.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} nextcloud.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} ivre.rts.lan" /etc/hosts; then
  ee "[**] ivre.rts.lan found."
else
  ee "[***] adding in ivre.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} ivre.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} hastebin.rts.lan" /etc/hosts; then
  ee "[**] hastebin.rts.lan found."
else
  ee "[***] adding in hastebin.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} hastebin.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} matrix.rts.lan" /etc/hosts; then
  ee "[**] matrix.rts.lan found."
else
  ee "[***] adding in matrix.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} matrix.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} element.rts.lan" /etc/hosts; then
  ee "[**] element.rts.lan found."
else
  ee "[***] adding in element.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} element.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} reconmap.rts.lan" /etc/hosts; then
  ee "[**] reconmap.rts.lan found."
else
  ee "[***] adding in reconmap.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} reconmap.rts.lan" >> /etc/hosts
fi
if grep -qF "${ip_address} ssh.rts.lan" /etc/hosts; then
  ee "[**] ssh.rts.lan found."
else
  ee "[***] adding in ssh.rts.lan with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} ssh.rts.lan" >> /etc/hosts
fi
ee "[**] Finished updating /etc/hosts."
echo
ee "[*] Sleeping 30 seconds to allow services to initialize."
sleep 30
ee "[*] Starting Configuration of webservices..."
### GITEA config CURL ####
ee "[*] Congifuring Gitea"
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
  --insecure | tee -a $log > /dev/null
if [ $? -eq 0 ]; then
   ee "[**] Gitea Configured."
else
  ee "[!!!] Gitea configuration failed, please post an issue on the RTS github. Exiting."
  exit
fi
echo
ee "[*] Configuring Nextcloud"
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
  --keepalive-time 300 | tee -a $log > /dev/null
if [ $? -eq 0 ]; then
   ee "[**] NextCloud Configured."
else
   ee "[!!!] NextCloud configuration failed, please post an issue on the RTS github. Exiting."
   exit
fi
echo
ee "[*] Configuring and starting reconmapd agent service in the background."
REDIS_HOST=localhost REDIS_PORT=6379 REDIS_PASSWORD=REconDIS ${install_path}/reconmapd | tee -a $log > /dev/null 2>&1 &
echo
ee "[*] Configuring rmap."
sudo -u rts ${install_path}/rmap config --api-url http://rts.lan:5510 | tee -a $log
sudo -u rts ${install_path}/rmap login -u admin -p admin123 | tee -a $log
# add install_path to the base path 
export PATH=$PATH:${install_path}
echo
ee "[****************************************************]"
ee "[****************Service Information ****************]"
ee "[****************************************************]"
ee
ee "Linux hosts file:"
ee "/etc/hosts"
ee "Windows hosts file:"
ee "c:\windows\system32\drivers\etc\hosts"
ee
ee "Copy and Paste the following into your respective systems hosts file:"
echo
ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')
for whatever in ip_address
do
  echo $ip_address rts.lan | tee -a $log
  echo $ip_address www.rts.lan | tee -a $log
  echo $ip_address gitea.rts.lan | tee -a $log
  echo $ip_address nextcloud.rts.lan | tee -a $log
  echo $ip_address ivre.rts.lan | tee -a $log
  echo $ip_address hastebin.rts.lan | tee -a $log
  echo $ip_address matrix.rts.lan | tee -a $log
  echo $ip_address element.rts.lan | tee -a $log
  echo $ip_address reconmap.rts.lan | tee -a $log
  echo $ip_address ssh.rts.lan | tee -a $log
done
echo
ee "[***] Convenant is accessible at http://rts.lan:7443"

# Some quick configuration for reconmap
chmod -R 777 ${install_path}/reconmap/logs | tee -a $log
chmod -R 777 ${install_path}/reconmap/data/attachments | tee -a $log
ee "[*] The username and password for Gitea and Nextcloud are:"
ee "rts/$web_password"
ee "[*] The username and password for Reconmap is:"
ee "admin/admin123"
ee "[*] Be sure to visit http://nextcloud.rts.lan/index.php/core/apps/recommended in your browser to install recommended applications."
ee "[*] Log file moved from /tmp/rts.log to ${install_path}/rts.log"
ee "[***] This concludes RTS installation."
ee "Hack the Planet!"
mv /tmp/rts.log /opt/rts/
chown rts:adm /opt/rts/rts.log

# Also need to get nginx server up and operational for the rest of the website. Then we're done.

# I think it's a good idea to set up a shared local folder for nextcloud. For this you have to
# A.) enable the "external storage" under apps
# B.) use something like "/opt/pentest-storage-data/" and chmod 777 that sucker
# C.) make sure you mount that directory in the docker-compose.yml for nextcloud under volumes, which means its need to be setup before hand
# D.) figure out a way to programatically make those changes instead of manually do it via the user with curl.


# Other issues:
# 1.) the recommapd path sucks. It spawns a new bash shell, so it doesn't know where rmap is installed even if in same directory. This will require a change to rts user .bashrc to add in whatever directory
# you want to use for these suckers. and source it. This will make the web terminal work with rmap.
# 2.) Consider using a directory that is mapped to nextcloud, so when rmap creates output, you can grab it from nextcloud as well.


# GITEA API ACCESS
# http://gitea.rts.lan/api/v1/users/rts/tokens
# curl -XPOST -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:$web_password http://gitea.rts.lan/api/v1/users/rts/tokens


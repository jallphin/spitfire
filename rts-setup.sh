#!/bin/bash
clear
# Reset
nocolor='\e[0m'       # Text Reset

# Regular Colors
black='\e[0;30m'        # Black
red='\e[0;31m'          # Red
green='\e[0;32m'        # Green
yellow='\e[0;33m'       # Yellow
blue='\e[0;34m'         # Blue
purple='\e[0;35m'       # Purple
cyan='\e[0;36m'         # Cyan
white='\e[0;37m'        # White

# Bold
bblack='\e[1;30m'       # Black
bred='\e[1;31m'         # Red
bgreen='\e[1;32m'       # Green
byellow='\e[1;33m'      # Yellow
bblue='\e[1;34m'        # Blue
bpurple='\e[1;35m'      # Purple
bcyan='\e[1;36m'        # Cyan
bwhite='\e[1;37m'       # White

# Underline
ublack='\e[4;30m'       # Black
ured='\e[4;31m'         # Red
ugreen='\e[4;32m'       # Green
uyellow='\e[4;33m'      # Yellow
ublue='\e[4;34m'        # Blue
upurple='\e[4;35m'      # Purple
ucyan='\e[4;36m'        # Cyan
uwhite='\e[4;37m'       # White
set -o pipefail
nextcloud_db_user=nextcloud
nextcloud_db_host=nextcloud-db
nextcloud_d_pass=rts_passw0rd
gitea_db_host=gitea-db
gitea_db_type=postgres
gitea_db_user=gitea
gitea_db_pass=gitea
initial_working_dir="$(pwd)/setup"
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

# simple spinner
spin[0]="-"
spin[1]="\\"
spin[2]="|"
spin[3]="/"

# silent log
function slog() {
tee -a $log > /dev/null 2>&1
}

#echo log
function elog() {
tee -a $log
}

#echo regular
function es() {
echo -e "${bcyan}[*] $1${nocolor}" | elog
}

#echo errors
function ee() {
echo -e "${bred}[!!!] $1${nocolor}" | elog
}

#echo warnings
function ew() {
echo -e "${byellow}[***] $1${nocolor}" | elog
}

#echo completed
function ec() {
echo -e "${bgreen}[**] $1${nocolor}" | elog
}

function check_installed() {
# check to see if an application is installed, and if not, install it.
es "Checking if '${1}' is installed..."
dpkg -s $1 2>&1 | slog
if [ $? -eq 0 ]; then
    ec "${1} is installed."
else
    ew "${1} is not installed, installing from repo."
    apt install ${1} -y 2>&1 | slog
    # Verify package is now installe
    dpkg -s ${1} 2>&1 | slog
    if [ $? -eq 0 ]; then
       ec "${1} is now installed."
    else
       ee "{1} installation failed, check logs. Exiting."
        exit
    fi
fi
sleep 3
echo
}

function add_hosts() {
if grep -qF "${ip_address} ${1}" /etc/hosts; then
  ec "${1} found."
else
  ew "adding in ${1} with ip ${ip_address} into /etc/hosts"
  echo "${ip_address} ${1}" >> /etc/hosts
fi
}

# create a fresh log if installation got interrupted
rm -rf /tmp/rts.log | slog
# remove previous rmap config if present
rm -rf /home/rts/.reconmap/config.json | slog

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
echo -e "${bwhite}#### Red Team Server Setup Script ####${nocolor}"
es "= Status"
ec "= Completed"
ew "= Warning"
ee "= Error"
es "Log file is at /tmp/rts.log for any issues."
echo

function additional_content() {
echo
es "Here's the list of tools we can clone into the local Gitea repository for team sharing:"
es "--------------------------------------------------------------------------------------------"
es "SecLists"
es "HateCrack"
es "Slowloris"
es "GhostPack"
es "HackTricks"
es "Payload All The Things"
es "Cobalt Strike ElevateKit"
es "Cobalt Strike Malleable C2 Profiles"
es "Cobalt Strike Community Kit"
es "Cobalt Strike Arsenal (not official, 3rd party)"
es "Veil Evasion Framework"
es "----------------------------------------------------------------------------------------------"
read -p "[*] Do you want to install these additional tools? --> " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
   es "Installing now"
   sleep 3
   auth_token=$(curl -s -X POST -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:h3llfury http://gitea.rts.lan/api/v1/users/rts/tokens | jq -e '.sha1' | tr -d '"')
   if [ $? -eq 0 ]; then
        ec "Gitea auth token acquired."
     else
        ee "Gitea auth token failed, check the logs to see what happened."
        exit
   fi
static_auth_token=$auth_token

seclists_clone="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/danielmiessler/SecLists.git\", \"description\": \"SecLists\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"SecLists\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
payload_all_the_things="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/swisskyrepo/PayloadsAllTheThings.git\", \"description\": \"A list of useful payloads\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"payload_all_the_things\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
cobalt_strike_elevate="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/ElevateKit.git\", \"description\": \"Cobalt Strike Elevate Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_elevate\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
cobalt_strike_c2_profiles="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/Malleable-C2-Profiles.git\", \"description\": \"Cobalt Strike Malleable C2 Profiles\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_malleable-c2\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
cobalt_strike_community_kit="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/community_kit.git\", \"description\": \"Cobalt Strike Community Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_community_kit\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
# Cobalt Strike Community kit has its own setup script, which we'll need to replicate for our local gitea instance. Best way is probably to download the tracked_repos.txt from gitea, and then use a for loop to clone those bad boys. Thing is, they are tracked...
# so mirroring is good to keep the list up to date, but how to pull the rest of the repos? something to ponder later, I guess.
# So after some thought, ask the user if he wants to download the community kit, and if so clone all of them locally using the script. A simple clone from Internet -> execute script -> done.
# If a team needs them, they can just scp or copy them from RTS to whatever host they need. To be honest, if Im going to use CS Im going to the team server on RTS anyways.
# then you can write a script to copy all the contents out of the cloned directories into one final folder containing all the scripts.

# Or better yet, if you want to mirror them all in gitea:
# pull the community kit file down: community_kit_projects="https://raw.githubusercontent.com/Cobalt-Strike/community_kit/main/tracked_repos.txt"
# then do a similar for loop in the setup script to iterate through the these with the above curl commands, mirroring all of them. That way the team can just clone them. Make sure to ask the user if they are ok with that, as it is a lot of them. 
cobalt_strike_arsenal="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/mgeeky/cobalt-arsenal.git\", \"description\": \"Cobalt Strike Battle Tested Arsenal\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_arsenal\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
veil="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Veil-Framework/Veil.git\", \"description\": \"Veil Evasion Framework\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"veil-evasion\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
hatecrack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/trustedsec/hate_crack.git\", \"description\": \"TrustedSec HateCrack\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hatecrack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
slowloris="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/gkbrk/slowloris.git\", \"description\": \"Slowloris DOS\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"slowloris\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
#nuclei=$(go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest)
ghostpack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/r3motecontrol/Ghostpack-CompiledBinaries.git\", \"description\": \"Ghostpacks C# Binaries\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"ghostpack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
hacktricks="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/carlospolop/hacktricks.git\", \"description\": \"hacktricks.xyz\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hacktricks\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' | tee -a $log > /dev/null"
echo
es "Mirroring SecLists"
eval $seclists_clone
es "Mirroring HateCrack"
eval $hatecrack
es "Mirroring Slowloris"
eval $slowloris
es "Mirroring GhostPack"
eval $ghostpack
es "Mirroring HackTricks"
eval $hacktricks
es "Mirroring Payload All The Things"
eval $payload_all_the_things
es "Mirroring Cobalt Strike ElevateKit"
eval $cobalt_strike_elevate
es "Mirroring Cobalt Strike Malleable C2 Profiles"
eval $cobalt_strike_c2_profiles
es "Mirroring Cobalt Strike Community Kit"
eval $cobalt_strike_community_kit
es "Mirroring Cobalt Strike Arsenal"
eval $cobalt_strike_arsenal
es "Mirroring Veil Evasion Framework"
eval $veil
ec "Done mirroring, expanding cobalt-strike community kit into red-share..."
ew "This will launch Cobalt Strikes custom installation script"
cd /opt/rts/
git clone http://gitea.rts.lan/rts/cobalt_strike_community_kit.git > /dev/null 2>&1  | slog
chmod +x /opt/rts/cobalt_strike_community_kit/community_kit_downloader.sh | slog
/opt/rts/cobalt_strike_community_kit/community_kit_downloader.sh | slog
mv /opt/rts/cobaltstrike_community_kit /opt/rts/red-share/cobaltstrike_community_kit | slog
ec "Finished."
sleep 3
else
   ew "Returning to main setup."
   return
fi

}

function setup_notes() {
tee -a /opt/rts/red-share/rts.txt
}

es "Starting sanity checks and initial setup"

es "Checking root status..."
# check to see if I am root
if [ "$EUID" -ne 0 ]; then
  ee "Effective UID is $EUID"
  ee "Please run as root"
  exit
else
  es "Effective UID is $EUID"
  ec "Running as root"
fi

echo
echo "rts_ip_address=${ip_address}" > ./setup/.env
echo -e "added rts_ip_address=${ip_address} to ./env" | slog

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
es "Checking hostname status..."
# check to see if hostname is set correctly
check_hostname="$(hostname)"
hosts_line="127.0.1.1	rts.lan	  rts"
if [ "${check_hostname}" != "rts" ]; then
    ee "Hostname is not set correctly (currently set to $check_hostname), setting to rts.lan"
    hostnamectl set-hostname rts | slog
    sed -i".bak" "/$check_hostname/d" /etc/hosts | slog
    echo ${hosts_line} >> /etc/hosts
    # verify hostname changed
    if [ "`(hostname -f)`" != "rts.lan" ]; then
        ee "Hostname change did not work, you need to do it manually. Exiting."
        exit
    fi
    else ec "Hostname (${check_hostname}) is correct."
fi

# ensure ssh is enabled
echo
sleep 3

es "Checking SSHd status..."
check_sshd="$(systemctl is-active ssh)"
if [ "${check_sshd}" = "inactive" ]; then
  ew "SSHd is not running, starting."
  systemctl start ssh | slog
  sleep 3
  check_new_sshd="$(systemctl is-active ssh)"
  if [ "${check_new_sshd}" = "inactive" ]; then
      ee "SSHD is not starting, check your configuration. Exiting."
  else es "SSHd successfully started."
  fi
else ec "SSH is running."
fi
echo
sleep 3

check_installed docker.io
check_installed golang
check_installed golang-go
check_installed docker-compose
check_installed jq

echo
sleep 3
#ensure rts user exists on the system, and if not create it.
es "Checking to see if rts user exists..."
getent passwd rts | slog
if [ $? -eq 0 ]; then
    ec "'rts' user  exists"
else
    ew "'rts' user does not exist, creating.."
    es "The 'rts' user will be the primary *SHARED* account that your team uses to access this instance of kali. Make sure you use a generic team password."
    read -r -s -p "[*] What password would you like for the 'rts' account? -> " rtspassword
    useradd rts -s /bin/bash -m -g adm -G dialout,cdrom,floppy,sudo,audio,dip,video,plugdev,netdev,bluetooth,wireshark,scanner,kaboxer,docker | slog
    echo "rts:$rtspassword" | chpasswd | slog
    ec "User created."
fi
echo
sleep 3
# check to make sure root belongs to docker group
es "Checking root and rts user permissions for docker..."
check_USER="root"
check_GROUP="docker"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    ec "$check_USER belongs to $check_GROUP"
else
    ew "$check_USER does not belong to $check_GROUP, adding."
    usermod –aG $check_GROUP $check_USER | slog
    ec "$check_USER added to $check_GROUP group"
fi

check_USER="rts"
if id -nG "$check_USER" | grep -qw "$check_GROUP" ; then
    ec "$check_USER belongs to $check_GROUP"
else
    ew "$check_USER does not belong to $check_GROUP, adding."
    usermod -aG $check_GROUP $check_USER | slog
    ec "$check_USER added to $check_GROUP group."
fi
echo
sleep 2
# If script was run by non-rts user in non /home/rts/rts/ directory this is a problem that we will now fix"
if [ "${initial_user}" != "rts" ] || [ "${initial_working_dir}" != "${install_path}" ]; then
	es "Copying files from current location to ${install_path}"
        if [ ! -d "${install_path}" ]
           then
               mkdir ${install_path} | slog
               chown -R rts:adm ${install_path} | slog
	   else
	       rm -rf ${install_path} | slog # I understand this clobbers a previous install directory - but if you already have it installed, why are you running this again? Clean install? 
               mkdir ${install_path} | slog
               chown -R rts:adm ${install_path} | slog
        fi
#        sudo -u rts cp -R ${initial_working_dir}/. ${install_path}
	sudo -u rts cp -R ${initial_working_dir}/covenant ${install_path} | slog
	sudo -u rts cp -R ${initial_working_dir}/hastebin ${install_path} | slog
	sudo -u rts cp ${initial_working_dir}/{.env,config.json,docker-compose.yml,environment.js,homeserver.yaml,nuke-docker.sh,scan.sh,nuke-ivre.sh,nuke.sh} ${install_path} | slog
	es "Changing working directory to ${install_path}"
        cd ${install_path}
        pwd
        ec "Assuming rts user level."
else ec "User and path look good to go."
fi
echo
sleep 3
#lets start crack-a-lackin

#check for internet access
es "Checking for Internet access"
if nc -zw1 google.com 443; then
  ec "Internet Connectivity checks successful."
else ee "Internet connectivity is *REQUIRED* to build RTS. Fix, and restart script."
fi
echo
sleep 2
sudo_1=$(sudo -u rts whoami)
sudo_2=$(sudo -u rts pwd)
#echo "sudo_1 test = $sudo_1"
#echo "sudo_2 test = $sudo_2"
es "Dropping priveleges down to rts user account."
if [ "${sudo_1}" = "rts" ]; then
   es "User Privs look good, continuing."
   if [ "${sudo_2}" = "${install_path}" ]; then
      es "Build path looks good, continuing with the build."
   else
        ee "Something is wrong and we are not in the right path. Exiting."
        exit
   fi
else
   ee "Something is wrong and we are not the right user. Exiting."
   exit
fi
echo
es "Cloning Reconmap..."
sudo -u rts git clone https://github.com/reconmap/reconmap.git ${install_path}/reconmap 2>&1 | slog
if [ $? -eq 0 ]; then
   ec "reconmap clone successful."
else
   ee "reconmap clone failed, exiting. Check your internet connectivity or github access."
   exit
fi
sudo -u rts git clone https://github.com/reconmap/agent.git ${install_path}/reconmap-agent 2>&1 | slog
if [ $? -eq 0 ]; then
   ec "reconmap-agent clone successful."
else
   ee "reconmap-agent clone failed, exiting. Check your internet connectivity or github access."
   exit
fi
sudo -u rts git clone https://github.com/reconmap/cli.git ${install_path}/reconmap-cli 2>&1 | slog
if [ $? -eq 0 ]; then
   ec "reconmap-cli  clone successful."
else
   ee "reconmap-cli clone failed, exiting. Check your internet connectivity or github access."
   exit
fi
#sudo -u rts cp ./agent-dockerfile ${install_path}/reconmap-agent/Dockerfile >/dev/null
sudo -u rts cp ${initial_working_dir}/config.json ${install_path}/reconmap/ | slog
sudo -u rts cp ${initial_working_dir}/environment.js ${install_path}/reconmap/ | slog
sudo -u rts rm ${install_path}/config.json | slog
sudo -u rts rm ${install_path}/environment.js | slog
# copy in patched terminal_handler for kali linux
sudo -u rts cp ${initial_working_dir}/terminal_handler.go ${install_path}/reconmap-agent/internal/ | slog

if [ $? -eq 0 ]; then
   ec "Reconmap setup successful."
else
   ee "Reconmap setup failed, exiting. Check your internet connectivity or github access."
   exit
fi
echo
es "Starting reconmap-agent build"
sudo -u rts make -C ${install_path}/reconmap-agent/ | slog
if [ $? -eq 0 ]; then
   ec "Reconmap-agent build successful."
else
   ee "Reconmap-agent build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
es "Starting reconmap-cli build"
sudo -u rts make -C ${install_path}/reconmap-cli/ 2>&1 | slog
if [ $? -eq 0 ]; then
   ec "Reconmap-cli build successful."
else
   ee "Reconmap-cli build failed, exiting. Something is wrong with the build or script."
   exit
fi
echo
es "Copying reconmapd & rmap to install path."
sudo -u rts cp ${install_path}/reconmap-agent/reconmapd ${install_path}/ | slog
sudo -u rts cp ${install_path}/reconmap-cli/rmap ${install_path}/ | slog
echo

es "Copying website data to install path."
sudo -u rts cp -R ${initial_working_dir}/website  ${install_path}/ | slog
echo

sudo -u rts mkdir ${install_path}/red-share | slog
sudo -u rts mkdir ${install_path/red-share/ivre | slog
sudo -u chmod -R 777 ${install_path/red-share | slog

es "Starting Docker Compose Build"
read -p "[**] Everything seems good to go to continue the docker-compose build. Continue? [y/n] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
   ec "tail -f /tmp/rts.log to follow along (build can take quite some time)"
   sleep 3
else
   ee "Not Cool!"
   exit
fi

echo
es "Stage 1 - Docker Container Building..."
sleep 3
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml build 2>&1 | slog &
pid=$! # get pid of working process
echo -n "[*] Building ${spin[0]}"
while kill -0 $pid > /dev/null 2>&1;
do
  for i in "${spin[@]}"
  do
    echo -ne "\b$i"
    sleep 0.1
  done
done
echo
if [ $? -eq 0 ]; then
   ec "Stage 1 complete, moving to stage 2."
else
   ee "Stage 1 failure, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
sleep 5
es "Stage 2 - Pulling docker images..."
sleep 5
sudo -u rts docker-compose -f ${install_path}/docker-compose.yml up -d 2>&1 | slog &
pid=$! # get pid of working process
echo -n "[*] Pulling images ${spin[0]}"
while kill -0 $pid > /dev/null 2>&1;
do
  for i in "${spin[@]}"
  do
    echo -ne "\b$i"
    sleep 0.1
  done
done
echo
if [ $? -eq 0 ]; then
   ec "Stage 2 complete, finalizing."
else
   ee "Stage 2 failure, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
sleep 5
es "Generating Matrix/Synapse configuration and restarting."
sudo -u rts docker-compose run --rm -e SYNAPSE_SERVER_NAME=matrix.rts.lan synapse generate 2>&1 | slog
if [ $? -eq 0 ]; then
    ec "Matrix/Synapse configuration generated."
else
   ee "Matrix/Synapse configuration failed. Please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
sleep 5
sudo -u rts docker-compose restart 2>&1 | slog
if [ $? -eq 0 ]; then
   ec "Docker Compose restart complete, finalizing."
else
   ee "Docker Compose restart failed, please post an issue on the RTS github or check logs. Exiting."
   exit
fi
echo
es "Adding in services to /etc/hosts"
add_hosts www.rts.lan
add_hosts gitea.rts.lan
add_hosts nextcloud.rts.lan
add_hosts ivre.rts.lan
add_hosts hastebin.rts.lan
add_hosts matrix.rts.lan
add_hosts element.rts.lan
add_hosts reconmap.rts.lan
add_hosts ssh.rts.lan

ec "Finished updating /etc/hosts."
echo
es "Sleeping 30 seconds to allow services to initialize."
sleep 30
es "Starting Configuration of webservices..."
### GITEA config CURL ####
es "Congifuring Gitea"
curl -s 'http://gitea.rts.lan/' \
  -H 'User-Agent: Mozilla/5.0 (X11; Linux x86_64; rv:78.0) Gecko/20100101 Firefox/78.0' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
  -H 'Accept-Language: en-US,en;q=0.5' \
  -H 'Connection: keep-alive' \
  -H 'Cache-Control: max-age=0' \
  -H 'Origin: null' \
  -H 'Upgrade-Insecure-Requests: 1' \
  -H 'DNT: 1' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -H 'User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.55 Safari/537.36 Edg/96.0.1054.41' \
  -H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9' \
  -H 'Accept-Language: en-US,en;q=0.9' \
  -H 'Cookie: i_like_gitea=63542a430923887a; gitea_awesome=rts; gitea_incredible=5d08bd126b945c61dec7e1ec09bde03f8f0ac2865321719d63d04596fb91f8; lang=en-US; _csrf=KuOvKkDGWFXDe67yuX5yzfXXxPQ6MTY0OTAwMjY2NjA2MDAyNDc5MQ' \
  --data-raw "db_type=postgres&db_host=gitea-db%3A5432&db_user=gitea&db_passwd=gitea&db_name=gitea&ssl_mode=disable&db_schema=&charset=utf8&db_path=%2Fdata%2Fgitea%2Fgitea.db&app_name=RTS+The+Red+Team+Server&repo_root_path=%2Fdata%2Fgit%2Frepositories&lfs_root_path=%2Fdata%2Fgit%2Flfs&run_user=git&domain=localhost&ssh_port=22&http_port=3000&app_url=http%3A%2F%2Fgitea.rts.lan&log_root_path=%2Fdata%2Fgitea%2Flog&smtp_host=&smtp_from=&smtp_user=&smtp_passwd=&enable_federated_avatar=on&enable_open_id_sign_in=on&enable_open_id_sign_up=on&default_allow_create_organization=on&default_enable_timetracking=on&no_reply_address=noreply.localhost&password_algorithm=pbkdf2&admin_name=rts&admin_passwd=$url_encoded_pass&admin_confirm_passwd=$url_encoded_pass&admin_email=root%40localhost" \
  --compressed \
  --insecure | slog
if [ $? -eq 0 ]; then
   ec "Gitea Configured."
else
  ee "Gitea configuration failed, please post an issue on the RTS github. Exiting."
  exit
fi
echo
es "Configuring Nextcloud"
docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:enable files_external 2>&1 | slog
docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:create --config datadir=/red-share -- red-share local null::null 2>&1 | slog
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
  --keepalive-time 300 | slog
if [ $? -eq 0 ]; then
   ec "NextCloud Configured."
else
   ee "NextCloud configuration failed, please post an issue on the RTS github. Exiting."
   exit
fi
echo
es "Configuring and starting reconmapd agent service in the background."
REDIS_HOST=localhost REDIS_PORT=6379 REDIS_PASSWORD=REconDIS ${install_path}/reconmapd > /dev/null 2>&1 &
echo
es "Configuring rmap."
sudo -u rts ${install_path}/rmap configure set --api-url http://rts.lan:5510 | slog
sudo -u rts ${install_path}/rmap login -u admin -p admin123 | slog
# add install_path to the base path
export PATH=$PATH:${install_path}
echo
mkdir /opt/rts/red-share
## insecure!!!!
sudo chmod 777 /etc/samba/smb.conf
# add code to check to see if the red-share is already in the file, if it is skip this.
# also add code to check and add to /etc/fstab to map the drive constantly.
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
if grep -Fq "[red-share]" /etc/samba/smb.conf
        then
                es "Samba Already configured, you are good to go."
        else
                sudo echo "[red-share]" >> /etc/samba/smb.conf
                sudo echo "comment = Redteam Share" >> /etc/samba/smb.conf
                sudo echo "path = /opt/rts/red-share" >> /etc/samba/smb.conf
                sudo echo "public = yes" >> /etc/samba/smb.conf
                sudo echo "writeable = yes" >> /etc/samba/smb.conf
                # spin up a simple http.server
                python3 -m http.server 8081 &
                sudo systemctl restart smbd.service
                sudo systemctl restart nmbd.service
                echo "[*] Samba server setup!"
fi
sleep 3
echo
## This is where we ask the user if they want to mirror additional tools and if so, start the process.
es "RTS can mirror some popular tools and set up some additional scripts/toolkits."
read -p "[*] Would you like to review and possibly install, or skip for now?-> " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
   additional_content
else
   ec "Skipping for now"
fi

### I'd love to be able to whack all the default next cloud shit and install a text file that has all of the features of RTS listed for easy reference.
clear
echo
es "[****************************************************]"
es "[****************Service Information ****************]"
es "[****************************************************]"
es
es "Linux hosts file:"
es "/etc/hosts"
es "Windows hosts file:"
es "c:\windows\system32\drivers\etc\hosts"
es
es "Copy and Paste the following into your respective systems hosts file:"
echo
ip_address=$(ip route get 1 | awk '{print $(NF-2);exit}')
for whatever in ip_address
do
  echo $ip_address rts.lan | elog
  echo $ip_address www.rts.lan | elog
  echo $ip_address gitea.rts.lan | elog
  echo $ip_address nextcloud.rts.lan |elog
  echo $ip_address ivre.rts.lan | elog
  echo $ip_address hastebin.rts.lan | elog
  echo $ip_address matrix.rts.lan | elog
  echo $ip_address element.rts.lan | elog
  echo $ip_address reconmap.rts.lan | elog
  echo $ip_address ssh.rts.lan | elog
done
echo
# Some quick configuration for reconmap
chmod -R 777 ${install_path}/reconmap/logs | slog
chmod -R 777 ${install_path}/reconmap/data/attachments | slog

# add in external storage to nextcloud (yaye!)
docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ app:enable files_external | slog
docker exec -t nextcloud_app runuser -u www-data -- /var/www/html/occ files_external:create --config datadir=/red-share -- red-share local null::null | slog
# copy nuke.sh to ivre-share so nuke-ivre.sh works
mv /opt/rts/nuke.sh /opt/rts/ivre/ivre-share/
ec "========================================================[**]" | setup_notes
ec "Main website: http://www.rts.lan" | setup_notes
ec "Gitea:        http://gitea.rts.lan" | setup_notes
ec "Nextcloud:    http://nextcloud.rts.lan" | setup_notes
ec "IVRE Scanner: http://ivre.rts.lan" | setup_notes
ec "Hastebin:     http://hastebin.rts.lan" | setup_notes
ec "Element Chat: http://element.rts.lan" | setup_notes
ec "Reconmap:     http://reconmap.rts.lan" | setup_notes
ec "SSH -Web-:    http://ssh.rts.lan" | setup_notes
ec "Convenant C2: https://rts.lan:7443" | setup_notes
ec "========================================================[**]" | setup_notes
echo | setup_notes
ec "RTS is installed to ${install_path}. Scripts and setup data live here." | setup_notes
ec "The shared directory for everything is ${install_path}/red-share and is accessible from NextCloud, locally, SMB, and even via the website at the link." | setup_notes
ec "${install_path}/red-share is intended to be the central point for red teams to share data across the team. Please utilize it for artifact, scan, reporting data." | setup_notes
ec "The username and password for Gitea and Nextcloud are:" | setup_notes
ew "rts/$web_password" | setup_notes
ec "The username and password for Reconmap is:" | setup_notes
ew "admin/admin123" | setup_notes
#es "Be sure to visit http://nextcloud.rts.lan/index.php/core/apps/recommended in your browser to install recommended applications." | setup_notes
es "Log file moved from /tmp/rts.log to ${install_path}/rts.log" | setup_notes
es "scan.sh -> Scan script to order IVRE to scan a host/network/range." | setup_notes
es "nuke-ivre.sh -> orders IVRE to completely reset/wipe its database." | setup_notes
es "nuke-docker.sh -> completely destroys docker environment for fresh install on same box." | setup_notes
es "rmap -> Reconmap CLI interface. Refer to its github for instructions." | setup_notes
ec "This concludes RTS installation."
ec "Hack the Planet!"
mv /tmp/rts.log /opt/rts/
chown rts:adm /opt/rts/rts.log

# Other issues:
# 1.) the recommapd path sucks. It spawns a new bash shell, so it doesn't know where rmap is installed even if in same directory. This will require a change to rts user .bashrc to add in whatever directory
# you want to use for these suckers. and source it. This will make the web terminal work with rmap.
# 2.) Consider using a directory that is mapped to nextcloud, so when rmap creates output, you can grab it from nextcloud as well.


# GITEA API ACCESS
# http://gitea.rts.lan/api/v1/users/rts/tokens
# curl -XPOST -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:$web_password http://gitea.rts.lan/api/v1/users/rts/tokens
set +o pipefail

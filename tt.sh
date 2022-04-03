#!/bin/bash
auth_token=$(curl -s -X POST -H "Content-Type: application/json"  -k -d '{"name":"rts"}' -u rts:h3llfury http://gitea.rts.lan/api/v1/users/rts/tokens | jq -e '.sha1' | tr -d '"')
if [ $? -eq 0 ]; then
     echo "[*] Auth token aquired"
  else
     echo "[!!!] Auth token failed. "
      exit
    fi
static_auth_token=$auth_token

seclists_clone="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/danielmiessler/SecLists.git\", \"description\": \"SecLists\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"SecLists\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
payload_all_the_things="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/swisskyrepo/PayloadsAllTheThings.git\", \"description\": \"A list of useful payloads\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"payload_all_the_things\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
cobalt_strike_elevate="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/ElevateKit.git\", \"description\": \"Cobalt Strike Elevate Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_elevate\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
cobalt_strike_c2_profiles="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/Malleable-C2-Profiles.git\", \"description\": \"Cobalt Strike Malleable C2 Profiles\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_malleable-c2\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
cobalt_strike_community_kit="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Cobalt-Strike/community_kit.git\", \"description\": \"Cobalt Strike Community Kit\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_community_kit\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
# Cobalt Strike Community kit has its own setup script, which we'll need to replicate for our local gitea instance. Best way is probably to download the tracked_repos.txt from gitea, and then use a for loop to clone those bad boys. Thing is, they are tracked...
# so mirroring is good to keep the list up to date, but how to pull the rest of the repos? something to ponder later, I guess.
# So after some thought, ask the user if he wants to download the community kit, and if so clone all of them locally using the script. A simple clone from Internet -> execute script -> done.
# If a team needs them, they can just scp or copy them from RTS to whatever host they need. To be honest, if Im going to use CS Im going to the team server on RTS anyways.
# then you can write a script to copy all the contents out of the cloned directories into one final folder containing all the scripts.

# Or better yet, if you want to mirror them all in gitea:
# pull the community kit file down: community_kit_projects="https://raw.githubusercontent.com/Cobalt-Strike/community_kit/main/tracked_repos.txt"
# then do a similar for loop in the setup script to iterate through the these with the above curl commands, mirroring all of them. That way the team can just clone them. Make sure to ask the user if they are ok with that, as it is a lot of them. 
cobalt_strike_arsenal="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/mgeeky/cobalt-arsenal.git\", \"description\": \"Cobalt Strike Battle Tested Arsenal\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"cobalt_strike_arsenal\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
veil="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/Veil-Framework/Veil.git\", \"description\": \"Veil Evasion Framework\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"veil-evasion\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
hatecrack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/trustedsec/hate_crack.git\", \"description\": \"TrustedSec HateCrack\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hatecrack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
slowloris="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/gkbrk/slowloris.git\", \"description\": \"Slowloris DOS\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"slowloris\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
#nuclei=$(go install -v github.com/projectdiscovery/nuclei/v2/cmd/nuclei@latest)
ghostpack="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/r3motecontrol/Ghostpack-CompiledBinaries.git\", \"description\": \"Ghostpacks C# Binaries\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"ghostpack\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' > /dev/null"
hacktricks="curl -s -X 'POST' 'http://gitea.rts.lan/api/v1/repos/migrate' -H 'Authorization: token ${static_auth_token}' -H 'accept: application/json' -H 'Content-Type: application/json' -d '{ \"clone_addr\": \"https://github.com/carlospolop/hacktricks.git\", \"description\": \"hacktricks.xyz\", \"issues\": false, \"labels\": false, \"lfs\": false, \"milestones\": false, \"mirror\": false, \"private\": false, \"pull_requests\": false, \"releases\": false, \"repo_name\": \"hacktricks\", \"repo_owner\": \"rts\", \"service\": \"git\", \"uid\": 0, \"wiki\": false }' >/dev/null"


echo "[*] Mirroring SecLists"
eval $seclists_clone
echo "[*] Mirroring HateCrack"
eval $hatecrack
echo "[*] Mirroring Slowloris"
eval $slowloris
echo "[*] Mirroring GhostPack"
eval $ghostpack
echo "[*] Mirroring HackTricks"
eval $hacktricks
echo "[*] Mirroring Payload All The Things"
eval $payload_all_the_things
echo "[*] Mirroring Cobalt Strike ElevateKit"
eval $cobalt_strike_elevate
echo "[*] Mirroring Cobalt Strike Malleable C2 Profiles"
eval $cobalt_strike_c2_profiles
echo "[*] Mirroring Cobalt Strike Community Kit"
eval $cobalt_strike_community_kit
echo "[*] Mirroring Cobalt Strike Arsenal"
eval $cobalt_strike_arsenal
echo "[*] Mirroring Veil Evasion Framework"
eval $veil

# Set up the samba share and make the drive sharable even after reboot by adding entry into /etc/fstab
# add code to check if directory is already made if so exit
mkdir /opt/rts/red-share
## insecure!!!!
sudo chmod 777 /etc/samba/smb.conf
# add code to check to see if the red-share is already in the file, if it is skip this.
# also add code to check and add to /etc/fstab to map the drive constantly.
sudo cp /etc/samba/smb.conf /etc/samba/smb.conf.backup
if grep -Fq "[red-share]" /etc/samba/smb.conf
	then
		echo "[*] Samba Already configured, you are good to go."
		exit
	else
		sudo echo "[red-share]" >> /etc/samba/smb.conf
		sudo echo "comment = Redteam Share" >> /etc/samba/smb.conf
		sudo echo "path = /opt/rts/red-share" >> /etc/samba/smb.conf
		sudo echo "public = yes" >> /etc/samba/smb.conf
		sudo echo "writeable = yes" >> /etc/samba/smb.conf
		# spin up a simple http.server
		python3 -m http.server 8080 &
		sudo systemctl restart smbd.service
		sudo systemctl restart nmbd.service
		echo "[*] Samba server setup!"
fi


### I'd love to be able to whack all the default next cloud shit and install a text file that has all of the features of RTS listed for easy reference.

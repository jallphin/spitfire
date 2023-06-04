<p align="center">
<img width="600" height="650" src="https://github.com/jallphin/red-team-server/blob/main/setup/website/RTS_logo.png?raw=true">
</p>

<p alight="left">
# Red Team Server (RTS)
Deployable Nerve Center for Pentest Engagements 

Overview:

Red Team Server is a unified stack of applications and installations to support collaborative Red Team Engagements using a docker-compose. 
It consists of:
- Rich Text/Modern Collaboration Tools (via NextCloud)
- Unified Group & Team Communication (web based & client based using Matrix)
- A web-enabled git repository containing curated tools you and your team needs on the regular (via Gitea)
- Automated Reconnaissance, Scanning and Enumeration- Screenshots included (via IVRE)
- Centralized C2 Infrastructure (via Sliver, MITRE Caldera, Powershell Empire and Covenant)
- At your fingertips references, despite connectivity issues (MITRE Att&ck Navigator & References, Payload All the Things, Hacktricks, etc.)
- Centralized Vulnerability Management and Reporting (via Penetration Collaboration Framework)
- Cloud based artifact storage and later retrieval (via NextCloud)
- Convienent "pastebin" functionality for working and collaborting on the fly (via Hastebin)
- Command shortcut script to help redteams remember proper syntax (Orange Cyber Defense Arsenal)
- Web based SSH access (via wetty)
- Apache Guacamole access (via Apache Guacamole)

# Screenshots
<img width="600" height="650" src="https://github.com/jallphin/red-team-server/blob/development/setup/website/rts-menu-1.png?raw=true">
<img width="600" height="650" src="https://github.com/jallphin/red-team-server/blob/development/setup/website/rts-menu-2.png?raw=true">
<img width="600" height="650" src="https://github.com/jallphin/red-team-server/blob/development/setup/website/rts-web-page-1?raw=true">

## Getting Started
While the above description of RTS is how it's *intended* to deploy, you can also deploy it in a standard Virtual Machine as well. The one gotcha (for now) is that all the services domain names must be locally mapped into each accessing systems ```host``` file in order for the reverse proxy to function. 

Other than that, you clone this repository into a blank kali linux install, 

> ```chmod +x ./rts.sh``` 

and execute

 > ```rts.sh```

During installation you can watch the install logs by using ```tail -f /tmp/rts.log```

## Using

As mentioned above, you'll need to edit your testing system (defined as the the system you will be using to conduct penetration tests against a target) host file. The ```rts.sh``` script will tell you all the relevant hostnames and IP's so it should just be a simple copy + paste operation. 

Once done, everything *should* be setup and installed. Just navigate to any of the URL's and use as the author of that software intended. 

# RTS Deployment Configurations
## As a standalone mini server
At it's heart RTS is just a culmination of others people hard work and ingenunity which has been curated, automated, and made easy to install.
RTS is meant to be installed on a portable computing device that you can take with you to pentest engagements. 
How our team deploys RTS:
1. ASUS Vivomini (https://www.asus.com/us/Displays-Desktops/Mini-PCs/VivoMini/)
2. ESXI 6.5 installed (the ESXi 6.5 image actually needs to modified with proper LAN drivers to work)
3. Kali as a virtual machine running inside ESXI 6.5
4. Each service running a docker micro-service utilizing docker-compose and a master bash script for automation. 

The above setup allows us to deploy a small RTS system to a target network for local usage.
When RTS is deployed this way, it provides a convienent, deployable nerve center for any pentest engagement. 

## As a virtual machine
RTS can also be deployed as a virtual machine for easier deployments:
1. Install kali linux
2. Clone this repository
3. Install
4. Ensure RTS's network adapter in the virtual machine is set to 'bridged' 

# RTS Components

## Main Packages:
1. Kali Linux (https://www.kali.org/)
2. Matrix Synapse HomeServer (https://github.com/matrix-org/synapse)
3. Element Web Client (https://github.com/vector-im/element-web)
4. IVRE Recon Framework (https://github.com/ivre/ivre)
5. Reconmap Framework (https://github.com/reconmap) **Disabled until further notice due to app breakage**
6. Penetration Testing Collaboration Framework - PCF (https://gitlab.com/invuls/pentest-projects/pcf)
7. Nextcloud (https://github.com/nextcloud)
8. Gitea (https://github.com/go-gitea/gitea)
9. CyberChef (https://github.com/gchq/CyberChef) 
10. Hastebin (https://github.com/toptal/haste-server)
11. Nginx (https://github.com/nginx)
12. Nginx-proxy (https://github.com/nginx-proxy/nginx-proxy)
13. Portainer.io (https://github.com/portainer/portainer) - For managing the containers and stack. 

## Auxilliary Modules:
1. Cobalt Strike Community Kit (https://github.com/Cobalt-Strike/community_kit)
2. Daniel Miessler's SecLists (https://github.com/danielmiessler/SecLists)
3. Trusted Sec's Hatecrack (https://github.com/trustedsec/hate_crack)
4. Slowloris (https://github.com/gkbrk/slowloris)
5. Ghostpack Compiled Binaries (https://github.com/r3motecontrol/Ghostpack-CompiledBinaries)
6. Veil Evasion Framework (https://github.com/Veil-Framework/Veil)
7. Cobalt Strike Elevation Kit (https://github.com/Cobalt-Strike/ElevateKit.git)
8. Cobalt Strike C2 Profiles (https://github.com/Cobalt-Strike/Malleable-C2-Profiles.git)
9. Cobalt Strike Arsenal (https://github.com/mgeeky/cobalt-arsenal.git)
 
## References:
1. LOLBins (https://lolbas-project.github.io/)
2. GTFOBins (https://gtfobins.github.io/)
3. Hacktricks (https://github.com/carlospolop/hacktricks)
4. Payload All The Things (https://github.com/swisskyrepo/PayloadsAllTheThings)
5. MITRE ATT&CK Navigator (https://github.com/mitre-attack/attack-navigator)
6. MITRE ATT&CK Reference (https://github.com/mitre-attack/attack-website.git)
7. Opensource Penetration Testing Standards

## C2 Frameworks:
1. Convenant C2 Framework (https://github.com/cobbr/Covenant)
2. Sliver (https://github.com/BishopFox/sliver)
3. MITRE Caldera (https://github.com/mitre/caldera)
4. Powershell Empire & Starkiller (https://github.com/EmpireProject/Empire)

## Additional toolage:
1. Orange Cyberdefense's Arsenal shortcut script (https://github.com/Orange-Cyberdefense/arsenal)
2. Glow Markdown Command Line Reader (https://github.com/charmbracelet/glow)
3. PEASS-NG Privelege Escalation Tools (https://github.com/carlospolop/PEASS-ng)
4. Wetty Terminal Access in a webpage (https://github.com/butlerx/wetty)
5. Properly configures Metasploit for shared database connectivity - allowing team collaboration. 

# Troubleshooting
## Environment does not come up (docker problems)
Typically, if an install fails its because one of the upstream packages has changed and I haven't had time to update it yet.
If this happens, especially with something in docker-compose.yml the easiest fix is to just not install it in the menu, and add it in later with your custom fixes.
You can do this by simply re-running ```rts.sh``` and de-selecting the offending packages. The setup script should not stomp on a previous installation, so it should just adjust it.
The script dynamically updates ```docker-compose.yml``` at runtime, so deselecting the package from the script menu will simply remove it from ```docker-compose.yml```
## Gitea Mirroring
The second largest issue is with the Gitea package - as they often update the API and this breaks a number of things with the installation. This is the first thing you should check if nothing is being mirrored to Gitea.
Usually it is a problem with the 'auth-token'. 

# Thanks / Credit
Thanks to all of the above authors of the software linked above. Without your outstanding hard work, ingenunity and selfless dedication to open source software none of this would be possible. With that being said, if you would like direct credit here, please reach out to me with your name, preferred contact method (if any), citations you may want to be included, and/or any other links to your work and I will put them here. 
</p>
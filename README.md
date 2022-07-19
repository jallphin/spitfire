# Red Team Server (RTS)
Deployable Nerve Center for Pentest Engagements 

Overview:

How many times have you been on a pentest engagement and wished you had something (capability, software, tool)?
How hard is it to constantly build new images, install all the tools, and have all the software you want at your finger tips? Especially when testing closed networks, standalone systems, etc. 

What if you could bring along a small, portable server that had:
1. Rich Text/Modern Collaboration Tools
2. Unified Group & Team Communication (web based & client based)
3. A web-enabled git repository containing curated tools you and your team needs on the regular
4. Automated Reconnaissance, Scanning and Enumeration- Screenshots included
5. Centralized C2 Infrastructure
6. At your fingertips references, despite connectivity issues
7. Centralized Vulnerability Management and Reporting
8. Cloud based artifact storage and later retrieval
9. Convienent "pastebin" functionality for working and collaborting on the fly
10. Command shortcut script to help redteams remember proper syntax

# Welcome to RTS

At it's heart RTS is just a culmination of others people hard work and ingenunity which has been curated, automated, and made easy to install.
RTS is meant to be installed on a portable computing device that you can take with you to pentest engagements. 
The way we use this guy:
1. ASUS Vivomini (https://www.asus.com/us/Displays-Desktops/Mini-PCs/VivoMini/)
2. ESXI 6.5 installed (the ESXi 6.5 image actually needs to modified with proper LAN drivers to work)
3. Kali as a virtual machine running inside ESXI 6.5
4. Each service running a docker micro-service utilizing docker-compose and a master bash script for automation. 

The culmination of the all four steps above results in something we call RTS. 

When RTS is deployed this way, it provides a convienent, deployable nerve center for any pentest engagement. 

# Composition
1. Kali Linux (https://www.kali.org/)
2. Matrix Synapse HomeServer (https://github.com/matrix-org/synapse)
3. Element Web Client (https://github.com/vector-im/element-web)
4. IVRE Recon Framework (https://github.com/ivre/ivre)
5. Reconmap Framework (https://github.com/reconmap) **Disabled until further notice due to app breakage**
6. Convenant C2 Framework (https://github.com/cobbr/Covenant) (still in work)
7. Nextcloud (https://github.com/nextcloud)
8. Gitea (https://github.com/go-gitea/gitea)
9. Hastebin (https://github.com/toptal/haste-server)
10. LOLBins (https://lolbas-project.github.io/)
11. GTFOBins (https://gtfobins.github.io/)
12. Nginx (https://github.com/nginx)
13. Nginx-proxy (https://github.com/nginx-proxy/nginx-proxy)
14. Opensource Penetration Testing Standards
15. Orange Cyberdefense's Arsenal shortcut script (https://github.com/Orange-Cyberdefense/arsenal)


# Get Started
While the above description of RTS is how it's *intended* to deploy, you can also deploy it in a standard Virtual Machine as well. The one gotcha (for now) is that all the services domain names must be locally mapped into each accessing systems ```host``` file in order for the reverse proxy to function. 

Other than that, you clone this repository into a blank kali linux install, ```chmod +x ./rts-setup``` and execute. 

# Using

As mentioned above, you'll need to edit your testing system (defined as the the system you will be using to conduct penetration tests against a target) host file. The ```rts-setup.sh``` script will tell you all the relevant hostnames and IP's so it should just be a simple copy + paste operation. 

Once done, everything *should* be setup and installed. Just navigate to any of the URL's and use as the author of that software intended. 

# Thanks / Credit
Thanks to all of the above authors of the software linked above. Without your outstanding hard work, ingenunity and selfless dedication to open source software none of this would be possible. With that being said, if you would like direct credit here, please reach out to me with your name, preferred contact method (if any), citations you may want to be included, and/or any other links to your work and I will put them here. 

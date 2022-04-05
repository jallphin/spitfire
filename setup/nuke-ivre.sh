#!/bin/bash
echo -e "[*] Nuking IVRE database"
docker exec -t -w /red-share/ivre/scans ivreclient ./nuke.sh

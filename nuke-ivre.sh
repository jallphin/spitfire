#!/bin/bash
echo -e "[*] Nuking IVRE database"
docker exec -t -w /ivre-share ivreclient ./nuke.sh

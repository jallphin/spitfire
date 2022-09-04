#!/bin/bash
while :
do
 sleep 60
 curl http://www.rts.lan > /dev/null 2>&1
 if [ $? -eq 0 ]; then
     logger [*] RTS is up.
 else
     logger [*] RTS is down, attempting to restart services.
     systemctl restart docker
     docker-compose -f /opt/rts/docker-compose.yml restart
     sleep 15
     # Verify RTS is restored
     curl http://www.rts.lan
     if [ $? -eq 0 ]; then
        logger [*] RTS has been restored.
     else
        logger [*] RTS could not be restored. Manual intervention required.
     fi
 fi
done

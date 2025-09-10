#!/bin/bash

### Variables
listrudder=/tmp/listrudder
allserverslist=/tmp/allserverslist
filteredserverslist=/tmp/filteredserverslist
norudderservers=/usr/local/sbin/norudderservers
results=/tmp/results

#Listing of servers configured on Rudder
ssh root@be-rudder "rudder-cli node list --skip-verify | grep hostname | awk '{print $2}' | cut -d '\"' -f4 | cut -d '.' -f1" > $listrudder
####################################

#Listing of active VMs and containers on Proxmox's clusters
ssh burp@galaxie5 'sudo pvesh get /cluster/resources -type vm --output-format yaml | grep -B4 running | egrep -i 'name' | cut -d " " -f4 | sort' > $allserverslist
ssh burp@galaxie1-po 'sudo pvesh get /cluster/resources -type vm --output-format yaml | grep -B4 running | egrep -i 'name' | cut -d " " -f4 | sort' >> $allserverslist

#Deletion of servers intentionally not backed up by burp
grep -vw -f $norudderservers $allserverslist > $filteredserverslist

#Listing of known and unconfigured servers on burp
grep -vw -f $listrudder $filteredserverslist > $results

#Sending results by email
unbackedupservers=$(cat $results)
if [ -s $results ]
then
        mail -s "$(hostname -s) - $(basename $0) : some servers are not configured in Rudder" system@esiee.fr <<< $(printf "%s\r\n%s\n" "Some servers are not configured in Rudder :" "" "$unbackedupservers" "" "If this is unintentionnal, please check pending or missing nodes in Rudder." "" "If this is an expected configuration, please add it to rudder servers exclusion list : ssh root@burp \"echo 'someserver' >> $norudderservers\".")
    else
            cat $results | /usr/bin/mail -s "SUCCESS : All known servers are configured in Rudder" system@esiee.fr
        fi

        #Deletion of temporary files
        rm $listburp $allserverslist $filteredserverslist $results
#!/bin/bash

### Variables
listrudder=/tmp/listrudder
allserverslist=/tmp/allserverslist
filteredserverslist=/tmp/filteredserverslist
norudderservers=/usr/local/sbin/norudderservers
results=/tmp/results

# On liste les serveurs dans la cli de rudder
ssh root@be-rudder "rudder-cli node list --skip-verify | grep hostname | awk '{print $2}' | cut -d '\"' -f4 | cut -d '.' -f1" > $listrudder

# On liste les CT et VM des clusters proxmox
ssh burp@galaxie5 'sudo pvesh get /cluster/resources -type vm --output-format yaml | grep -B4 running | egrep -i 'name' | cut -d " " -f4 | sort' > $allserverslist
ssh burp@galaxie1-po 'sudo pvesh get /cluster/resources -type vm --output-format yaml | grep -B4 running | egrep -i 'name' | cut -d " " -f4 | sort' >> $allserverslist

# Suppression des serveurs non sauvegardés par burp
grep -vw -f $norudderservers $allserverslist > $filteredserverslist

# Liste des serveurs connus et non sauve dans burp
grep -vw -f $listrudder $filteredserverslist > $results

unbackedupservers=$(cat $results)
if [ -s $results ]
then
        mail -s "$(hostname -s) - $(basename $0) : some servers are not configured in Rudder" system@esiee.fr <<< $(printf "%s\r\n%s\n" "Some servers are not configured in Rudder :" "" "$unbackedupservers" "" "If this is unintentionnal, please check pending or missing nodes in Rudder." "" "If this is an expected configuration, please add it to rudder servers exclusion list : ssh root@burp \"echo 'someserver' >> $norudderservers\".")
    else
            cat $results | /usr/bin/mail -s "SUCCESS : All known servers are configured in Rudder" system@esiee.fr
        fi

        # delete des fichiers temp
        rm $listburp $allserverslist $filteredserverslist $results

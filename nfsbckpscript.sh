#!/bin/bash

truncate -s 0 errors.log
current_date=$(date +%Y-%m-%d)
nfs_var=( $(mount -l | grep nfs | awk '{print $3}') )
#nfs_var=("/dba" "/dba2" "/backup")
declare -p nfs_var

#If the backup mountpoint is mounted we can start the rsync process
if mountpoint -q /backup;
then
    #Iterating over the mount points in the list provided.
    for value in "${nfs_var[@]}"
    do
        if [[ $value != /backup ]]
        then
            rsync -auP $value/ /backup/$value
            #if the last exit code was not eq to 0 then try again the rsync process
            if [ "$?" -ne "0" ]
            then
                rsync -avuP $value/ /backup/$value 2>> errors.log
                echo "Script ran once more for $value" >> errors.log
            fi
        fi
    done
else
    mountpoint /mnt/backup &>> errors.log
fi
echo "Kindly look at the attached" | mail -s "NFSbackup $current_date" user@example.com -A errors.log
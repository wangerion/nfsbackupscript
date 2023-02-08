#!/bin/bash

truncate -s 0 errors.log

mount_checker () {
    if mountpoint -q "$1";
    then
        return 0
    else
        mount "$1"
        if mountpoint -q "$1";
        then
            echo "NFS $1 succesfully mounted." >> errors.log
            return 0
        fi
        echo "NFS $1 is not mounted." >> errors.log
        return 1
    fi
}

current_date=$(date +%d-%m-%Y)
#nfs_var=( $(mount -l | grep nfs | awk '{print $3}') )
nfs_var=("/dba" "/dba2" "/backup")
#declare -p nfs_var
excluded_nfs=/backup

#If the backup mountpoint is mounted we can start the rsync process
if mount_checker $excluded_nfs;
then
    #Iterating over the mount points in the list provided.
    for value in "${nfs_var[@]}"
    do
        if [[ $value != "$excluded_nfs" ]]
        then
            if mount_checker "$value";
            then
                rsync -au $value/ /backup/$value --dry-run
                #if the last exit code was not eq to 0 then try again the rsync process
                if [ "$?" -ne "0" ]
                then
                    rsync -au $value/ /backup/$value --dry-run 2>> errors.log
                    echo "Script ran once more for $value" >> errors.log
                fi
            fi
        fi
    done
fi
#Size is > 0 bytes
if [[ -s "errors.log" ]]
then
    echo "Kindly look at the attached" | mail -s "$current_date" user@example.com -A errors.log
fi
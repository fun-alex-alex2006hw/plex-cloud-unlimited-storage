#!/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

#########################
# Configuration Options #
#########################

# ACD Mount Point
ACD_MOUNT="/plex/.acd"

# Log file location
LOG_FILE="/var/log/scripts/check-acd-mount/check-acd-mount.log"

# Process ID file
PIDFILE=/var/run/check_acd_mount.pid

# Mount tries
UNMOUNT_TRIES=1
MOUNT_TRIES=1
UNMOUNT_SLEEP=1m



########################
# End of Configuration #
########################



####################
#    Functions     #
####################

function write_log {
    mkdir -p $(dirname "${LOG_FILE}")
    echo "[$(date --rfc-3339=seconds)]-$$: $*" >> $LOG_FILE
}

function clean_up {
  write_log $(rm -vf $PIDFILE)
  if [ $(stat -c%s "$LOG_FILE") -ge 5000000 ]; then
    savelog -tpj $LOG_FILE
  fi
  exit $1
}

####################
# End of Functions #
####################

trap clean_up SIGHUP SIGINT SIGTERM

write_log "Starting check_ACD_mount.sh script"

if [ -f $PIDFILE ]; then
    PID=$(cat $PIDFILE)
    ps -p $PID > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        write_log "Previous job is already running"
        exit 1
    else
        ## Process not found assume not running
        echo $$ > $PIDFILE
        if [ $? -ne 0 ]; then
            write_log "Could not create PID file"
            exit 1
        fi
    fi
else
    echo $$ > $PIDFILE
    if [ $? -ne 0 ]; then
        write_log "Could not create PID file"
        exit 1
    fi
fi

# make sure we can see folders inside the mount point
FOLDER_COUNT=$(ls -l $ACD_MOUNT  | grep -v '^total' | wc -l)
if [ $FOLDER_COUNT -gt 0 ]; then
    write_log "Everything Looks ok (Folder count: $FOLDER_COUNT)"
else
  # Check if the folder is mounted before trying to unmount
  CHECK_MOUNTPOINT=$(mount | grep $ACD_MOUNT)
  if [ $? -eq 0 ]; then
    
    # There was an issue with the mount point, attempting to unmount and remount
    write_log "Something is wrong (Folder count: $FOLDER_COUNT)"

    while : ; do
      write_log "Attempting to unmount the folder (try $UNMOUNT_TRIES)"
      FUSE_UNMOUNT=$(fusermount -uz $ACD_MOUNT 2>&1)
      if [ $? -ne 0 ]; then
        # it failed
        # log the error the log file
        write_log $FUSE_UNMOUNT
        # increase interation count
        ((UNMOUNT_TRIES++))
        # sleep for time before trying to unmount again
        write_log "Sleeping for $UNMOUNT_SLEEP beforing trying to unmount again"
        sleep $UNMOUNT_SLEEP
      else
        # the unmount worked, break out of the loop
        break
      fi
    done
  fi
  
  while : ; do
    write_log "Attempting to mount the folder (try $MOUNT_TRIES)"
    $FUSE_MOUNT=$(acd_cli mount $ACD_MOUNT)
    FOLDER_COUNT=$(ls -l $ACD_MOUNT  | grep -v '^total' | wc -l)
    if [ $FOLDER_COUNT -gt 0 ]; then
      # it worked
      write_log "Everything Looks ok (Folder count: $FOLDER_COUNT)"
      # the unmount worked, break out of the loop
      break
    fi
    write_log $FUSE_MOUNT
    ((MOUNT_TRIES++))
  done
fi

clean_up

# Intial script is below
<<COMMENT1
syncresult=$(/usr/local/bin/acdcli sync 2>&1)
if [ $(echo $syncresult | grep -i error | wc -l) -gt 0 ]; then
        echo Error with the DB
        rm ~/.cache/acd_cli/nodes.db
        /usr/local/bin/acdcli sync
        sleep 10
fi
COMMENT1
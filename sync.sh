#!/bin/bash

## Specify Email Options
emailsendnm="Niftsync Service"
emailtoaddr="email@gmail.com"
alertsuberror="Alert: The Niftsync Service on $HOSTNAME Encountered an Error"
alertsubrep="Report for Niftsync Service on $HOSTNAME"

## Specify remote fileshare mountpoint
remotesrv="/share"
## Specify local directory as sync source
localsrv="/tank"
## Specifiy whether script should always notify or only if there's a problem
erroronly="false"

## Set environment for cron
PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/niftsync

## End of user configured options ##


## Ensure working directory is always same as script (for cron)
cd "${0%/*}"

## Setup Local Working Directories
mkdir -p logs
mkdir -p tmp

## Remove log entries older than 30 days
find logs/ -type f -name 'log*' -mtime +30 -exec rm {} +

## Creates logfile
log="logs/log-`date +%m-%d-%Y`"
date=`date '+%H:%M:%S %m-%d-%Y'`
touch $log
echo "Starting file sync script - $date..." > $log

## Checks if remote server share is mounted
if  mountpoint -q $remotesrv; then
    echo "Remote server share is already mounted." >> $log
else
    echo "Remote server share is not mounted." >> $log
    mounted="false"
fi

## Attempts to mount remote server share if not mounted already
if [[ $mounted = "false" ]]; then
    echo "Attempting to mount remote server share..." >> $log
    mount -a
else
    :
fi

## Checks if previous mount attempt was successful
if mountpoint -q $remotesrv && [[ $mounted = "false" ]]; then
    echo "Remote server share was mounted successfully." >> $log
elif [[ $(mountpoint -q $remotesrv) != 1 ]] && [[ $mounted = "false" ]]; then
    printf "\nERROR: Script could not mount the remote file share. Ensure the remote host is online, can be pinged from this host, and that the fstab entry for the mount is correct." >> $log

    ## Prepare log content with HTML formatting
    perl -ne 'print "$_<br />"' $log > tmp/log.sending

    ## Populate email template with relevant data
    mailsend="tmp/mail.sending"
    cp mail.template $mailsend
    emailheader="Could Not Mount the Remote File Share"
    perl -pi -e 's#%%emailsendnm%%#'"$emailsendnm"'#' $mailsend
    perl -pi -e 's#%%emailsubject%%#'"$alertsuberror"'#' $mailsend
    perl -pi -e 's#%%emailheader%%#'"$emailheader"'#' $mailsend
    perl -pi -e 's#%%emailmessage%%#'"`cat tmp/log.sending`"'#' $mailsend

    # Send the notification email
    cat $mailsend | msmtp -a gmail $emailtoaddr

    # Clean up temp files
    rm -r tmp
    exit 1
fi

## Sets start time for sync operation
SECONDS=0

## Runs sync operation using rsync
echo "Starting the sync operation..." >> $log
if rsync -raq --delete $localsrv $remotesrv; then
    duration=$SECONDS
    ## Format duration counter for sync operations longer than 1 hour
    if [[ $duration > "3600" ]]; then
        durhrs=$(($duration / 3600))
        durmin=$(($duration % $durhrs / 60))
        dursec=$(($duration % 60))
        printf "\nThe Sync operation completed successfully after $durhrs hr $durmin min $dursec sec." >> $log
    else
        printf "\nThe sync operation completed successfully after $(($duration / 60)) min and $(($duration % 60)) sec." >> $log
    fi

    if [[ $erroronly = "false" ]]; then

        ## Prepare log content with HTML formatting
        perl -ne 'print "$_<br />"' $log > tmp/log.sending

        ## Populate email template with relevant data
        mailsend="tmp/mail.sending"
        cp mail.template $mailsend
        emailheader="Sync Operation Completed Successfully"
        perl -pi -e 's#%%emailsendnm%%#'"$emailsendnm"'#' $mailsend
        perl -pi -e 's#%%emailsubject%%#'"$alertsubrep"'#' $mailsend
        perl -pi -e 's#%%emailheader%%#'"$emailheader"'#' $mailsend
        perl -pi -e 's#%%emailmessage%%#'"`cat tmp/log.sending`"'#' $mailsend

        # Send the notification email
        cat $mailsend | msmtp -a gmail $emailtoaddr

       # Clean up temp files
       rm -r tmp

    else
        :
    fi

else
   duration=$SECONDS
   ## Format duration counter for sync operations longer than 1 hour
   if [[ $duration > "3600" ]]; then
       durhrs=$(($duration / 3600))
       durmin=$(($duration % $durhrs / 60))
       dursec=$(($duration % 60))
       printf "\nERROR: Something went wrong with the sync operation after $durhrs hr $durmin min $dursec sec. Try running a sync manually for further information." >> $log
   else
       printf "\nERROR: Something went wrong with the sync operation after $(($duration / 60)) min and $(($duration % 60)) sec. Try running a sync manually for further information." >> $log
   fi

    ## Prepare log content with HTML formatting
    perl -ne 'print "$_<br />"' $log > tmp/log.sending

    ## Populate email template with relevant data
    mailsend="tmp/mail.sending"
    cp mail.template $mailsend
    emailheader="An Error Occured During the Sync Operation"
    perl -pi -e 's#%%emailsendnm%%#'"$emailsendnm"'#' $mailsend
    perl -pi -e 's#%%emailsubject%%#'"$alertsuberror"'#' $mailsend
    perl -pi -e 's#%%emailheader%%#'"$emailheader"'#' $mailsend
    perl -pi -e 's#%%emailmessage%%#'"`cat tmp/log.sending`"'#' $mailsend

    # Send the notification email
    cat $mailsend | msmtp -a gmail $emailtoaddr

    # Clean up temp files
    rm -r tmp

    exit 1

fi

exit 0

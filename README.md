# niftsync
A directory replication script with HTML email alerts.

# Intro
This tool is designed for use in cases where file replication between two directories with email alerts is desired. The original implimentation was for VM backup replication between two servers over NFS.

The script relies on a few dependencies to function properly. Namely the ``ssmtp`` package for handling email sending, ``rsync`` to handle the actual data replication, and ``perl`` for generating said email reports. In addition, the default configuration for this script requires its connection to a Gmail account in order to send emails.

# Setup
To get started (and after the aformentioned prerequisites have been installed/updated), the ``ssmtp.conf`` file should be edited to reflect the credentials to the Gmail account to be used for sending email reports. After editing the file, save and close it and move it to ``/etc/ssmtp``.

Next, the ``sync.sh`` file should be opened for editing. The default configurable options are:

* emailsendnm = The "from" attribute you wish to append to the email. Default is "Niftsync Service".
* emailtoaddr = The email address the script should send email alerts to.
* alertsuberror = The "subject" attribute to be appened to email alerts if the script encounters an issue.
* alertsubrep = The "subject" attribute to be appened to email alerts if the script has been set to always email notify and no errors were encountered.
* remotesrv = The directory where data should be replicated to.
* localsrv = The directory where data should be replicated from.
* erroronly = If set to "false", the script will always send an email alert after running. If set to anything else, the script will only send an email alert when the script encounters an error.

By default the script will delete any logs that are older than 30 days that exist in the `logs` folder. This can be manipulated by changing the "`find logs/ -type f -name 'log*' -mtime +30 -exec rm {} +`" line.

# Running the Script

To run the script manually (first run, etc.) ensure that `sync.sh` is executable.

`chmod +x sync.sh`

Then it can be manually executed via `./sync.sh` (depending on the ammount of data and the connection speed between directories, this can take some time - it's generally a good idea to fork the process for this reason, eg. `./sync.sh &`). Naturally, the script can be automatically run by cron at set intervals, the `crontab` file contains a example wherein the script is run by cron every Sunday at 10AM.

Additional information regarding this utility can be found on my site at the link below:

[https://www.tech-jungle.com/automate-data-replication-with-html-email-alerts-using-niftsync](https://www.tech-jungle.com/automate-data-replication-with-html-email-alerts-using-niftsync)

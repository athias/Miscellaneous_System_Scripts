#!/bin/bash
################################################################################
#
# ./disk_health_check.sh
#
# Created by:	Matthew R. Sawyer
#
# Intended for use within crontab.  Performs a health check for all disks on the
# system that are smart control enabled.  The log is then mailed to root for
# review.
# Note:  It is highly recommended to configure your system to send root mail
#        to a centralized address for review.
# Note:  The LOG_DIR variable should be customized for your particular needs
#
################################################################################
# Establish Variables and perform basic checks
################################################################################

CUR_DATE=$(date +"%Y%m%d")
CUR_TIME=$(date +"%H.%M.%S")
CUR_HOST=`hostname -s`
ORIG_DIR=`pwd`
LOG_DIR=/storage/sysadmin/logs/disk_health_check
CUR_LOG=${LOG_DIR}/disk_health_check.${CUR_HOST}.${CUR_DATE}.log

################################################################################
# Function - End of Script cleanup
################################################################################

end_script ()
{
  sleep 1
  cd $ORIG_DIR
  exit
}

################################################################################
# Verify the script is being run by root
################################################################################

if [[ "$EUID" != "0" ]];then
  printf "\n\e[0;31mERROR:\e[0m\tThis script must be run as root!\n"
  end_script
fi

################################################################################
# Verify Logging directory and file
################################################################################

if [[ ! -d ${LOG_DIR} ]];then
  mkdir -p ${LOG_DIR}
  chown root:root ${LOG_DIR}
  chmod 750 ${LOG_DIR}
fi

if [[ -f ${CUR_LOG} ]];then
  mv ${CUR_LOG} ${CUR_LOG}.${CUR_TIME}
fi

touch ${CUR_LOG}
chown root:root ${CUR_LOG}
chmod 600 ${CUR_LOG}

################################################################################
# Perform the Disk Health Check
################################################################################

# Header
printf "################################\n" | tee -a ${CUR_LOG}
printf "# Daily Disk Health Status Log #\n" | tee -a ${CUR_LOG}
printf "################################\n\n" | tee -a ${CUR_LOG}
printf "Started at Date:\t${CUR_DATE}\n" | tee -a ${CUR_LOG}
printf "Started at Time:\t${CUR_TIME}\n\n" | tee -a ${CUR_LOG}

# Discover Disks
printf "##### Scanning for Disks #####\n" | tee -a ${CUR_LOG}
ALL_DISKS=`smartctl --scan | awk '{print $1}'`
printf "\n" | tee -a ${CUR_LOG}
sleep 2

# Check Disk Status
printf "##### Checking Health Status #####\n" | tee -a ${CUR_LOG}
printf "\n" | tee -a ${CUR_LOG}
printf "Device\t\tStatus\n" | tee -a ${CUR_LOG}
printf "######\t\t######\n" | tee -a ${CUR_LOG}

for CUR_DISK in ${ALL_DISKS};do
  printf "${CUR_DISK}\t" | tee -a ${CUR_LOG}
  smartctl -H ${CUR_DISK} | grep "SMART overall-health self-assessment test result:" | awk '{print $6}' | tee -a ${CUR_LOG}
done

sleep 2

# Close out log
printf "\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}
printf "# Finished - Review Log to Verify Status #\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}

# Mail Log to root
cat ${CUR_LOG} | tr -d \\r | mailx -s "disk health check - ${CUR_DATE}" root

################################################################################
# End of Script
################################################################################

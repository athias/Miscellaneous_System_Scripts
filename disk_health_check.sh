#!/bin/bash
################################################################################
#
# ./local_repo_update.sh
#
# Created by:	Matthew R. Sawyer
#
# Intended for use within crontab.  Performs a reposync between the connected
# repository and the local repository.  It will then create a repo based on the
# base and optional directories identified.
# NOTE:  It is highly recommended to configure your system to send root mail to
#        a centralized address for review.
# NOTE:  The LOG_DIR variable should be customized to your system
# NOTE:  The REPO_BASE_DIR variable should be customized to your system
#
################################################################################
# Establish Variables and perform basic checks
################################################################################

CUR_DATE=$(date +"%Y%m%d")
CUR_TIME=$(date +"%H.%M.%S")
CUR_HOST=`hostname -s`
ORIG_DIR=`pwd`
LOG_DIR=/storage/sysadmin/logs/local_repo_update
CUR_LOG=${LOG_DIR}/local_repo_update.${CUR_HOST}.${CUR_DATE}.log
REPO_BASE_DIR=/storage/sysadmin/Patches
RHEL_7_BASE_REPO=${REPO_BASE_DIR}/rhel-7-server-rpms/Packages/
RHEL_7_OPTIONAL_REPO=${REPO_BASE_DIR}/rhel-7-server-optional-rpms/Packages/

################################################################################
# Function - End of Script cleanup
################################################################################

end_script ()
{
  sleep 1
  cd ${ORIG_DIR}
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
# Check on Log
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
# Perform a Reposync
################################################################################

# Header
printf "###############################\n" | tee -a ${CUR_LOG}
printf "# Daily Repository Update Log #\n" | tee -a ${CUR_LOG}
printf "###############################\n\n" | tee -a ${CUR_LOG}
printf "Started at Date:\t${CUR_DATE}\n" | tee -a ${CUR_LOG}
printf "Started at Time:\t${CUR_TIME}\n\n" | tee -a ${CUR_LOG}

# Perform Repository Sync
printf "##### Starting reposync #####\n" | tee -a ${CUR_LOG}
reposync -n -r rhel-7-server-optional-rpms -r rhel-7-server-rpms -p ${REPO_BASE_DIR} | egrep -v 'ETA' | tee -a ${CUR_LOG}
sleep 2

# Create Repository for Base RPMs
printf "\n" | tee -a ${CUR_LOG}
printf "##### Creating Base RPM Repo #####\n" | tee -a ${CUR_LOG}
createrepo --update ${RHEL_7_BASE_REPO} | tee -a ${CUR_LOG}
sleep 2

# Create Repository for Optional RPMs
printf "\n" | tee -a ${CUR_LOG}
printf "##### Creating Base RPM Repo #####\n" | tee -a ${CUR_LOG}
createrepo --update ${RHEL_7_OPTIONAL_REPO} | tee -a ${CUR_LOG}
sleep 2

# Close out log
printf "\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}
printf "# Finished - Review Log to Verify Status #\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}

# Mail Log to root
cat ${CUR_LOG} | tr -d \\r | mailx -s "Local Repo Update Log - ${CUR_DATE}" root

# End Script
end_script

################################################################################
# End of Script
################################################################################

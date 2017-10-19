#!/bin/bash
################################################################################
#
# ./Daily_Repo_Update.sh
#
# Created by:	Matthew R. Sawyer
#
# Purpose:	Intended for use within crontab - Performs a daily reposync and
#		createrepo to ensure your personal patch directory is udpatated
#
################################################################################
# Establish Variables and perform basic checks
################################################################################

CUR_DATE=$(date +"%Y%m%d")
CUR_TIME=$(date +"%H.%M.%S")
ROOT_UID=0
LOG_DIR=/tmp
CUR_LOG=${LOG_DIR}/Daily_Repo_Update.log.${CUR_DATE}
REPO_BASE_DIR=/storage/sysadmin/Patches/
RHEL_7_BASE_REPO=/storage/sysadmin/Patches/rhel-7-server-rpms/Packages/
RHEL_7_OPTIONAL_REPO=/storage/sysadmin/Patches/rhel-7-server-optional-rpms/Packages/

################################################################################
# Verify the script is being run by root
################################################################################

if [[ "$UID" != "$ROOT_UID" ]]
then
	printf "\n\e[0;31mERROR\e[0m\tThis script must be run as root\n"
	end_script
fi

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
reposync -n -p ${REPO_BASE_DIR} | tee -a ${CUR_LOG}
sleep 5

# Create Repository for Base RPMs
printf "\n" | tee -a ${CUR_LOG}
printf "##### Creating Base RPM Repo #####\n" | tee -a ${CUR_LOG}
createrepo --update ${RHEL_7_BASE_REPO} | tee -a ${CUR_LOG}
sleep 5

# Create Repository for Optional RPMs
printf "\n" | tee -a ${CUR_LOG}
printf "##### Creating Base RPM Repo #####\n" | tee -a ${CUR_LOG}
createrepo --update ${RHEL_7_OPTIONAL_REPO} | tee -a ${CUR_LOG}
sleep 5

printf "\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}
printf "# Finished - Review Log to Verify Status #\n" | tee -a ${CUR_LOG}
printf "##########################################\n" | tee -a ${CUR_LOG}

################################################################################
# End of Script
################################################################################

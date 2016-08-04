#!/bin/bash
################################################################################
#
# ./fstab-cleanup
#
# Created by:	Matthew R. Sawyer
#
# Purpose:	This script will clean up the /etc/fstab.  It will provide basic
#		system information and modification date-stamp, and it will put
#		the fstab into a column format.
#
################################################################################
# Establish Variables and perform basic checks
################################################################################

CUR_DATE=$(date +"%Y%m%d")
CUR_TIME=$(date +"%H%M%S")
CUR_DATE_TIME=$(date +"%Y%m%d_%H%M%S")
CUR_HOST=`uname -n`
ROOT_UID=0
ORIG_DIR=`pwd`
FSTAB=/etc/fstab
TEMP_FSTAB=/tmp/fstab

cd /

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
	cd $ORIG_DIR
	exit
}

################################################################################
# Perfom /etc/fstab cleanup
################################################################################

# Back up previous /etc/fstab
if [[ -f ${FSTAB}.${CUR_DATE} ]];then
	printf "\n\e[0;33;40mNOTICE:\e[0m\tThis Script has been run already today; backing up /etc/fstab by date-time now.\n\n"
	printf "Backing up /etc/fstab now.\n"
	cp ${FSTAB} ${FSTAB}.${CUR_DATE_TIME}
	FSTAB_BAK=${FSTAB}.${CUR_DATE_TIME}
else
	printf "Backing up /etc/fstab now.\n"
	cp ${FSTAB} ${FSTAB}.${CUR_DATE}
	FSTAB_BAK=${FSTAB}.${CUR_DATE}
fi

# Create column format of /etc/fstab
printf "#Device Mountpoint FStype Options FSdump FSCK\n" > ${TEMP_FSTAB}

cat ${FSTAB} | egrep -v '^#|^$' >> ${TEMP_FSTAB}

# Tell them about generating the header
printf "Generating the new /etc/fstab header\n"
printf "\n"

# Generate the header
printf "#\n" > ${FSTAB}
printf "# /etc/fstab\n" >> ${FSTAB}
printf "#\n" >> ${FSTAB}
printf "# Hostname:\t${CUR_HOST}\n" >> ${FSTAB}
printf "# Generated on:\t${CUR_DATE} at ${CUR_TIME}\n" >> ${FSTAB}
printf "#\n" >> ${FSTAB}

# Tell them about formatting the fstab
printf "Formatting the remainder of the /etc/fstab\n"
printf "\n"

# Format the fstab
column -t ${TEMP_FSTAB} >> ${FSTAB}

# Show them the final product
printf "Finished product:\n\n"
cat ${FSTAB}

# Show them the restore method
printf "\n##########\n"
printf "If you are not satisfied you can restore it from the backup:\n"
printf "\tcp ${FSTAB_BAK} ${FSTAB}\n"
printf "\n"

# Remove temporary fstab
rm -f ${TEMP_FSTAB}

# Finish Script
end_script

################################################################################
# End of Script
################################################################################

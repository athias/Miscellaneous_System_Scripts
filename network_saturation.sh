#!/bin/bash
################################################################################
#
# ./network_saturation.sh
#
# Created by:   Matthew R. Sawyer
#
# A quick network saturation test that dumps blank packets directly onto a
# network device.
#
################################################################################
# Function - Set Variables
################################################################################

set_variables ()
{

CUR_DATE=$(date +"%Y%m%d")
CUR_TIME=$(date +"%H%M%S")
CUR_DATE_TIME=$(date +"%Y%m%d_%H%M%S")

}

################################################################################
# Function - Root UID check
################################################################################

# Root UID check
root_uid_check ()
{
  if [[ "$EUID" != "0" ]];then
    printf "\n\e[0;31mERROR:\e[0m\tThis script must be run as root\n" | tee -a ${CUR_LOG}
    end_script
  fi
}

################################################################################
# Function - Log Configuration
################################################################################

log_check ()
{

LOG_DIR=/root/logs
LOG_FILE=network_saturation.log
LOG_ARCHIVE=${LOG_DIR}/ARCHIVE
CUR_LOG=${LOG_DIR}/${LOG_FILE}

# Create the /root/logs directory if it doesn't exist
if [[ ! -d ${LOG_DIR} ]];then
  if [[ ! -d /root ]];then
    printf "\n\e[0;31mERROR:\e[0m\tYou have some serious issues if the \'/root\' directory doesn't exist\n\n"
    end_script
  fi
  mkdir ${LOG_DIR}
fi

# Archive any existing logs
if [[ -f ${LOG_DIR}/${LOG_FILE} ]];then
  # Create Archive Directory if it doesn't exist
  if [[ ! -d ${LOG_ARCHIVE} ]];then
    mkdir ${LOG_ARCHIVE}
  fi
  # Existing Archived logs check
  if [[ -f ${LOG_ARCHIVE}/${LOG_FILE}.${CUR_DATE} ]];then
    mv ${LOG_ARCHIVE}/${LOG_FILE}.${CUR_DATE} ${LOG_ARCHIVE}/${LOG_FILE}.${CUR_DATE}.${CUR_TIME}
    mv ${LOG_DIR}/${LOG_FILE} ${LOG_ARCHIVE}/${LOG_FILE}.${CUR_DATE}
  else
    mv ${LOG_DIR}/${LOG_FILE} ${LOG_ARCHIVE}/${LOG_FILE}.${CUR_DATE}
  fi
fi

}

################################################################################
# Function - End of script cleanup
################################################################################

end_script ()
{
  if [[ ${PID_FILE} ]];then
    rm -f ${PID_FILE}
  fi
  exit
}

################################################################################
# Function - PID file Creation and verification
################################################################################

pid_check ()
{

  PID_FILE=/var/run/network_saturation.pid

  if [[ -f ${PID_FILE} ]];then
    CUR_PID=$(cat ${PID_FILE})
    if [[ -z $(ps --no-headers -p ${CUR_PID}) ]];then
      printf "\n\e[0;33mNOTICE:\e[0m\tThe previous PID was not cleaned up properly - fixing this now...\n"
      rm -f ${PID_FILE}
    else
      printf "\e[0;31mERROR:\e[0m\tYou are attempting to run this script while another version is currently running\n"
      printf "\nDo you wish to stop the previous process and run this instead? [Y/N]? "
      # Response from User
      read yn
      if [[ $yn =~ [Yy][Ee][Ss]|[Yy] ]];then
        kill -hup ${CUR_PID} &>/dev/null
        if [[ $? != "0" ]];then
          kill -9 ${CUR_PID} &>/dev/null
        fi
      fi
    fi
  fi

  # Create the PID File
  touch ${PID_FILE}
  echo $$ > ${PID_FILE}

}

################################################################################
# Function - Gather Information
################################################################################

info_gather ()
{

printf "\n##### Network Saturation Test Variable Input #####\n\n"

while [[ ${IP_CHECK} != "1" ]];do
  printf "Please input the IP you want to send to: "
  read
  if [[ -n $(ipcalc -cs ${REPLY} && echo success) ]];then
    printf "\nThe IP you designated is \"${REPLY}\" - Is this correct? [y/n] "
    read yn
    if [[ $yn =~ [Yy][Ee][Ss]|[Yy] ]];then
      DEST_IP=${REPLY}
      IP_CHECK=1
      printf "\n"
    else
      printf "\n"
    fi
  else
    printf "\n\e[0;31mERROR:\e[0m\tThe IP address you chose is invalid, please try again\n"
  fi
done

while [[ ${ITER_CHECK} != "1" ]];do
  printf "Please input the number of seconds you want to run [1-1800]: "
  read
  if [[ ${REPLY} =~ ^[0-9]+$ ]];then
    if [[ ${REPLY} -le 1800 ]] && [[ ${REPLY} -ge 1 ]];then
      printf "\nYou choose to run this for ${REPLY} second - Is this correct? [y/n] "
      read yn
      if [[ $yn =~ [Yy][Ee][Ss]|[Yy] ]];then
        ITER_COUNT=${REPLY}
        ITER_CHECK=1
        printf "\n"
      else
        printf "\n"
      fi
    else
      printf "\n\e[0;31mERROR:\e[0m\tYou must select a valid number between 1 and 1800 - please try again\n"
    fi
  else 
    printf "\n\e[0;31mERROR:\e[0m\tYou must select a valid number between 1 and 1800 - please try again\n"
  fi
done

printf "List of interfaces to choose from:\n"
DEVICES=$(sar -n DEV 1 1 | egrep -v "IFACE|Average|^$|\(|\)" | awk '{print $3}')
for i in ${DEVICES}; do
  printf "\t${i}\n"
done
printf "\n"

while [[ ${DEV_CHECK} != "1" ]]; do
  printf "Please input the device you want to monitor: "
  read
  #while [[ ${DEV_MATCH} != "1" ]]; do
  for i in ${DEVICES}; do
    if [[ ${i} == ${REPLY} ]];then
      DEV_MATCH=1
    fi
  done
  if [[ ${DEV_MATCH} == "1" ]]; then
    DEV_CHECK=1
    DEV_MON=${REPLY}
  else
    printf "\n\e[0;31mERROR:\e[0m\tYou did not select a valid device to monitor - please try again\n"
  fi
done

}

################################################################################
# Main Script
################################################################################

set_variables
root_uid_check
pid_check
log_check
info_gather

printf "\n\n"

# Begin logging
printf "\e[0;35m##### Welcome to the network Saturation Test #####\e[0m\n\n" | tee -a ${CUR_LOG}
printf "Current Test Started on:\n" | tee -a ${CUR_LOG}
printf "\t${CUR_DATE} at ${CUR_TIME}\n\n" | tee -a ${CUR_LOG}
printf "Testing IP address is:\t${DEST_IP}\n" | tee -a ${CUR_LOG}
printf "No. of seconds to run:\t${ITER_COUNT}\n" | tee -a ${CUR_LOG}
printf "Monitoring interface:\t${DEV_MON}\n\n" | tee -a ${CUR_LOG}

# Run the port device dump and track PID
dd if=/dev/zero bs=32k > /dev/udp/${DEST_IP}/65432 &
DD_PID=$!
kill -STOP ${DD_PID}

printf "## The network saturation device dump is running under PID \e[0;34m${DD_PID}\e[0m\n" | tee -a ${CUR_LOG}
printf "Please record this in the event you need to manually kill the process\n\n" | tee -a ${CUR_LOG}
printf "## Press Any Key to begin Test ##\n" | tee -a ${CUR_LOG}
read -n 1 -s -r

printf "\n" | tee -a ${CUR_LOG}
sar -n DEV | grep IFACE | egrep -v "Average" | tee -a ${CUR_LOG}
kill -CONT ${DD_PID}
sleep 1

i=0
while [[ ${i} -le ${ITER_COUNT} ]];do
  sar -n DEV 1 1 | grep "${DEV_MON}" | grep Average | tee -a ${CUR_LOG}
  let i=$i+1
done

printf "\nTerminating device dump process...\n"
kill -HUP ${DD_PID} &>/dev/null
sleep 1

printf "\n\e[0;35m##### End of Network Saturation Test #####\e[0m\n" | tee -a ${CUR_LOG}
printf "\nThe log file can be reviewed at: ${CUR_LOG}\n" | tee -a ${CUR_LOG}

end_script

################################################################################
# End of Script
################################################################################

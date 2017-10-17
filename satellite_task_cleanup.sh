#!/bin/bash
################################################################################
#
# Satellite Task Cleanup
#   This script will clean up all 'stopped' and 'paused' tasks in an 'error'
#   state.  Prior to cleaning them up, a dump of the tasks will be stored in all
#   log directory for auditing purposes.  The option of viewing the current
#   status of tasks to be cleaned up is also available.
# 
# Created by:
#   Matthew R. Sawyer
#
################################################################################
# Root UID Check
################################################################################

if [[ "${EUID}" != "0" ]];then
  printf "\n\e[0;31mERROR:\e[0m\tYou must run this script as root\n\n"
  exit 1
fi

################################################################################
# Establish Variables
################################################################################

# General Purpose
CUR_DATE=$(date +"%Y%m%d") # YYYYMMDD
CUR_TIME=$(date +"%H%M%S") # HHMMSS
CUR_HOST=`uname -n`
ORIG_DIR=`pwd`

# Customizable Variables
BASE_DIR=/root/scripts
LOG_DIR=${BASE_DIR}/logs
LOG_ARCHIVE_DIR=${LOG_DIR}/ARCHIVE
ARCHIVE_TASKS_LOG=archived_tasks.${CUR_HOST}.${CUR_DATE}.log
CLEANUP_TASKS_LOG=cleanup_tasks.${CUR_HOST}.${CUR_DATE}.log
PID_WATCH_TIME=20

################################################################################
# Verify Directories and Logs
################################################################################

for CUR_DIR in {${BASE_DIR},${LOG_DIR},${SCRIPT_DIR},${LOG_ARCHIVE_DIR}};do
  if [[ ! -d ${CUR_DIR} ]];then
    mkdir -p ${CUR_DIR}
  fi
done

################################################################################
# pid_watch Function
################################################################################

pid_watch ()
{

# Verify a pid to watch has been provided
if [[ ! ${1} ]];then
  printf "\e[0;33mERROR:\e[0m\tThe pid_watch function must be called with \$\{1\}\n"
  exit 1
fi

# If a sleep amount has been provided, verify it is a valid number
if [[ ${2} ]];then
  PW_RE_NUM='^[0-9]+$'
  if [[ ${2} =~ ${PW_RE_NUM} ]];then
    PW_SLEEP_TIME=${2}
  else
    printf "\e[0;33mERROR:\e[0m\tThe \$\{2\}\ option must be a valid number\n"
    exit 1
  fi
else
  # Set Default time if one isn't specified
  PW_SLEEP_TIME=30
fi

# Monitor pid based on sleep timer and report status
PW_FIRST_RUN="yes"
while [[ -n $(ps -f h -p ${1}) ]];do
  if [[ ${PW_FIRST_RUN} == "yes" ]];then
    printf "\t\e[0;33mStarted monitoring Pid \e[0;36m${1} \e[0;33m- checking status in \e[0;36m${PW_SLEEP_TIME} \e[0;33mseconds...\e[0m\n"
    sleep ${PW_SLEEP_TIME}
    PW_FIRST_RUN="no"
  else
    printf "\t\e[0;33mPid \e[0;36m${1} \e[0;33mis still running, checking again in \e[0;36m${PW_SLEEP_TIME} \e[0;33mseconds...\e[0m\n"
    sleep ${PW_SLEEP_TIME}
  fi
done

# Report Success
printf "\t\e[0;33mPid \e[0;36m${1} \e[0;33mhas finished running!\e[0m\n"

}

################################################################################
# Satellite Cleanup Function
################################################################################

satellite_cleanup ()
{

# Header
printf "\n\e[0;34m####################################\e[0m" | tee -a ${CUR_LOG}
printf "\n\e[0;34m# Beginning Satellite Task Cleanup #\e[0m" | tee -a ${CUR_LOG}
printf "\n\e[0;34m####################################\e[0m\n\n" | tee -a ${CUR_LOG}

# Prepare Cleanup Log
if [[ -f ${LOG_DIR}/${CLEANUP_TASKS_LOG} ]];then
  /bin/mv ${LOG_DIR}/${CLEANUP_TASKS_LOG} ${LOG_ARCHIVE_DIR}/${CLEANUP_TASKS_LOG}.${CUR_TIME}
fi
  CUR_LOG=${LOG_DIR}/${CLEANUP_TASKS_LOG}

# Prepare Cleanup Log
if [[ -f ${LOG_DIR}/${ARVHICE_TASKS_LOG} ]];then
  /bin/mv ${LOG_DIR}/${ARCHIVE_TASKS_LOG} ${LOG_ARCHIVE_DIR}/${ARCHIVE_TASKS_LOG}.${CUR_TIME}
fi
  TASK_LOG=${LOG_DIR}/${ARCHIVE_TASKS_LOG}

# Stop Katello
printf "\e[0;34m##### Shutting Down Katello #####\e[0m\n\n" | tee -a ${CUR_LOG}
katello-service stop  | tee -a  ${CUR_LOG}
sleep 2

# Verify Postgres is Running
printf "\n\e[0;34m##### Verifying Postgres is Running #####\e[0m\n\n" | tee -a ${CUR_LOG}
if [[ -n `service postgresql status | grep "is running..."` ]];then
  printf "\e[0;32m\tPostgres is running\e[0m\n" | tee -a ${CUR_LOG}
else
  printf "\e[0;33m\tPostgres is not running, attempting to restart\e[0m\n" | tee -a ${CUR_LOG}
  sleep 2
  service postgresql start | tee -a ${CUR_LOG}
  sleep 2
  if [[ -n `service postgresql status | grep "is running..."` ]];then
    printf "\e[0;32m\tPostgres is running\e[0m\n" | tee -a ${CUR_LOG}
  else
    printf "\e[0;31m\tPostgres failed to restart correctly, please investigate\e[0m\n" | tee -a ${CUR_LOG}
    exit 1
  fi
fi

# Archive Tasks before removing them
printf "\n\e[0;34m##### Archiving error tasks #####\e[0m\n\n" | tee -a ${CUR_LOG}
printf "\e[0;33m\tPaused errors:\e[0m\t" | tee -a ${CUR_LOG}
sudo -u postgres -i psql -d foreman -c "select * from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'paused' and result = 'error');" >> ${TASK_LOG}
if [[ $? == "0" ]];then
  printf "\e[0;32mARCHIVED\e[0m\n" | tee -a ${CUR_LOG}
fi
sleep 1
printf "\e[0;33m\tStopped errors:\e[0m\t" | tee -a ${CUR_LOG}
sudo -u postgres -i psql -d foreman -c "select * from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'stopped' and result = 'error');" >> ${TASK_LOG}
if [[ $? == "0" ]];then
  printf "\e[0;32mARCHIVED\e[0m\n" | tee -a ${CUR_LOG}
fi
sleep 1

# Clear out error tasks
printf "\n\e[0;34m##### Removing Error Records from Database #####\e[0m\n\n" | tee -a ${CUR_LOG}
printf "\e[0;33m\tPaused errors:\e[0m\n" >> ${CUR_LOG}
sudo -u postgres -i psql -d foreman -c "delete from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'paused' and result = 'error');" >> ${CUR_LOG} 2>&1 & pid_watch $! ${PID_WATCH_TIME}
tail -3 ${CUR_LOG}
sleep 1
printf "\n\e[0;33m\tStopped errors:\e[0m\n" >> ${CUR_LOG}
sudo -u postgres -i psql -d foreman -c "delete from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'stopped' and result = 'error');" >> ${CUR_LOG} 2>&1 & pid_watch $! ${PID_WATCH_TIME}
tail -3 ${CUR_LOG}
sleep 1

# Restart Katello
printf "\n\e[0;34m##### Verifying Katello is Down #####\e[0m\n" | tee -a ${CUR_LOG}
printf "\n\e[0;33mNOTE:\e[0m\tServices may initially report \'\e[0;31mFAILED\e[0m\', verify the second occurrence reports \'\e[0;32mOK\e[0m\'\n\n" | tee -a ${CUR_LOG}
katello-service restart | tee -a ${CUR_LOG}
sleep 1

# foreman-rake clean_backend_objects
printf "\n\e[0;34m##### Cleaning database backend objects #####\e[0m\n" | tee -a ${CUR_LOG}
foreman-rake katello:clean_backend_objects --trace >> ${CUR_LOG} 2>&1 & pid_watch $! ${PID_WATCH_TIME}
cat ${CUR_LOG} | grep -A 99 "** Invoke katello:clean_backend_objects (first_time)"

# foreman-rake reindex
printf "\n\e[0;34m##### Performing database reindex #####\e[0m\n" | tee -a ${CUR_LOG}
foreman-rake katello:reindex --trace  >> ${CUR_LOG} 2>&1 & pid_watch $! ${PID_WATCH_TIME}
cat ${CUR_LOG} | grep -A 99 "** Invoke katello:reindex (first_time)"

# Finish
printf "\n\e[0;34m###################################\e[0m" | tee -a ${CUR_LOG}
printf "\n\e[0;34m# Satellite Task Cleanup Complete #\e[0m" | tee -a ${CUR_LOG}
printf "\n\e[0;34m###################################\e[0m\n" | tee -a ${CUR_LOG}

exit 0

}

################################################################################
# Satellite Status Function
################################################################################

satellite_status ()
{

# STATUS CHECK
printf "\e[0;34m##### Listing number of Error Records in Database #####\e[0m\n\n"
printf "\e[0;32m\t# Paused errors:\e[0m\n"
sudo -u postgres -i psql -d foreman -c "select count(*) from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'paused' and result = 'error');"
sleep 2
printf "\e[0;32m\t# Stopped errors:\e[0m\n"
sudo -u postgres -i psql -d foreman -c "select count(*) from foreman_tasks_tasks where id in (select id from foreman_tasks_tasks where state = 'stopped' and result = 'error');"

exit 0
}

################################################################################
# Display Usage Function
################################################################################

print_usage ()
{

printf "\n\e[0;36mWelcome to the Satellite Task Cleanup Script!\e[0m\n"

cat <<USAGE

Usage: ${0} [option]

    -h | --help      Prints this Usage Menu
    -c | --cleanup   Performs a cleanup of error tasks
    -s | --status    Checks status for current errors

USAGE

    #This will clear out those pesky failed tasks that
    #are causing strange errors and performace issues.

exit 0
}

################################################################################
# Main Script
################################################################################

case "${1}" in
  -h) print_usage
      ;;
  --help) print_usage
          ;;
  -s) satellite_status
      ;;
  --status) satellite_status
      ;;
  -c) satellite_cleanup
      ;;
  --cleanup) satellite_cleanup
      ;;
  *) print_usage
     ;;
esac

################################################################################
# End of script
################################################################################

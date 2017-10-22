# Miscellaneous System Scripts
A collection of miscellaneous scripts I've created over time to assist with routine tasks.  While I always attempt to make my scripts as universal as possible - these scripts tend to be the exception to the rule.  They will likely be more customized than others and may require significant modifications to adjust to your specific situation.

## List of Scripts
* fstab_cleanup.sh
  * Organizes the /etc/fstab into column format and adds a descriptive header for ease of use
  * This script will likely be moved into the RHEL_STIG_Baseline repository over time
* local_repo_update.sh
  * For those who maintain a local repository, and want to ensure it is updated regularly
  * Intended for a crontab - Performs a daily reposync then updates the repositories
  * NOTE: Only coded for base and optional RPM streams
* disk_health_check.sh
  * Intended for a crontab - Performs a health check of your disks and sends the log to root for review
  * NOTE: It is expected you have your root mail forwarded to a location you can review
* satellite_task_cleanup.sh
  * Specific for Red Hat Satellite Server
  * Cleans up tasks within the foreman database which helps with performance
* network_saturation.sh
  * Performs a UDP dump onto a specific port to artificially saturate a line
  * Designed to be used for testing purposes only
  
## Update History
* 20171022
  * Added scripts into readme
    * satellite_task_cleanup.sh was added previously and not mentioned
    * network_saturation.sh was added previously and not mentioned
  * Merged request to change backtick command calls into $() format
* 20161218
  * Recategorized this repository to my miscellaneous scripts collection
  * Updated this README to reflect repository recategorization
  * Updated disk_health_check.sh
    * Corrected mail issue (sending log as attachment) when configured to send to email
    * Added check for log directory
    * Other minor general script quality updates
  * Updated local_repo_update.sh
    * Corrected mail issue (sending log as attachment) when configured to send to email
    * Added check for log directory

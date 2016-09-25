# System_Build_Utilities
A Series of Scripts designed to help with System provisioning and rout

# List of Scripts
* fstab_cleanup.sh
  * Organizes the /etc/fstab into column format and adds a descriptive header for ease of use
* daily_repo_update.sh
  * Intended for a crontab - Performs a daily reposync then updates the repositories
  * NOTE: Only coded for base and optional RPM streams

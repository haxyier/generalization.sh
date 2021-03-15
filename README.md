# generalization.sh
## Description
**generalization.sh** is a command line tool which generalize (sysprep) system for CentOS 7, 8 and Stream 8. 
## Features
generalization.sh removes or regenerates following system-specific files and configurations.
- Log files (mainly in  ```/var/log/*```)
- Received emails
- cron configurations
- DHCP status files
- YUM cache files
- YUM UUID (Only CentOS 7)
- YUM transaction history (Optional)
- SSH host keys
- ```.ssh``` directories (contain authorized_keys and known_hosts)
- tmp files
- Firewall configurations
- Hostname
- NIC configurations (ex. static ip address, gateway, UUID, etc.)
- machine-id (>= CentOS 7.1)
- Command execution history (.bash_history)
## Usage
You can run this script from bash command line. This script needs root privileges. **You should use this script with ```source``` command** as shown below. It's because some features need to set environment variables for root.  
  
``` source generalization.sh ```

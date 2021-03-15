#! /bin/bash

###############################################
# generalization.sh
#
#
# Script to generalize Operating System for templating.
# This script needs root privileges.
# 
#
# Compatible with >=CentOS 7.1, =CentOS 8.x, =CentOS Stream 8
###############################################

### declare functions ###

function print_error ()
{
    script_filename=$(basename $0)
    echo "${script_filename} line ${1} : command exited with error code." 1>&2
}

# If target file exists, remove it. Otherwise, do nothing.
function rm_if_exists ()
{
    target_file=$1
    if ls ${target_file} > /dev/null 2>&1; then
        rm -rf ${target_file}
    fi
}


### Generalization process ###

# Confirmation of execution
echo "WARNING: This script removes user-specific files and configurations in your system."
echo "This action cannot be undone."
read -p "Are you sure you want to execute this script? (y/N):" input
case "$input" in
	[yY]) ;;
	* ) return 1; exit 1 ;;
esac


# Handle errors.
trap 'print_error $LINENO' ERR


# Detect OS Version.
OS_VERSION=$(cat /etc/redhat-release | sed -r "s/^.*release ([0-9]).*$/\1/")


#
# Remove unnecessary files.
#

# Remove log files.
echo "Removing log files..."

systemctl stop rsyslog
auditctl -e 0 > /dev/null
find /var/log -name "*-????????" -print0 | xargs -0 --no-run-if-empty rm
find /var/log -name "*.gz" -print0 | xargs -0 --no-run-if-empty rm
rm_if_exists "/var/log/dmesg.old"
rm_if_exists "/var/log/anaconda/*"
rm_if_exists "/var/crash/*"
find /var/log -type f -print0 | xargs -0 --no-run-if-empty truncate -s 0


# Remove received emails.
echo "Removing received emails..."

if [[ -e /usr/lib/systemd/system/postfix.service ]]; then
    systemctl stop postfix
fi

find /var/spool/mail -type f -print0 | xargs -0 --no-run-if-empty truncate -s 0


# Remove cron configurations.
echo "Removing cron configurations..."

rm_if_exists "/var/spool/cron/*"


# Remove DHCP status files.
echo "Removing DHCP status files..."

rm_if_exists "/var/lib/dhclient/*"


# Clean up YUM cache files.
echo "Cleaning up YUM cache files..."

yum clean all > /dev/null


#TODO: Enable working on CentOS 8.
# Remove YUM transaction history（optional）
#echo "Removing YUM transaction history..."

#rm_if_exists "/var/lib/yum/history/*"


# Remove SSH host keys.
echo "Removing SSH host keys..."

rm_if_exists "/etc/ssh/ssh_host_*_key*"


# Remove .ssh directories. (authorized_keys and known_hosts etc.)
echo "Removing SSH authorized keys and known hosts..."

rm_if_exists "/root/.ssh"
find /home -maxdepth 2 -mindepth 2 -name .ssh -type d | xargs --no-run-if-empty rm -r


# Remove tmp files.
echo "Removing tmp files..."

rm_if_exists "/tmp/*"
rm_if_exists "/var/tmp/*"


# Remove Kickstart configuration file.
echo "Removing Kickstart configuration file..."

rm_if_exists "/root/anaconda-ks.cfg"


#
# Regenerate system-specific ID
#

# Regenerate UUID (filesystems)
# cannot change UUID of mounted filesystems.
#xfs_admin -U `uuidgen` <disk-name>


# Regenerate UUID (LVM PV and VG)
# cannot change UUID of mounted volumes.
#pvchange -au
#vgchange -u <vg-name>


# Regenerate yum-uuid (exists only CentOS 7).
echo "Removing uuid using for YUM..."

rm_if_exists "/var/lib/yum/uuid"


#
# Remove system-specific network configurations.
#

# Remove system-specific firewall configurations.
echo "Removing user-specific firewall rules..."

truncate -cs 0 "/etc/sysconfig/iptables"
rm_if_exists "/etc/sysconfig/iptables.save"
rm_if_exists "/etc/firewalld/services/*"
rm_if_exists "/etc/firewalld/zones/*"


# Restore hostname to default.
echo "Restoring default hostname..."

hostnamectl set-hostname localhost.localdomain


# Remove user-specific NIC configurations.
echo "Removing user-specific NIC configurations..."

sed -i '/^BOOTPROTO/c\BOOTPROTO="dhcp"' /etc/sysconfig/network-scripts/ifcfg-*
find /etc/sysconfig/network-scripts -name "ifcfg-*" -not -name "ifcfg-lo" -print0 | xargs -0 --no-run-if-empty sed -i '/^\(HWADDR\|UUID\|HOSTNAME\|DHCP_HOSTNAME\|IPADDR\|PREFIX\|NETMASK\|GATEWAY\|DNS\)/d'
rm_if_exists "/etc/sysconfig/network-scripts/ifcfg-*.bak"


# Regenerate machine-id (>= CentOS 7.1)
echo "Regenerating machine id..."

rm_if_exists "/etc/machine-id"
systemd-machine-id-setup > /dev/null


# remove all user's command execution history.
echo "Removing command execution history..."

rm_if_exists "/root/.bash_history"
find /home -maxdepth 2 -mindepth 2 -name .bash_history | xargs --no-run-if-empty rm
export HISTSIZE=0



echo -e "\nGeneralization complete!"

# Confirmation of shutdown
echo "Shutdown is required to finish generalizing Operating System."

read -p "Shutdown now? (y/N):" input
case "$input" in [yY]) shutdown now ;; esac

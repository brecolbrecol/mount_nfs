#!/bin/bash
#
## Config file required, which must define:
# - REMOTE_NFS_IP
# - REMOTE_NFS_MAC
# - LOCAL_MOUNTPOINT
##

DIR="$(dirname $(readlink -f $0))"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
NOK="${RED}✖${NC}"
OK="${GREEN}✔${NC}"


function load_config {
	if [[ ! -z $WAM_CONFIG ]]
	then
		. $WAM_CONFIG	
	elif [[ -e "${DIR}/config" ]]
	then
		. "${DIR}/config"
	else
		echo "Config required! Please, define ${DIR}/config"
		return 1
	fi

	if [[ -z ${REMOTE_NFS_IP} || -z ${REMOTE_NFS_MAC} || -z ${LOCAL_MOUNTPOINT} ]]
	then
		echo -e "Invalid config file, please fix it. Must define:\n"
		echo -e "REMOTE_NFS_IP=\"192.168.0.XXX\"\nREMOTE_NFS_MAC=\"ff:ff:ff:ff:ff:ff\"\nLOCAL_MOUNTPOINT=\"./data\""
		return 2
	fi

	if [[ -z ${REMOTE_MOUNTPOINT} ]]
	then
		REMOTE_MOUNTPOINT="${LOCAL_MOUNTPOINT}"
	fi

	if [[ -z ${REMOTE_USER} ]]
	then
		REMOTE_USER="$(whoami)"
	fi

	DEV="$(ip route get ${REMOTE_NFS_IP} |grep dev |awk -F'dev ' '{print $2}' |awk '{print $1}')"

	return 0
}


function clear_line {
	echo -en "\r                                                                    "
}

function wol {
	echo -en "Sending magic packet...\t\t"
	sudo etherwake -D -b -i "${DEV}" "${REMOTE_NFS_MAC}" > /dev/null 2>&1 && echo -e "${OK}" || echo -e "${NOK}"
}

function is_server_alive {
	ping -c 1 $1 >/dev/null 2>&1
}

function wait_server_alive {
	echo -en "Waiting for ${REMOTE_NFS_IP}...\t"
	while ! is_server_alive ${REMOTE_NFS_IP}
	do
		echo -en "${NOK}"
		sleep 1
		clear_line
		echo -en "\rWaiting for ${REMOTE_NFS_IP}...\t"
	done
	echo -e "${OK}"
}

function mount_remote_nfs {
	mkdir -p "${LOCAL_MOUNTPOINT}" > /dev/null 2>&1 # ensure local mountpoint exists
	echo -en "Mounting ${LOCAL_MOUNTPOINT}...\t\t"
	sudo mount -t nfs ${REMOTE_NFS_IP}:${REMOTE_MOUNTPOINT} ${LOCAL_MOUNTPOINT} && echo -e "${OK}" || echo -e "${NOK}"
}


function wait_server_down {
	ssh ${REMOTE_USER}@${REMOTE_NFS_IP} sudo poweroff > /dev/null 2>&1
	echo -en "Waiting for ${REMOTE_NFS_IP}...\t"
	while is_server_alive ${REMOTE_NFS_IP}
	do
		echo -en ${NOK}
		sleep 1
		clear_line
		echo -en "\rWaiting for ${REMOTE_NFS_IP}...\t"
	done
	echo -e ${OK}
}

function umount_remote_nfs {
	echo -en "Unmounting ${LOCAL_MOUNTPOINT}...\t\t"
	sudo umount ${LOCAL_MOUNTPOINT} >/dev/null 2>&1 && echo -e $OK || echo -e $NOK
}

load_config || exit

if [[ -z ${1} || "${1}" == "status" ]]
then
	mount |grep ${LOCAL_MOUNTPOINT} > /dev/null && status="${GREEN}" || status="${RED}not "
	echo -e "${LOCAL_MOUNTPOINT} is ${status}mounted${NC}"
elif [[ "${1}" == "mount" ]]
then
	wol
	wait_server_alive
	mount_remote_nfs
elif [[ "${1}" == "umount" ]]
then
	umount_remote_nfs
	wait_server_down
elif [[ "${1}" == "help" || "${1}" == "--help" ]]
then
	echo "Use: $0 [mount|umount|status|help]"
fi


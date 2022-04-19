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
	mount ${LOCAL_MOUNTPOINT} && echo -e "${OK}" || echo -e "${NOK}"
}

load_config || exit
wol
wait_server_alive
mount_remote_nfs


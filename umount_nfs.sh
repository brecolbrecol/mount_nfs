#!/bin/bash
DIR="$(dirname $(readlink -f $0))"
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
NOK="${RED}✖${NC}"
OK="${GREEN}✔${NC}"
## Config file, which defines:
# - REMOTE_NFS_IP
# - REMOTE_NFS_MAC
. ${DIR}/config
DEV="$(ip route get ${REMOTE_NFS_IP} |grep dev |awk -F'dev ' '{print $2}' |awk '{print $1}')"

function clear_line {
	echo -en "\r                                                                    "
}

function is_server_alive {
	ping -c 1 $1 >/dev/null 2>&1
}

function wait_server_down {
	ssh ${REMOTE_NFS_IP} sudo poweroff > /dev/null 2>&1
	echo -en "Waiting for $REMOTE_NFS_IP...\t"
	while is_server_alive $REMOTE_NFS_IP
	do
		echo -en $NOK
		sleep 1
		clear_line
		echo -en "\rWaiting for ${REMOTE_NFS_IP}...\t"
	done
	echo -e $OK
}

function umount_remote_nfs {
	echo -en "Unmounting $LOCAL_MOUNTPOINT...\t\t"
	umount $LOCAL_MOUNTPOINT && echo -e $OK || echo -e $NOK
}

umount_remote_nfs
wait_server_down


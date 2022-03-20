#!/bin/bash

## Config file, which defines:
# - REMOTE_NFS_IP
# - REMOTE_NFS_MAC
. config
DEV="$(ip route get ${REMOTE_NFS_IP} |grep dev |awk -F'dev ' '{print $2}' |awk '{print $1}')"

function clear_line {
	echo -en "\r                                                                    "
}

function wol {
	echo -en "Sending magic packet...\t\t"
	sudo etherwake -D -b -i ${DEV} ${REMOTE_NFS_MAC} > /dev/null 2>&1 && echo "✔" || echo "✖"
}

function is_server_alive {
	ping -c 1 $1 >/dev/null 2>&1
}

function wait_server_alive {
	echo -en "Waiting for $REMOTE_NFS_IP...\t"
	while ! is_server_alive $REMOTE_NFS_IP
	do
		echo -en "✖"
		sleep 1
		clear_line
		echo -en "\rWaiting for ${REMOTE_NFS_IP}...\t"
	done
	echo -e "✔"
}

function mount_remote_nfs {
	mount $LOCAL_MOUNTPOINT
}

wol
wait_server_alive
mount_remote_nfs


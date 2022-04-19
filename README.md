# Wake And Mount NAS
Script for WOL and mounting remote NFS server

## Requirements
```
apt-get install etherwake
```

## Use

1. Define your user-case variables inside ./config file *¹*
1. Launch script: `./wam_nas.sh`

*¹* alternately, you can also define environment variable `WAM_CONFIG`, i.e: `WAM_CONFIG=file_name ./wam_nash.sh`

## Security notes
Script launchs `etherwake`, `mount` and `umount` with sudo; you can (and definetly may want to) tune it.

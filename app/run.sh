#!/usr/bin/env sh

# Based on https://cloud.google.com/run/docs/tutorials/network-filesystems-filestore#defining_your_processes_in_the_startup_script
set -eo pipefail

# Create mount directory for service.
mkdir -p /mnt/nfs/filestore

echo "Mounting Cloud Filestore."
mount --verbose -t nfs -o nolock $FILESTORE_IP_ADDRESS:/$FILESTORE_FILESHARE_NAME /mnt/nfs/filestore

echo "Mounting completed."

ocis init || true
ocis server

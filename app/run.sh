#!/usr/bin/env bash
set -eo pipefail

# Create mount directory for service.
mkdir -p $MNT_DIR

echo "Mounting Cloud Filestore."
mount -o nolock $FILESTORE_IP_ADDRESS:/$FILE_SHARE_NAME $MNT_DIR
echo "Mounting completed."

ocis init || true
ocis server

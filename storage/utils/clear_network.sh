#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

REMOVE_NETWORK=false
for arg in "$@"; do
    if [ "$arg" == "--network" ]; then
        REMOVE_NETWORK=true
        break
    fi
done

# Move to root folder
ROOTPATH="$(realpath "$(dirname "$0")")"
while [ "$ROOTPATH" != "/" ] && [ ! -f "$ROOTPATH/.env" ]; do ROOTPATH="$(dirname "$ROOTPATH")"; done
[ "$ROOTPATH" = "/" ] && { echo "ROOTPATH is root directory. Exiting."; exit 1; }
cd "$ROOTPATH"

# Import environment variables
[ -f "$ROOTPATH/.env" ] && { echo "Loading environment variables from .env"; . "$ROOTPATH/.env"; }

# Stop and remove all Docker containers whose names start with "ipfs_"
echo "Stopping and removing Docker containers..."
for container in $(sudo docker ps -a --filter "name=^ipfs_" --format "{{.Names}}"); do
    sudo docker stop "$container"
    sudo docker rm "$container"
done

# Remove Docker network if flag is set
if [ "$REMOVE_NETWORK" = true ]; then
    if [ -n "$(sudo docker network ls --filter name="$IPFS_NETWORK_NAME" --format "{{.Name}}")" ]; then
        echo "Removing Docker network $IPFS_NETWORK_NAME..."
        sudo docker network rm "$IPFS_NETWORK_NAME"
    fi
else
    echo "Network removal skipped. Use --network flag to remove it."
fi

# Remove the storage nodes directory and contents
if [ -d "$STORAGE_NODES" ]; then
    echo "Removing storage nodes directory..."
    rm -rf "$STORAGE_NODES"
fi

# Remove swarm key
if [ -f "$STORAGE_CONFIGS/swarm.key" ]; then
    echo "Removing swarm key..."
    rm -f "$STORAGE_CONFIGS/swarm.key"
fi

echo "Cleanup completed."
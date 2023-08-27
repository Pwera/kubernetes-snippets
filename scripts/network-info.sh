#!/bin/bash

# Get a list of all container IDs using crictl
CONTAINER_IDS=$(sudo crictl ps -q)

if [ -z "$CONTAINER_IDS" ]; then
    echo "No containers found."
else
    echo "Container details:"
    for CONTAINER_ID in $CONTAINER_IDS; do
        CONTAINER_INFO=$(sudo crictl inspect "$CONTAINER_ID")
        CONTAINER_NAME=$(echo "$CONTAINER_INFO" | jq -r '.status.labels."io.kubernetes.pod.name"')
        CONTAINER_PID=$(echo "$CONTAINER_INFO" | jq -r '.info.pid')
        CONTAINER_NETNS=$(echo "$CONTAINER_INFO" | jq -r '.info.runtimeSpec.linux.namespaces[] | select(.type == "network") | .path')

        if [ -z "$CONTAINER_NAME" ]; then
            echo "Variable CONTAINER_NAME is not set or is empty."
            continue
        fi
        NETNS=$(sudo ip netns identify "$CONTAINER_PID")
        if [ -z "$CONTAINER_NETNS" ]; then
            echo "Variable CONTAINER_NETNS is not set or is empty for $CONTAINER_NAME."
            continue
        fi
        id=$(sudo nsenter --net=$CONTAINER_NETNS ethtool -S eth0 | grep -i peer)
        echo $id
        id=$(echo "$id" | grep -oP 'peer_ifindex: \K\d+')
        echo $id
        VETH_NAME=$(ip -o link show | awk -F': ' '{print $2}' | sed -n "${id}p")

        echo "Container Name: $CONTAINER_NAME"
        echo "Container ID: $CONTAINER_ID"
        echo "Container PID: $CONTAINER_PID"
        echo "Container netns: $CONTAINER_NETNS"
        echo "Container netns: $NETNS"
        echo "Container veth: $VETH_NAME"
        echo "----------------------------------"
    done
fi


#!/bin/bash

CONTAINER_NAME="chatroom-application"
IMAGE_NAME="vootlasaicharan/chatroom-application:${BUILD_NUMBER}"

# Stop and remove existing container if it exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME" && docker rmi $(docker images -q)
    echo "Container stopped and removed."
fi

# Run the new container
sudo docker run -itd --name "$CONTAINER_NAME" -p 8080:8080 "$IMAGE_NAME"

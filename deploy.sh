#!/bin/bash

CONTAINER_NAME="chatroom-application"
IMAGE_NAME="vootlasaicharan/chatroom-application:latest"

# Stop and remove existing container if it exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" && docker rm "$CONTAINER_NAME" && docker rmi "$IMAGE_NAME"
    echo "Container stopped and removed."
fi

# Pull and run the new container
docker pull $IMAGE_NAME
docker run -d --name $CONTAINER_NAME -p 8080:8080 $IMAGE_NAME

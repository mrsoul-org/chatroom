#!/bin/bash

set -e  # Exit immediately on failure

CONTAINER_NAME="chatroom-application"
IMAGE_NAME="vootlasaicharan/chatroom-application:latest"

echo "🚀 Starting deployment..."

# Stop and remove existing container if it exists
if docker ps -a | grep -q "$CONTAINER_NAME"; then
    echo "🛑 Stopping and removing existing container..."
    docker stop "$CONTAINER_NAME" || echo "Container not running."
    docker rm "$CONTAINER_NAME" || echo "Container already removed."
fi

# Clean up old images
echo "🧹 Cleaning up old Docker images..."
docker image prune -af || true

# Run the new container
echo "▶️ Starting new container..."
docker run -d --name "$CONTAINER_NAME" -p 8080:8080 "$IMAGE_NAME"

# Verify container is running
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo "✅ Deployment successful. Container is running."
    exit 0
else
    echo "❌ Deployment failed. Container is not running."
    exit 1
fi
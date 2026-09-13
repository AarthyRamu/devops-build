#!/bin/bash
set -e

CONTAINER_NAME="react-app"

echo "Stopping old container if running..."
docker rm -f $CONTAINER_NAME || true

echo "Pulling latest image..."
docker pull aarthyramu/devops-build:dev

echo "Starting new container..."
docker run -d --name $CONTAINER_NAME -p 80:80 aarthyramu/devops-build:dev

echo "Deployment completed successfully!"

#!/bin/bash
set -e

# Variables
IMAGE_NAME="aarthyramu/devops-build"
TAG="dev"

echo "Building Docker image..."
docker build -t $IMAGE_NAME:$TAG .

echo "Pushing image to DockerHub..."
docker push $IMAGE_NAME:$TAG

echo "Build and push completed successfully!"

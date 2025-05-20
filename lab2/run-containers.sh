#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <number_of_containers> <image_name>"
  exit 1
fi

if [ -z "$2" ]; then
  echo "Usage: $0 <number_of_containers> <image_name>"
  exit 1
fi

COUNT=$1
IMAGE_NAME=$2

if ! [[ "$COUNT" =~ ^[0-9]+$ ]]; then
  echo "Error: First argument must be a positive integer."
  exit 1
fi

docker volume inspect shared_volume > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "Creating shared_volume..."
  docker volume create shared_volume
fi

echo "Cleaning up old containers..."
docker rm -f $(docker ps -aq --filter "name=worker") > /dev/null 2>&1 || true

echo "Starting $COUNT containers using image '$IMAGE_NAME'..."

for i in $(seq 1 $COUNT); do
  docker run -d --name worker$i -v shared_volume:/shared $IMAGE_NAME
done

echo "$COUNT containers are running using image '$IMAGE_NAME'."

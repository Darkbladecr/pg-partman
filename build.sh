#!/bin/sh

VER=16
TAG=$VER-alpine

PUSH_FLAG=false

# Check if the flag --push is present in the arguments
while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
        -p|--push)
            PUSH_FLAG=true
            shift
            ;;
        *)
            # Unknown option
            shift
            ;;
    esac
done

if [ "$PUSH_FLAG" = true ]; then
  docker buildx build --platform linux/arm64,linux/amd64 \
    --builder=container \
    -t darkbladecr/postgres-pg_partman:$TAG \
    --push \
    .
fi

docker buildx build --platform linux/arm64 \
 --builder=container \
 --load \
 -t postgres-pg_partman:$TAG \
 -t darkbladecr/postgres-pg_partman:$TAG \
 .
#!/bin/bash

set -e
docker-compose build

set +e
docker-compose rm -fs
set -e

docker-compose up -d
docker-compose logs -f

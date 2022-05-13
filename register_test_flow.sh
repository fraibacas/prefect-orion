#!/bin/bash
set -e

docker-compose exec prefect-server /bin/bash -c 'prefect deployment create /flows/test.py'

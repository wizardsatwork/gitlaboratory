#!/bin/bash

source ./ENV.sh

function stop() {
  echo "stopping ${CONTAINER_NAME}"
  docker stop ${CONTAINER_NAME} \
  && echo "stopped ${CONTAINER_NAME}" \
  || echo "container ${CONTAINER_NAME} not started"
}

function rm() {
  echo "delete ${CONTAINER_NAME}"
  docker rm -f ${CONTAINER_NAME} && echo "removed container" || echo "container does not exist"
}

function build() {
  echo "building: ${CONTAINER_NAME}"

  docker build \
    -t ${CONTAINER_NAME} \
    --build-arg="USER=${USER}" \
    --build-arg="GROUP=${GROUP}" \
    --build-arg="WORKDIR=${WORKDIR}" \
    --build-arg="VERSION=${VERSION}" \
    --build-arg="MD5=${MD5}" \
    --build-arg="PORT=${CONTAINER_PORT}" \
    . # dot!

  echo "build finished"
}

function run() {
  rm

  echo "run ${CONTAINER_NAME}"

  docker run \
    --name ${CONTAINER_NAME} \
    --detach \
    --link=magic-postgres:postgresql \
    --publish=10083:80 \
    --volume=data:/home/redmine/data \
    ${CONTAINER_NAME}

  echo "started docker container"
}

function logs() {
  echo "connecting to docker logs"
  docker logs ${CONTAINER_NAME}
}

function help() {
  echo "Usage:"
  echo ""
  echo './cli.sh $command'
  echo ""
  echo "commands:"
  echo "run - run docker container"
  echo "rm - remove container"
  echo "build - build container"
  echo "stop - stop container"
}

if [ $1 ]
then
  function=$1
  shift
  $function $@
else
  help $@
fi

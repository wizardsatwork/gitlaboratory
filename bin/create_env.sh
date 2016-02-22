#!/bin/bash

echo "Start env generation"

GENERATED_CWD="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )/.."

GENERATED_POSTGRES_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
GENERATED_REDIS_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
GENERATED_GITLAB_DB_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
GENERATED_REDMINE_DB_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
GENERATED_MONGO_DB_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
GENERATED_ROCKETCHAT_DB_PASS="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
SECRET_KEY_BASE="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"

if [ -f "./GITLAB_SECRETS_DB_KEY_BASE" ]; then
  GITLAB_SECRETS_DB_KEY_BASE=$(cat ./GITLAB_SECRETS_DB_KEY_BASE)
else
  GITLAB_SECRETS_DB_KEY_BASE="$(base64 /dev/urandom | tr -dC '[:graph:]'  | stdbuf -o0 head --bytes 55)"
  echo $GITLAB_SECRETS_DB_KEY_BASE >> ./GITLAB_SECRETS_DB_KEY_BASE
fi

POSTGRES_FILE=$GENERATED_CWD/postgres/ENV.sh
REDIS_FILE=$GENERATED_CWD/redis/ENV.sh
OPENRESTY_FILE=$GENERATED_CWD/openresty/ENV.sh
GITLAB_FILE=$GENERATED_CWD/gitlab/ENV.sh
REDMINE_FILE=$GENERATED_CWD/redmine/ENV.sh
REDMINE_CONFIG_DIR=$GENERATED_CWD/redmine/config
REDMINE_DB_CONFIG_FILE=$REDMINE_CONFIG_DIR/database.yml
REDMINE_SECRET_CONFIG_FILE=$REDMINE_CONFIG_DIR/secret.yml
REDMINE_RAILS_ENV=production

MONGODB_FILE=$GENERATED_CWD/mongodb/ENV.sh
ROCKETCHAT_FILE=$GENERATED_CWD/rocketchat/ENV.sh

POSTGRES_USER_NAME=postgres
POSTGRES_DATABASE=postgres
POSTGRES_PORT=5432

GITLAB_DB_USER=gitlab
GITLAB_DB_PASS=$GENERATED_GITLAB_DB_PASS
GITLAB_DB_NAME=gitlabhq_production

REDMINE_DB_USER=redmine
REDMINE_DB_PASS=$GENERATED_REDMINE_DB_PASS
REDMINE_DB_NAME=redmine_production

ROCKETCHAT_DB_USER=rocketchat
ROCKETCHAT_DB_DATABASE=rocketchat
ROCKETCHAT_DB_PASS=$GENERATED_ROCKETCHAT_DB_PASS

GITLAB_HOST_PORT=8888
REDMINE_HOST_PORT=8889
ROCKETCHAT_HOST_PORT=8890

echo "\
#!/bin/bash

# autogenerated postgres pass
export SU_PASS=$GENERATED_POSTGRES_PASS

# postgres user settings
export SU_USER=$POSTGRES_USER_NAME

# postgres management database, service will create their own databases
export DB=$POSTGRES_DATABASE

# postgres host settings
export HOST_PORT=$POSTGRES_PORT

# postgres container settings
export CONTAINER_NAME=magic-postgres

# this is the internal port of the container
export CONTAINER_PORT=5432

# postgres language and encoding
export LANG=en_US.utf8

# the directory the postgres data will be stored in
export PGDATA=/home/data/postgresql

export GITLAB_DB_USER=$GITLAB_DB_USER
export GITLAB_DB_PASS=$GITLAB_DB_PASS
export GITLAB_DB_NAME=$GITLAB_DB_NAME

export REDMINE_DB_USER=$REDMINE_DB_USER
export REDMINE_DB_PASS=$REDMINE_DB_PASS
export REDMINE_DB_NAME=$REDMINE_DB_NAME
export REDMINE_DB_PORT=$POSTGRES_PORT
" > $POSTGRES_FILE
echo "wrote $POSTGRES_FILE"

echo "\
#!/bin/bash

export CONTAINER_NAME=magic-redis

export USER_NAME=wnwredis
export USER_ID=23523
export DIR=/home/redis

export CONTAINER_PORT=6379
export HOST_PORT=6379

# autogenerated redis password
export PASS=$GENERATED_REDIS_PASS
" > $REDIS_FILE
echo "wrote $REDIS_FILE"

OUT_DIR="./out"
SRC_DIR="./src"

echo "\
#!/bin/bash
export CONTAINER_NAME=magic-resty
export CONTAINER_PORT_80=8080
export HOST_PORT_80=80
export CONTAINER_PORT_443=443
export HOST_PORT_443=4343

export OUT_DIR=$OUT_DIR
export SRC_DIR=$SRC_DIR

export EXPORT_PATH=/usr/local/openresty/nginx/sbin
export VERSION=1.9.7.1
export TARGET_DIR=/home/openresty/
export LUA_SRC_DIR=$SRC_DIR/lua
export HOST_SRC_DIR=$LUA_SRC_DIR/hosts
export SBIN=/usr/local/openresty/nginx/sbin
" > $OPENRESTY_FILE
echo "wrote $OPENRESTY_FILE"

echo "\
#!/bin/bash

export CONTAINER_NAME=magic-gitlab
export HOSTNAME=gitlab.wiznwit.com

export CONTAINER_PORT_80=80
export CONTAINER_PORT_443=443
export CONTAINER_PORT_22=22

export HOST_PORT_80=$GITLAB_HOST_PORT
export HOST_PORT_443=443
export HOST_PORT_22=22

export GITLAB_DB_USER=$GITLAB_DB_USER
export GITLAB_DB_PASS=$GITLAB_DB_PASS
export GITLAB_DB_NAME=$GITLAB_DB_NAME

export GITLAB_SECRETS_DB_KEY_BASE=$GITLAB_SECRETS_DB_KEY_BASE

$(cat ./GITLAB_GITHUB_KEYS)
" > $GITLAB_FILE
echo "wrote $GITLAB_FILE"

echo "\
#!/bin/bash

export CONTAINER_NAME=magic-redmine
export HOSTNAME=redmine.wiznwit.com

export SECRET_KEY_BASE=$SECRET_KEY_BASE

export POSTGRES_CONTAINER_NAME=magic-postgres

export USER=redmine
export GROUP=redmine
export WORKDIR=/usr/src/redmine

export HOST_PORT_80=$REDMINE_HOST_PORT
export CONTAINER_PORT_80=3000

export REDMINE_DB_USER=$REDMINE_DB_USER
export REDMINE_DB_PASS=$REDMINE_DB_PASS
export REDMINE_DB_NAME=$REDMINE_DB_NAME
" > $REDMINE_FILE
echo "wrote $REDMINE_FILE"


echo "\
#!/bin/bash

export CONTAINER_NAME=magic-mongodb

export CONTAINER_PORT_27017=27017
export HOST_PORT_27017=27017
export CONTAINER_PORT_28017=28017
export HOST_PORT_28017=28017

export ROCKETCHAT_DB_USER=$ROCKETCHAT_DB_USER
export ROCKETCHAT_DB_NAME=$ROCKETCHAT_DB_DATABASE
export ROCKETCHAT_DB_PASS=$ROCKETCHAT_DB_PASS
" > $MONGODB_FILE
echo "wrote $MONGODB_FILE"

echo "\
#!/bin/bash

export CONTAINER_NAME=magic-rocketchat
export HOSTNAME=rocket.wiznwit.com


export CONTAINER_PORT_3000=3000
export HOST_PORT_3000=ROCKETCHAT_HOST_PORT

export ROCKETCHAT_DB_USER=$ROCKETCHAT_DB_USER
export ROCKETCHAT_DB_USER=$ROCKETCHAT_DB_PASS
export ROCKETCHAT_DB_NAME=$ROCKETCHAT_DB_NAME
" > $ROCKETCHAT_FILE
echo "wrote $ROCKETCHAT_FILE"


echo "finished env generation"

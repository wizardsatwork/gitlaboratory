#!/bin/bash
set -e

source /ENV.sh

case "$1" in
  rails|rake|passenger)
    if [ "$POSTGRES_PORT" ]; then
      adapter='postgresql'
      host='postgres'
      port="${POSTGRES_PORT:-5432}"
      username="${POSTGRES_USER:-postgres}"
      password="${POSTGRES_PASS}"
      database="${POSTGRES_DB:-$username}"
      encoding=utf8
    else
      echo >&2 'warning: missing POSTGRES_PORT environment variables'
      echo >&2 '  Did you forget to --link some_mysql_container:mysql or some-postgres:postgres?'
      echo >&2
      echo >&2 '*** Using sqlite3 as fallback. ***'

      adapter='sqlite3'
      host='localhost'
      username='redmine'
      database='sqlite/redmine.db'
      encoding=utf8

      mkdir -p "$(dirname "$database")"
      chown -R ${REDMINE_USER}:${REDMINE_GROUP} "$(dirname "$database")"
    fi

    # ensure the right database adapter is active in the Gemfile.lock
    bundle install --without development test

    if [ ! -s config/secrets.yml ]; then
      if [ "$REDMINE_SECRET_KEY_BASE" ]; then
        cat > 'config/secrets.yml' <<-YML
          $RAILS_ENV:
            secret_key_base: "$REDMINE_SECRET_KEY_BASE"
        YML
      elif [ ! -f /usr/src/redmine/config/initializers/secret_token.rb ]; then
        rake generate_secret_token
      fi
    fi
    if [ "$1" != 'rake' -a -z "$REDMINE_NO_DB_MIGRATE" ]; then
      gosu redmine rake db:migrate
    fi

    chown -R ${REDMINE_USER}:${REDMINE_GROUP} files log public/plugin_assets

    # remove PID file to enable restarting the container
    rm -f /usr/src/redmine/tmp/pids/server.pid

    if [ "$1" = 'passenger' ]; then
      # Don't fear the reaper.
      set -- tini -- "$@"
    fi

    set -- gosu redmine "$@"
    ;;
esac

exec "$@"
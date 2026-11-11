#!/bin/sh
set -eu
: "${REDMINE_DATABASE_PASSWORD:?A run-owned database password is required}"
: "${SECRET_KEY_BASE:?A run-owned Rails session secret is required}"
mkdir -p /data/files /data/log /data/tmp/pids /data/assets /data/plugin_assets
rm -f /data/tmp/pids/server.pid
bundle exec rails db:migrate
REDMINE_LANG=en bundle exec rails redmine:load_default_data
exec "$@"

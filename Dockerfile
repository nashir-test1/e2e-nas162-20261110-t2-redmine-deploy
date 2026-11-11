FROM ruby:3.4-slim-bookworm AS build
RUN apt-get update \
 && apt-get install -y --no-install-recommends build-essential git libpq-dev pkg-config ca-certificates \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /app
COPY . .
COPY deploy/database.yml config/database.yml
ENV RAILS_ENV=production
# Puma is already declared in the original Gemfile's test group.
# Install the original dependency set without changing Gemfile or its locks.
RUN bundle install --jobs=2 --retry=2
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

FROM ruby:3.4-slim-bookworm
RUN apt-get update \
 && apt-get install -y --no-install-recommends libpq5 ca-certificates git \
 && rm -rf /var/lib/apt/lists/* \
 && groupadd --gid 10001 redmine \
 && useradd --uid 10001 --gid 10001 --home-dir /data --no-create-home redmine
WORKDIR /app
COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build /app /app
RUN install -d -o 10001 -g 10001 /data/files /data/log /data/tmp /data/assets /data/plugin_assets \
 && cp -a public/assets/. /data/assets/ \
 && rm -rf files log tmp public/assets public/plugin_assets \
 && ln -s /data/files files \
 && ln -s /data/log log \
 && ln -s /data/tmp tmp \
 && ln -s /data/assets public/assets \
 && ln -s /data/plugin_assets public/plugin_assets \
 && chown -R 10001:10001 /data
ENV RAILS_ENV=production \
    RAILS_LOG_TO_STDOUT=1 \
    RAILS_SERVE_STATIC_FILES=1 \
    HOME=/data \
    SCHEMA=/data/schema.rb
USER 10001:10001
VOLUME ["/data"]
EXPOSE 3000
ENTRYPOINT ["sh", "/app/deploy/entrypoint.sh"]
CMD ["bundle", "exec", "rails", "server", "-b", "0.0.0.0", "-p", "3000"]

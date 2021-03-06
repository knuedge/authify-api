FROM ruby:2.3.4-alpine

ENV AUTHIFY_PORT=9292
ENV AUTHIFY_ENVIRONMENT=development
ENV AUTHIFY_DB_URL=sqlite3:///tmp/authify-api.db
ENV AUTHIFY_REDIS_HOST=redis
ENV AUTHIFY_PUBKEY_PATH=/ssl/public.pem
ENV AUTHIFY_PRIVKEY_PATH=/ssl/private.pem
ENV AUTHIFY_JWT_ISSUER="My Awesome Company Inc."
ENV AUTHIFY_JWT_ALGORITHM="ES512"
ENV AUTHIFY_JWT_EXPIRATION="15"
ENV AUTHIFY_VERIFICATIONS_REQUIRED="true"

RUN apk --no-cache upgrade \
    && apk --no-cache add \
       git \
       sqlite-libs mariadb-client mariadb-client-libs

RUN apk --no-cache add --virtual build-dependencies \
        build-base \
        ruby-dev \
        sqlite-dev \
        mariadb-dev

COPY . /app
RUN cd /app \
    && bundle install --jobs=4 \
    && apk del build-dependencies

RUN mkdir /ssl

RUN chown -R root:root /app \
    && chown nobody:nogroup /app/db \
    && chown nobody:nogroup /app/db/schema.rb \
    && rm -f /app/.travis.yml \
    && chown -R nobody:nogroup /ssl

USER nobody
WORKDIR /app

VOLUME /ssl

CMD bundle exec rake db:migrate \
    && bundle exec rackup \
       -o 0.0.0.0 \
       -p $AUTHIFY_PORT \
       -E $AUTHIFY_ENVIRONMENT

FROM --platform=$BUILDPLATFORM postgres:16-alpine

ARG TARGETARCH

ENV PG_CRON_VERSION v1.6.2

RUN set -ex \
    # Install build deps
    && apk add --no-cache --virtual .build-deps \
        git \
        autoconf \
        automake \
        g++ \
        clang15 \
        llvm15 \
        libtool \
        libxml2-dev \
        make
RUN set -ex \
    # Install pg_partman
    && mkdir -p /usr/src/ \
    && cd /usr/src/ \
    && git clone "https://github.com/pgpartman/pg_partman.git" pg_partman \
    && cd pg_partman \
    && git checkout 5.1.0-beta \
    && make \
    && make install \
    && cd .. \
    && rm -rf pg_partman
RUN set -ex \
    # Install pg_cron
    && wget -O pg_cron.tar.gz "https://github.com/citusdata/pg_cron/archive/$PG_CRON_VERSION.tar.gz" \
    && mkdir -p /usr/src/pg_cron \
    && tar \
        --extract \
        --file pg_cron.tar.gz \
        --directory /usr/src/pg_cron \
        --strip-components 1 \
    && rm pg_cron.tar.gz \
    && cd /usr/src/pg_cron \
    && make \
    && make install \
    && rm -rf /usr/src/pg_cron
RUN set -ex \
    # Remove build deps
    && apk del .build-deps

# Custom entrypoint is needed to setup pg_cron
COPY entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
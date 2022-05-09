FROM node:16-bullseye-slim AS builder

WORKDIR /app

COPY src /app/src
COPY config /app/config
COPY @types /app/@types
COPY package.json package-lock.json tsconfig.json /app/

RUN npm install && npm run build && npm prune --production




ENV CURLVERSION curl-7.65.3
RUN apt-get update && apt-get install  --yes libssl-dev libssl-dev  wget build-essential \
    && wget https://curl.haxx.se/download/$CURLVERSION.tar.gz \
    && tar xvzf $CURLVERSION.tar.gz \
    && rm $CURLVERSION.tar.gz \
    && cd $CURLVERSION \
    && LDFLAGS="-static" PKG_CONFIG="pkg-config --static" ./configure --with-ca-fallback --with-ssl  --disable-shared --enable-static --with-openssl   \
    --disable-file --disable-ftp --disable-gopher \
    --disable-imap --disable-ldap --disable-ldaps --disable-pop3 --disable-rtsp --disable-smtp --disable-telnet \
    --disable-tftp --disable-dict --disable-ares --disable-cookies  --disable-manual --disable-thread \
    && make curl_LDFLAGS="-static -all-static" \
    && strip src/curl \
    && make install

ENV MTRVERSION v0.95
RUN mkdir mtr-$MTRVERSION && cd mtr-$MTRVERSION && apt-get update && apt-get install  --yes   wget build-essential autotools-dev automake pkg-config libcap2-bin libjansson-dev\ 
    && wget --no-check-certificate --content-disposition https://github.com/traviscross/mtr/tarball/$MTRVERSION  -O - | tar -xz --strip-components=1 \
    && pwd ; ls -aul \
    && ./bootstrap.sh \
    && LDFLAGS="-static" PKG_CONFIG="pkg-config --static"  ./configure \
    && make \
    && strip mtr  \
    && make install




FROM node:buster-slim

ARG node_env=production
ENV NODE_ENV=$node_env

COPY --from=builder /usr/local/bin/curl /usr/local/bin/curl
COPY --from=builder /usr/local/sbin/mtr /usr/local/sbin/mtr
COPY --from=builder /usr/local/sbin/mtr-packet /usr/local/sbin/mtr-packet

WORKDIR /app
COPY --from=builder /app/dist /app/dist
COPY --from=builder /app/config /app/config
COPY --from=builder /app/package.json /app/package-lock.json /app/
COPY bin/entrypoint.sh /entrypoint.sh


RUN apt-get update && apt-get install  --yes iputils-ping traceroute dnsutils jq tini ca-certificates  && apt-get clean \
    && apt autoremove -y && rm -rf /var/lib/{apt,dpkg,cache,log} && \
    rm -rf /usr/share/doc  /usr/include /usr/local/include /usr/share/X11 /opt /usr/lib/arm-linux-gnueabihf/perl-base  /usr/share/man \
    /var/lib/apt /var/lib/dpkg /var/cache/debconf /usr/local/lib/node_modules/npm/docs\
    /sbin/debugfs /sbin/e2fsck /sbin/ldconfig /usr/bin/openssl /usr/bin/perl /usr/bin/tini-static /usr/share/perl5 /usr/bin/perl5.28.1 \
    && cd /app && npm install --production

ENTRYPOINT ["/usr/bin/tini", "--"]

CMD ["/entrypoint.sh"]

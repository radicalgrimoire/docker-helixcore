FROM ubuntu:noble
LABEL org.opencontainers.image.maintainer="ueno.s <ueno.s@gamestudio.co.jp>"

# Add external files
COPY files/run.sh /usr/local/bin/run.sh
COPY files/init.sh /usr/local/bin/init.sh
COPY files/p4.* /etc/logrotate.d/
COPY files/CheckCaseTrigger*.py /usr/local/bin/
COPY files/P4Triggers.py /usr/local/bin/P4Triggers.py
COPY files/admin.txt /opt/perforce/admin.txt

ARG P4NAME
ARG P4PORT
ARG P4USER
ARG P4PASSWD
ARG CASE_INSENSITIVE
ARG P4HOME
ARG P4ROOT

ENV P4NAME=$P4NAME \
    P4PORT=$P4PORT \
    P4USER=$P4USER \
    P4PASSWD=$P4PASSWD \
    P4HOME=$P4HOME \
    P4ROOT=$P4ROOT \
    CASE_INSENSITIVE=$CASE_INSENSITIVE \
    LANG=ja_JP.UTF-8 \
    LANGUAGE=ja_JP:ja

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apt-get update -y \
    && apt-get install -y gnupg language-pack-ja-base language-pack-ja tzdata curl jq openssl cron logrotate git \
    && locale-gen ja_JP.UTF-8 \
    && curl -sS https://package.perforce.com/perforce.pubkey | gpg --dearmor -o /usr/share/keyrings/perforce.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/perforce.gpg] http://package.perforce.com/apt/ubuntu noble release" > /etc/apt/sources.list.d/perforce.list \
    && apt-get update && apt-get -y install helix-p4d python3 perforce-p4python3 \
    && P4D_VERSION=$(p4d -V | head -1 | cut -d' ' -f3 | cut -d'/' -f1) \
    && echo "Installed P4D version: $P4D_VERSION" \
    && git clone https://github.com/perforce/helix-authentication-extension.git /opt/helix-authentication-extension \
    && apt-get remove -y git \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && chmod +x /usr/local/bin/init.sh \
    && chmod +x /usr/local/bin/run.sh \
    && chmod 644 /etc/logrotate.d/p4.* \
    && sed -i 's/\r$//' /usr/local/bin/init.sh \
    && sed -i 's/\r$//' /usr/local/bin/run.sh \
    && bash /usr/local/bin/init.sh

EXPOSE 1666

HEALTHCHECK \
    --interval=2m \
    --timeout=30s \
    CMD p4 -p ssl:1666 info -s > /dev/null || exit 1

CMD ["/usr/local/bin/run.sh"]
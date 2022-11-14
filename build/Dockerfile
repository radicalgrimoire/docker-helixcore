FROM ubuntu:focal
LABEL maintainer "ueno.s <ueno.s@gamestudio.co.jp>"

# Add external files
COPY files/run.sh /usr/local/bin/run.sh
COPY files/init.sh /usr/local/bin/init.sh
COPY files/p4.auth /etc/logrotate.d/p4.auth
COPY files/p4.commands /etc/logrotate.d/p4.commands
COPY files/p4.errors /etc/logrotate.d/p4.errors
COPY files/p4.events /etc/logrotate.d/p4.events
COPY files/p4.integrity /etc/logrotate.d/p4.integrity
COPY files/p4.log /etc/logrotate.d/p4.log
COPY files/CheckCaseTrigger.py /usr/local/bin/CheckCaseTrigger.py
COPY files/CheckCaseTrigger3.py /usr/local/bin/CheckCaseTrigger3.py
COPY files/P4Triggers.py /usr/local/bin/P4Triggers.py

ARG P4NAME=master
ARG P4TCP=1666
ARG P4USER=super
ARG P4PASSWD=Passw0rd
ARG P4CASE=0
ARG P4HOME=/opt/perforce/servers

ENV P4NAME=$P4NAME \
    P4TCP=$P4TCP \
    P4PORT=ssl:$P4TCP \
    P4USER=$P4USER \
    P4PASSWD=$P4PASSWD \
    P4HOME=$P4HOME \
    P4ROOT=$P4HOME/$P4NAME \
    CASE_INSENSITIVE=$P4CASE

RUN ln -sf /usr/share/zoneinfo/Asia/Tokyo /etc/localtime

RUN apt-get update -y \
    && apt-get install -y wget gnupg less language-pack-ja-base language-pack-ja tzdata curl jq git openssl sudo vim wget unzip cron logrotate init systemd

RUN echo 'export LANG=ja_JP.UTF-8' >> ~/.bashrc ;\
    echo 'export LANGUAGE="ja_JP:ja"' >> ~/.bashrc

RUN wget -qO - https://package.perforce.com/perforce.pubkey | apt-key add - ;\
    echo "deb http://package.perforce.com/apt/ubuntu focal release" >> /etc/apt/sources.list.d/perforce.list

RUN apt-get update && apt-get -y install helix-p4d python3 python3-distutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN chmod +x /usr/local/bin/run.sh \
    && chmod 644 /etc/logrotate.d/p4.auth \
    && chmod 644 /etc/logrotate.d/p4.commands \
    && chmod 644 /etc/logrotate.d/p4.errors \
    && chmod 644 /etc/logrotate.d/p4.events \
    && chmod 644 /etc/logrotate.d/p4.integrity \
    && chmod 644 /etc/logrotate.d/p4.log \
    && curl -kL https://bootstrap.pypa.io/get-pip.py | python3 \
    && pip install p4python \
    && bash /usr/local/bin/init.sh

EXPOSE 1666

HEALTHCHECK \
    --interval=2m \
    --timeout=30s \
    CMD p4 -p ssl:1666 info -s > /dev/null || exit 1

CMD ["/usr/local/bin/run.sh"]
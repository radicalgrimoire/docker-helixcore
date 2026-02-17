FROM ghcr.io/radicalgrimoire/docker-helixcore/helix-p4d:latest

LABEL maintainer="ueno.s <ueno.s@gamestudio.co.jp>"

COPY download-certs.sh /usr/local/bin/download-certs.sh
RUN chmod +x /usr/local/bin/download-certs.sh

CMD ["/usr/local/bin/run.sh"]

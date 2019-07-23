FROM opensuse/leap

RUN zypper in -y lighttpd

COPY lighttpd-start.sh /lighttpd-start.sh
ENTRYPOINT /lighttpd-start.sh

FROM opensuse/leap

RUN zypper in -y dhcp-server

COPY dhcp-start.sh /dhcp-start.sh
ENTRYPOINT /dhcp-start.sh

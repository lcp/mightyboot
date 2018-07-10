FROM opensuse

RUN zypper in -y dhcp-server

COPY dhcp6-start.sh /dhcp6-start.sh
ENTRYPOINT /dhcp6-start.sh

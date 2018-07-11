FROM opensuse

RUN zypper in -y dnsmasq

COPY dnsmasq-start.sh /dnsmasq-start.sh
ENTRYPOINT /dnsmasq-start.sh

# mightyboot

Mightyboot is a collection of services to quickly set up a PXE and HTTP(S)
Boot server for an isolated network environment. It comprises of 4 services:

* **dhcp** - DHCP service for IPv4
* **dhcp6** - DHCP service for IPv6
* **dnsmasq** - DNS and tftp services
* **lighttpd** - HTTP service

All service are run in the **host** network mode.

## Configuration

The related settings are controlled by the **env** file. There are several
environment variables, and the start-up scripts in the services will adjust the
config files accordingly. Here are the variables:

* **IFACE** - which network interface the services should listen to
* **IP4_PREFIX** - the prefix of IPv4 address of the target interface
* **IP6_PREFIX** - the prefix of IPv6 address of the target interface
* **PXE_URI** - the path to the bootloader in the tftp server
* **SERVER_NAME** - the domain name of the server
* **HTTPBOOT_URI** - the IPv4 HTTP URI to the UEFI bootloader
* **HTTPBOOT6_URI** - the IPv6 HTTP URI to the UEFI bootloader
* **HTTPS** - whether to enable HTTPS or not
* **SERVER_KEY** - the encrypt key for HTTPS

### Network Interface

Mightyboot assumes the IP addresses of the interface are **IP4_PREFIX**.1/24
and **IP6_PREFIX**1/64.

For example, to use mightyboot on *eth0* with **IP4_PREFIX**=192.168.110 and
**IP6_PREFIX**=2001:db8:f00f:cafe::, then the IP addresses of *eth0* **should**
be 192.168.110.1/24 and 2001:db8:f00f:cafe::1/64.

### DHCP

The ranges of DHCP IP addresses are **IP4_PREFIX**.100 to **IP4_PREFIX**.200
and **IP6_PREFIX**42:10 to **IP6_PREFIX**42:99. So, the ranges of DHCP IP
addresses in the previous example will be 192.168.110.100 to 192.168.110.200
and 2001:db8:f00f:cafe::42:10 to 2001:db8:f00f:cafe::42:99.

### PXE Path

Mightyboot mounts *data/tftproot* as the tftproot for dnsmasq. The user has to
install the pxe bootlader in *data/tftproot* and set **PXE_URI** properly.

For openSUSE/SLE, we just copy *EFI* and *boot* from openSUSE/SLE DVD image to
*data/tftproot/opensuse*, and set **PXE_URI** as */opensuse/EFI/BOOT/bootx64.efi*.

NOTE: Remember to adjust the paths in *grub.cfg*

### DNS

The domain name of the server can be customized with **SERVER_NAME**. The
dnsmasq service will map the default IPv4/IPv6 address to the specified
domain name.

### HTTP

Mightyboot mounts *data/www/htdocs* to */srv/www/htdocs* for lighttpd service,
so the HTTPBoot bootloader has to be installed in *data/www/htdocs*.

There are 2 HTTPBoot variable: **HTTPBOOT_URI**(IPv4) and
**HTTPBOOT6_URI**(IPv6). Both of them point to the specified bootloader.

Since HTTP server also can be the installation server of openSUSE/SLE, we can
copy everything in the installation DVD to *data/www/htdocs/suse* and set the URI
to "http://SERVER_NAME/suse/EFI/BOOT/bootx64.efi".

NOTE: Remember to adjust the paths in *grub.cfg*

### HTTPS

To enable HTTPS support in mightyboot, you need a server key.
Please refer [SSL Support for HTTP Server](https://en.opensuse.org/UEFI_HTTPBoot_with_OVMF#SSL_Support_for_HTTP_Server.28Optional.29)
to create a test key if necessary. The server key **must** contain both
the public certificate and the private key.

After creating the server key, copy the server key file to *data/lighttpd*.
Then, set **HTTPS** in **env** to **TRUE** and assign the file name of the
server key to **SERVER_KEY**. For example:

    HTTPS=TRUE
    SERVER_KEY=server.pem

### Grub2

There is a grub.cfg example in *data* in case you need a reference of grub.cfg.

## Launch Services

Just make sure that your system already installs docker and docker-compose and
run:

    $ docker-compose up

This first startup time will be longer since docker-compose has to download
and build images for the services. Once the images are cached, it will be much
faster.

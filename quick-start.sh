#!/bin/bash
# A quick setup script to switch the settings between different
# installation images
#
# Before starting the script:
# - Copy EFI and boot from SLE15 DVD1 to data/tftproot/SLE15
# - Copy everything in SLE15 DVD1 to data/www/htdocs/SLE15
# - Modify data/grub.cfg.example and copy it to
#   + data/tftproot/SLE15/EFI/BOOT/grub.cfg
#   + data/www/htdocs/SLE15/EFI/BOOT/grub.cfg
#
# Example:
#    SLE15 Image for PXE and HTTPBoot:
#    $ ./quick-start sle15
#
#    SLE15 Image for PXE and HTTPSBoot:
#    $ ./quick-start sle15 httpsboot

PREFIX=http

case "$1" in
	"sle15")
		TARGET="SLE15"
		LOADER="bootx64.efi"
		;;
	"sle15-aa64")
		TARGET="SLE15-AArch64"
		LOADER="bootaa64.efi"
	       	;;
	"leap15")
		TARGET="openSUSE15"
		LOADER="bootx64.efi"
		;;
	"leap15-aa64")
		TARGET="openSUSE15-AArch64"
		LOADER="bootaa64.efi"
		;;
	*)
		echo "Usage $0 <OS>"
		exit 1
		;;
esac

case "$2" in
	"httpsboot")
		PREFIX=https
		;;
esac

# Modify those variables to match the system settings
IFACE=vmbr0
IP4_PREFIX="192.168.110"
IP6_PREFIX="2001:db8:f00f:cafe::"
SERVER_NAME="www.httpboot.local"
SERVER_KEY="server.pem"

# Generate the other variables 
PXE_URI="/$TARGET/EFI/BOOT/$LOADER"
HTTPBOOT_URI="$PREFIX://$SERVER_NAME/$TARGET/EFI/BOOT/$LOADER"
HTTPBOOT6_URI=$HTTPBOOT_URI

sed "s,__IFACE__,$IFACE,g
     s,__IP4_PREFIX__,$IP4_PREFIX,g
     s,__IP6_PREFIX__,$IP6_PREFIX,g
     s,__PXE_URI__,$PXE_URI,g
     s,__SERVER_NAME__,$SERVER_NAME,g
     s,__HTTPBOOT_URI__,$HTTPBOOT_URI,g
     s,__HTTPBOOT6_URI__,$HTTPBOOT6_URI,g
     s,__SERVER_KEY__,$SERVER_KEY,g" env.template > env

echo "Start services for $TARGET"
docker-compose up

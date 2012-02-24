#!/bin/sh
#
# Gentoo Linux 10.0
#

export LANG=C
export LC_ALL=C

builder_path=${builder_path:?"builder_path needs to be set"}


# core packages
pkg="
 net-firewall/ebtables net-firewall/iptables net-firewall/ipset
 sys-apps/ethtool net-misc/vconfig
 net-misc/openssh dev-lang/ruby:1.8 net-misc/curl
 net-misc/rabbitmq-server
 app-emulation/qemu-kvm
 net-misc/bridge-utils
 sys-apps/usermode-utilities
 net-dns/dnsmasq sys-block/open-iscsi
 www-servers/nginx dev-libs/libxml2  dev-libs/libxslt
 net-misc/ipcalc sys-fs/dosfstools
 sys-block/tgt app-emulation/lxc
"
case $database_type in
mysql)
db_pkg='dev-db/mysql'
;;

postgresql)
db_pkg='dev-db/postgresql-server'
;;
esac

# host configuration
#hostname | diff /etc/hostname - >/dev/null || hostname > /etc/hostname
#egrep -v '^#' /etc/hosts | egrep -q $(hostname) || echo 127.0.0.1 $(hostname) >> /etc/hosts

#  some packages use ubuntu-natty. ex. lxc
echo $(dirname $0)

# debian packages
emerge --sync
emerge -vu ${pkg} ${db_pkg}

exit 0

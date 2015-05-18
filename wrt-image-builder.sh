#!/usr/bin/env bash

VERSION="trunk"
ARCH="ar71xx"
IMAGE_BUILDER="OpenWrt-ImageBuilder-$ARCH-generic.Linux-x86_64"
HTTP="http:/"
HTTPS="https:/"
OPENWRT_BASE_URL="downloads.openwrt.org/snapshots/$VERSION"
SRC="$HTTPS/$OPENWRT_BASE_URL/$ARCH/generic/$IMAGE_BUILDER.tar.bz2"

# Get Dependencies (Ubuntu only for now)
sudo apt-get install subversion build-essential libncurses5-dev zlib1g-dev gawk git ccache gettext libssl-dev xsltproc

# Download Image Builder
pushd /tmp
curl $SRC | tar xj
cd $IMAGE_BUILDER

# Configure package repositiories
PACKAGE_BASE_URL="$HTTP/$OPENWRT_BASE_URL/$ARCH/generic/packages"
cat <<EOF > repositories.conf
src/gz chaos_calmer_base $PACKAGE_BASE_URL/base
src/gz chaos_calmer_luci $PACKAGE_BASE_URL/luci
src/gz chaos_calmer_management $PACKAGE_BASE_URL/management
src/gz chaos_calmer_packages $PACKAGE_BASE_URL/packages
src/gz chaos_calmer_routing $PACKAGE_BASE_URL/routing
src/gz chaos_calmer_telephony $PACKAGE_BASE_URL/telephony
## This is the local package repository, do not remove!
src imagebuilder file:packages
EOF

# Configuration files
mkdir -p files/etc/config
# Wireless configuration for batman
cat <<EOF > files/etc/config/wireless
config wifi-device  radio0
        option type     mac80211
        option channel  1
        option hwmode   11g
        option path     'platform/ar933x_wmac'
        option htmode HT20

config wifi-iface 'mesh0'
        option device   radio0
        option ifname   mesh0
        option network  mesh
        option mode     adhoc
        option ssid     mesh
        option bssid '02:12:34:56:78:9A'
        option mcast_rate 18000
        option encryption none
EOF
# Network configuration for batman
cat <<EOF > files/etc/config/network
config interface 'loopback'
        option ifname 'lo'
        option proto 'static'
        option ipaddr '127.0.0.1'
        option netmask '255.0.0.0'

config globals 'globals'
        option ula_prefix 'fdf3:0a0a:d536::/48'

config interface 'lan'
        option ifname 'eth0'
        option force_link '1'
        option proto 'static'
        option ipaddr '192.168.1.1'
        option netmask '255.255.255.0'

config interface 'mesh'
        option mtu 1532
        option proto batadv
        option mesh bat0

config interface 'bat'
        option ifname 'bat0'
        option proto 'static'
        option mtu '1500'
        option ipaddr '10.0.0.10'
        option netmask '255.255.255.0'
EOF

# Actually build the image, adding these packages
make image PROFILE=TLMR3040 PACKAGES="kmod-batman-adv batctl" FILES=files/

# Copy the generated image back to the current directory
popd
mkdir -p images
cp /tmp/$IMAGE_BUILDER/bin/$ARCH/*mr3040* images/

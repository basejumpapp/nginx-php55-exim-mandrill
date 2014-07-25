#!/bin/bash

# get ec2 public hostname
cat /etc/issue | grep Amazon
if [ -e /etc/issue ]; then
    AMAZON_ISSUE=$(cat /etc/issue | grep Amazon)
    if [ -n "$AMAZON_ISSUE" ]; then
        # is amazon
        PUBLIC_HOSTNAME=$(curl -q http://169.254.169.254/latest/meta-data/public-hostname 2>/dev/null)
    else
        # not amazon
        if [ -n "$HOST_DOMAIN" ]; then
            # use HOST_DOMAIN environment variable
            PUBLIC_HOSTNAME=$HOST_DOMAIN
        else
            # last resort: just use the IP address
            PUBLIC_HOSTNAME=$(hostname -I | cut -f1 -d' ')
        fi
    fi
fi;


# modify exim.conf
SRC_FILE="/etc/exim/exim.conf"
TMP_FILE="/tmp/exim.conf"
SED_LINE1='s!@@HOSTNAME@@!'${PUBLIC_HOSTNAME}'!g'
SED_LINE2='s!@@MANDRILL_EMAIL@@!'${MANDRILL_EMAIL}'!g'
SED_LINE3='s!@@MANDRILL_PASSWORD@@!'${MANDRILL_PASSWORD}'!g'
echo $SED_LINE1 > /tmp/SED_LINE1;
echo $SED_LINE2 > /tmp/SED_LINE2;
echo $SED_LINE3 > /tmp/SED_LINE3;
/bin/cp $SRC_FILE $TMP_FILE
cat $TMP_FILE | sed -f /tmp/SED_LINE1 -f /tmp/SED_LINE2 -f /tmp/SED_LINE3 > $SRC_FILE

# set logs permissions
chown -R exim. /var/log/exim

# start exim
/usr/sbin/exim -bdf -q1h

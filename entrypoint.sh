#!/bin/bash

PWCLEAR="$(echo {A..Z} {a..z} {0..9} {0..9} '@ # % ^ ( ) _ + = - [ ] { } . ?' | tr ' ' "\n" | shuf | xargs | tr -d ' ' | cut -b 1-12)"
PWCRYPT="$(rspamadm pw -e -p $PWCLEAR)"

SECURE_IP=${SECURE_IP:-"127.0.0.1"}
PASSWORD=${PASSWORD:-"$PWCRYPT"}
#ENABLE_PASSWORD=${ENABLE_PASSWORD:-$PASSWORD}

if [ ! -f /etc/rspamd/local.d/worker-controller.inc ]; then
cat << EOF > /etc/rspamd/local.d/worker-controller.inc
bind_socket = "0.0.0.0:11334";
secure_ip = "${SECURE_IP}";
password = "${PASSWORD}";
#enable_password = "${PASSWORD}";
EOF
        echo " "
        echo " "
        echo "      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
	echo " "
        echo "      THE PASSWORD TO ACCESS THE WEB UI IS:  $PWCLEAR"
        echo " "
        echo "      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
        echo " "
        echo " "
else
	echo " "
	echo " "
	echo "      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
	echo "      IF YOU DIDN'T SET '\$PASSWORD' VARIABLE"
	echo "      OR IF YOU DON'T KNOW WHAT I'M SAYING"
	echo "      AND YOU DON'T KNOW THE PASSWORD TO ACCESS"
    echo "      THE WEB UI, THEN ENTER THE CONTAINER AND"
	echo "      DELETE THE FILE /etc/rspamd/local.d/worker-controller.inc"
	echo "      THEN RESTART THE CONTAINER AND SHOW THE CONSOLE LOGS"
	echo "      THE PASSWORD WILL BE PUT ON THE SCREEN"
	echo "      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^"
	echo " "
	echo " "
fi

LOGFILE="/var/log/rspamd/rspamd.log"

mkdir -p /var/log/rspamd
if [ ! -f $LOGFILE ]; then
    touch $LOGFILE
    chown rspamd:rspamd $LOGFILE
fi

if [ -d /var/lib/rspamd/dynamic ]; then
  rmdir /var/lib/rspamd/dynamic
fi
if [ ! -f /var/lib/rspamd/dynamic ]; then
  touch /var/lib/rspamd/dynamic && chmod 666 /var/lib/rspamd/dynamic 
fi

WAITFOR="ciccio:clamav pluto:rspamd"
check_service() {
  until eval $1 ; do
    sleep 1
    echo -n "..."
  done
  echo "OK"
}
if [ -n "$WAITFOR" ]; then
  for SERVICE in $WAITFOR; do
    NAME=${SERVICE%:*}
    CHECK=${SERVICE#*:}
    if [ -z "$NAME" -o -z "$CHECK" ]; then
      continue
    fi
    echo -n "Checking for $NAME..."
    case "$CHECK" in
      "clamav")
        check_service 'echo PING | nc -w 5 $NAME 3310 2>/dev/null'
        ;;
      "rspamd")
        check_service "ping -c1 $NAME 2>/dev/null"
        ;;
    esac
  done
fi

exec tail -f /var/log/rspamd/rspamd.log &
#rspamd -i -f
exec "$@"

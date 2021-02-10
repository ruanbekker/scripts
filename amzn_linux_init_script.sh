#!/usr/bin/env bash
# inspired by:
# https://unix.stackexchange.com/a/193568

# source function library
. /etc/init.d/functions

# application name
APP="node_exporter"
DESC="Node Exporter"

# chkconfig ${APP} on
# description: ${APP}

PATH=/sbin:/usr/sbin:/bin:/usr/bin
RETVAL=0
PIDFILE=/var/run/${APP}.pid
LOCKFILE=/var/lock/subsys/${APP}
DAEMON=${APP}
DAEMON_HOME="/usr/bin/"
BINARY=$DAEMON_HOME/${APP}
SCRIPTNAME=/etc/init.d/${APP}

# the user that will run the script
USER=root

start() {
    if [ -f ${PIDFILE} ]
    then
        PID=$(cat ${PIDFILE})
        if [ -z "$(pgrep ${PID})" ] && [ "${PID}" != "$(ps aux|grep -vE 'grep|runuser|bash'|grep -w "${APP}" | awk '{print $2}')" ]
        then
            printf "%s\n" "Process dead but pidfile exists"
        else
            printf "${APP} is already running!\n"
        fi
    else
        printf "%-50s" "Starting ${APP} ..."
        cd ${DAEMON_HOME}
        daemon --user ${USER} ${DAEMON}  >/dev/null 2>&1 &
        sleep 5
        PID=$(ps aux|grep -vE 'grep|runuser|bash'|grep -w "${APP}" | awk '{print $2}')
        if [ -z "$PID" ]
        then
            printf "[ \e[31mFAIL\033[0m ]\n"
        else
            echo ${PID} > ${PIDFILE}
            printf "[ \e[32mOK\033[0m ]\n"
        fi
    fi
}

stop() {
    printf "%-50s" "Shutting down ${APP} :"
    if [ -f ${PIDFILE} ]
    then
        PID=$(cat $PIDFILE)
        kill -HUP ${PID} 2>/dev/null
        printf "[ \e[32mOK\033[0m ]\n"
        rm -f ${PIDFILE}
    else
        printf "[ \e[31mFAIL\033[0m ]\n"
    fi
}

check_status() {
    printf "%-50s" "Checking ${APP} ..."
    if [ -f ${PIDFILE} ]
    then
        PID=$(cat ${PIDFILE})
        if [ -z "$(pgrep ${PID})" ] && [ "${PID}" != "$(ps aux|grep -vE 'grep|runuser|bash'|grep -w "${APP}" |awk '{print $2}')" ]
        then
            printf "%s\n" "Process dead but pidfile exists"
        else
            printf "[ \e[32mRUNNING\033[0m ]\n"
        fi
    else
        printf "[ \e[31mSTOPPED\033[0m ]\n"
    fi
}

case "${1}" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    status)
        check_status
        ;;
    restart)
        stop
        start
        ;;
    *)
        echo "Usage: ${APP} {start|stop|status|restart}"
        exit 1
        ;;
esac
exit 1

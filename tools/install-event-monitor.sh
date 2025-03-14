#!/usr/bin/env bash

export ADB=`which adb`

_adb_push() {
    "$ADB" push "$(dirname "$0")/$1" "$2"
}

_adb_shell() {
    "$ADB" shell "$1"
}

setup_event_monitor() {
    # Push the event monitor script to /tmp
    _adb_push event_monitor.sh /tmp/event_monitor.sh
    _adb_shell chmod 755 /tmp/event_monitor.sh
    _adb_shell /bin/rootshell -c 'mv /tmp/event_monitor.sh /data/rayhunter/event_monitor.sh' 
    # Although the command above gives an error, it actually works

    # Push and install the init.d script
    _adb_push tools/event_monitor_daemon /tmp/event_monitor_daemon
    _adb_shell chmod 755 /tmp/event_monitor_daemon
    _adb_shell /bin/rootshell -c 'mv /tmp/event_monitor_daemon /etc/init.d/event_monitor_daemon'
    # Although the command above gives an error, it actually works
    
    # Start the event monitor
    _adb_shell /bin/rootshell -c "/etc/init.d/event_monitor_daemon start"
}

setup_event_monitor 
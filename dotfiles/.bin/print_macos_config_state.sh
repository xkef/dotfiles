#!/bin/bash

# -------------------------------------------------
# Description:  macos system information fetching
# Create by:    xkef
# Since:        12/23/2018 (DD/MM/YYYY)
# -------------------------------------------------
# Version:      1.0
# -------------------------------------------------
# Bug:
# -------------------------------------------------

set -e
# Everything below will go to the file 'macos_stats.txt':

# partially adapted from:
# github.com/herrbischoff/awesome-macos-command-line

usage() {
    echo "./macos_get_hardware_config.sh [options]"
    echo "Supported options:"
    echo "  -i (will print particular system infos)"
    echo "  -c (will show continuous stream of file system access info)"
    echo "  -n (will show continuous stream of networking events)"
    echo "  -a (will show local wifi access points)"
    echo "  -h (display this help menu)"
    echo "---> streams can aborted using ctrl-c"
}
usage
main_func() {
    # stolen from
    # serverfault.com/questions/103501/how-can-i-fully-log-all-bash-scripts-actions
    echo "------------------------------------------------------------"
    echo "cpu brand: "
    sysctl -n machdep.cpu.brand_string

    echo "------------------------------------------------------------"
    echo "List All Hardware Ports: "
    networksetup -listallhardwareports

    echo "------------------------------------------------------------"
    echo "Remaining Battery (%): "
    pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f1 -d";"

    echo "------------------------------------------------------------"
    echo "Remaining Battery (%): "
    pmset -g batt | egrep "([0-9]+\%).*" -o --colour=auto | cut -f3 -d";"

    echo "------------------------------------------------------------"
    echo "Connected Device UDID: "
    system_profiler SPUSBDataType | sed -n -e "/iPad/,/Serial/p" -e '/iPhone/,/Serial/p'

    echo "------------------------------------------------------------"
    echo "Current Screen Resolution: "
    system_profiler SPDisplaysDataType | grep Resolution

    echo "------------------------------------------------------------"
    echo "Bluetooth Power State "
    defaults read /Library/Preferences/com.apple.Bluetooth ControllerPowerState

    echo "------------------------------------------------------------"
    echo "List attached disks and partitions"
    diskutil list

    echo "------------------------------------------------------------"
    echo "All Power Management Settings"
    pmset -g

    echo "------------------------------------------------------------"
    echo "Check System Sleep Idle Time"
    systemsetup -getcomputersleep

    echo "------------------------------------------------------------"
    echo "DHCP Info"
    ipconfig getpacket en0

    echo "------------------------------------------------------------"
    echo "IP Adress"
    curl -s https://api.ipify.org && echo

    echo "------------------------------------------------------------"
    echo "current SSID identifier of your network card"
    /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I | awk '/ SSID/ {print substr($0, index($0, $2))}'

    echo "------------------------------------------------------------"
    echo "status of Firewall"
    /usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate

    echo "------------------------------------------------------------"
    echo "Gatekeeper Status"
    spctl --status

    echo "------------------------------------------------------------"
    echo "Build Nr of OS and System Software Version"
    sw_vers
    sw_vers -productVersion

    echo "------------------------------------------------------------"
    echo "uptime of current session"
    uptime

    echo "------------------------------------------------------------"
    kextstat -l | sed -e '/apple/ { N; d; }' | sed 's/.*\(com.*\). /\1/'

    echo "------------------------------------------------------------"
    echo "Memory Statistics"
    vm_stat -c 3 1 | awk '{print $1,$2,$3,$4,$6,$7,$8,$9}'

} >macos_stats.txt

while [ $# -gt 0 ]; do
    if [ "$1" = "-i" ]; then
        main_func
        open macos_stats.txt
        exit
    elif [ "$1" = "-h" ]; then
        usage
        exit
    elif [ "$1" = "-c" ]; then
        echo "------------------------------------------------------------"
        echo "continuous stream of file system access info."
        sudo fs_usage
        echo "------------------------------------------------------------"
        exit
    elif [ "$1" = "-n" ]; then
        sudo lsof -i
        exit
    elif [ "$1" = "-a" ]; then
        echo "------------------------------------------------------------"
        echo "Wirless Scan: "
        echo "------------------------------------------------------------"
        /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s
        echo "------------------------------------------------------------"
        echo "Connection History: "
        echo "------------------------------------------------------------"
        defaults read /Library/Preferences/SystemConfiguration/com.apple.airport.preferences | grep LastConnected -A 7
    else
        echo "Unrecognized argument(s): $*"
        usage
        exit
    fi
done

#!/usr/bin/env bash
# System info for the Laser Flow wallpaper terminal.
# Usage: sysinfo.sh static | live      Output: key=value lines. Read-only, no side effects.
export LC_ALL=C

static() {
    . /etc/os-release 2>/dev/null
    echo "user=$(id -un)"
    echo "host=$(hostname)"
    echo "os=${PRETTY_NAME:-Linux} $(uname -m)"
    echo "model=$(cat /sys/class/dmi/id/product_name 2>/dev/null)"
    echo "kernel=$(uname -r)"
    echo "packages=$(dpkg-query -f '.\n' -W 2>/dev/null | wc -l) (dpkg)"
    sh=$(getent passwd "$(id -un)" | cut -d: -f7); sh=${sh##*/}
    ver=$("$sh" --version 2>/dev/null | head -1 | grep -oE '[0-9]+(\.[0-9]+)+' | head -1)
    echo "shell=$sh $ver"
    echo "de=Plasma $(plasmashell --version 2>/dev/null | awk '{print $2}')"
    echo "wm=KWin (${XDG_SESSION_TYPE:-x11})"
    echo "theme=$(kreadconfig6 --file plasmarc --group Theme --key name 2>/dev/null)"
    echo "icons=$(kreadconfig6 --file kdeglobals --group Icons --key Theme 2>/dev/null)"
    echo "terminal=konsole $(konsole --version 2>/dev/null | awk '{print $2}')"
    echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2- | sed 's/^ *//; s/ with .*//') ($(nproc))"
    lspci 2>/dev/null | grep -iE 'vga|3d' | sed -E 's/.*: //; s/Corporation //; s/Advanced Micro Devices, Inc. \[AMD\/ATI\]/AMD/; s/ \(rev .*\)//; s/\[|\]//g; s/ \/ .*//' \
        | awk '{print "gpu" NR "=" $0}'
}

live() {
    read -r up _ < /proc/uptime
    up=${up%.*}; d=$((up/86400)); h=$((up%86400/3600)); m=$((up%3600/60))
    s=""; [ $d -gt 0 ] && s="$d days, "; echo "uptime=${s}${h} hours, ${m} mins"
    awk '/^MemTotal/{t=$2} /^MemAvailable/{a=$2} /^SwapTotal/{st=$2} /^SwapFree/{sf=$2}
         END{printf "mem=%d %d\nswap=%d %d\n",(t-a)/1024,t/1024,(st-sf)/1024,st/1024}' /proc/meminfo
    awk '/^cpu /{idle=$5+$6; tot=0; for(i=2;i<=NF;i++) tot+=$i; print "cpustat=" idle " " tot}' /proc/stat
    echo "load=$(cut -d' ' -f1-3 /proc/loadavg)"
    df -h / | awk 'NR==2{print "disk=" $3 " / " $2 " (" $5 ")"}'
    for b in /sys/class/power_supply/BAT*; do
        [ -r "$b/capacity" ] && echo "battery=$(cat "$b/capacity")% [$(cat "$b/status")]" && break
    done
    for hw in /sys/class/hwmon/hwmon*; do
        n=$(cat "$hw/name" 2>/dev/null); t=$(cat "$hw/temp1_input" 2>/dev/null) || continue
        case $n in k10temp|coretemp) echo "tcpu=$((t/1000))";; amdgpu) echo "tgpu=$((t/1000))";; nvme) echo "tnvme=$((t/1000))";; esac
    done
    ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(i=1;i<=NF;i++){if($i=="dev")d=$(i+1); if($i=="src")s=$(i+1)}} END{if(s) print "ip=" s " (" d ")"; else print "ip=offline"}'
    ps -eo comm=,%cpu=,%mem= --sort=-%cpu 2>/dev/null | head -4 | awk '{printf "proc%d=%-16s %5.1f%% cpu %5.1f%% mem\n", NR, substr($1,1,16), $2, $3}'
}

case "$1" in
    static) static ;;
    *) live ;;
esac

#!/bin/bash

# Function to display the script usage
function usage {
    echo "Usage: $0 -t targets.txt [-p tcp/udp/all] [-i interface] [-n nmap-options] [-h]"
    echo "       -h: Help"
    echo "       -t: File containing IP addresses to scan. This option is required."
    echo "       -p: Protocol. Defaults to tcp"
    echo "       -i: Network interface. Defaults to eth0"
    echo "       -n: NMAP options (-A, -O, etc). Defaults to no options."
}

# Function to scan TCP/UDP ports using unicornscan and nmap
function scan_ports {
    local proto=$1
    local ip=$2
    local iface=$3
    local results_dir=$4

    if [[ $proto == "tcp" || $proto == "all" ]]; then
        echo "Obtaining all open TCP ports using unicornscan..."
        local tcp_result="${results_dir}/${ip}/${ip}-unic-tcp.txt"
        mkdir -p "${results_dir}/${ip}" # Ensure directory exists
        echo "" > "$tcp_result"
        echo "unicornscan -i ${iface} -mT ${ip}:a -l ${tcp_result}" | tee "$tcp_result"
        unicornscan -i ${iface} -mT ${ip}:a -l "$tcp_result"

        local tcp_ports=$(grep open "$tcp_result" | cut -d"[" -f2 | cut -d"]" -f1 | tr -d ' ' | tr '\n' ',')
        if [[ ! -z $tcp_ports ]]; then
            echo "TCP ports for nmap to scan: $tcp_ports"
            echo "nmap -e ${iface} ${nmap_opt} -oA ${results_dir}/${ip}/${ip} -p ${tcp_ports} ${ip}"
            nmap -e ${iface} ${nmap_opt} -oA ${results_dir}/${ip}/${ip} -p "${tcp_ports}" "${ip}"
        else
            echo "[!] No TCP ports found"
        fi
    fi

    if [[ $proto == "udp" || $proto == "all" ]]; then
        echo "Obtaining all open UDP ports using unicornscan..."
        local udp_result="${results_dir}/${ip}/${ip}-unic-udp.txt"
        echo "" > "$udp_result"
        echo "unicornscan -i ${iface} -mU ${ip}:a -l ${udp_result}" | tee "$udp_result"
        unicornscan -i ${iface} -mU ${ip}:a -l "$udp_result"

        local udp_ports=$(grep open "$udp_result" | cut -d"[" -f2 | cut -d"]" -f1 | tr -d ' ' | tr '\n' ',')
        if [[ ! -z $udp_ports ]]; then
            echo "UDP ports for nmap to scan: $udp_ports"
            echo "nmap -e ${iface} ${nmap_opt} -sU -oA ${results_dir}/${ip}/${ip}U -p ${udp_ports} ${ip}"
            nmap -e ${iface} ${nmap_opt} -sU -oA ${results_dir}/${ip}/${ip}U -p "${udp_ports}" "${ip}"
        else
            echo "[!] No UDP ports found"
        fi
    fi
}

# Check if no arguments are provided
if [[ -z $1 ]]; then
    usage
    exit 0
fi

# Set commonly used default options
proto="tcp"
iface="eth0"
results="/home/kali/port_sweep_results"
nmap_opt="-n -Pn -sV -T4 -O --version-light --script=default"

# Parse the options
while getopts "p:i:t:n:h" OPT; do
    case $OPT in
        p) proto=${OPTARG};;
        i) iface=${OPTARG};;
        t) targets=${OPTARG};;
        n) nmap_opt=${OPTARG};;
        h) usage; exit 0;;
        *) usage; exit 0;;
    esac
done

# Check if target file is provided
if [[ -z $targets ]]; then
    echo "[!] No target file provided"
    usage
    exit 1
fi

# Read the targets file and scan each IP
while read -r ip; do
    scan_ports "$proto" "$ip" "$iface" "$results"
done < "$targets"

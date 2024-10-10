import subprocess
import sys
import os

def create_directory(dir_path):
    """Creates directory if it doesn't exist."""
    if not os.path.exists(dir_path):
        os.mkdir(dir_path)
        print(f"\n[!] {dir_path} didn't exist, created {dir_path}")

def ping_sweep(range_ip, outdir):
    """Performs a ping sweep on the given IP range and writes live hosts to a file."""
    create_directory(outdir)
    outfile = os.path.join(outdir, "targets.txt")
    res = 0

    with open(outfile, 'w') as f:
        print(f"\n[+] Performing ping sweep over {range_ip}")
        sweep_cmd = f"nmap -n -sn {range_ip}"
        results = subprocess.check_output(sweep_cmd, shell=True).decode('utf-8')
        
        for line in results.splitlines():
            line = line.strip()
            if "Nmap scan report for" in line:
                ip_address = line.split(" ")[-1]
                host_dir = os.path.join(outdir, ip_address)
                create_directory(host_dir)
                
                if res > 0:
                    f.write('\n')
                f.write(ip_address)
                
                print(f"[*] {ip_address}")
                res += 1

    print(f"\n[*] Found {res} live hosts")
    print(f"[*] Created target list: {outfile}")
    print(f"[*] Run mix_port_scan.sh -t {outfile} -p all\n")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: script.py <IP_RANGE> <OUTPUT_DIRECTORY>")
        sys.exit(1)

    ip_range = sys.argv[1].strip()
    output_directory = sys.argv[2].strip()
    ping_sweep(ip_range, output_directory)

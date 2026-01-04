import argparse

from scapy.all import ARP, Ether, sendp  # type: ignore


def main() -> int:
    parser = argparse.ArgumentParser(description="Send a single L2 ARP request out of a TAP interface.")
    parser.add_argument("--iface", default="tapa", help="Interface to send on (e.g., tapa)")
    parser.add_argument("--target-ip", default="192.168.2.99", help="ARP query target IP")
    args = parser.parse_args()

    pkt = Ether(dst="ff:ff:ff:ff:ff:ff") / ARP(op=1, pdst=args.target_ip)
    sendp(pkt, iface=args.iface, verbose=False)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

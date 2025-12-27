from scapy.all import Ether, ARP, sendp

pkt = Ether(dst="ff:ff:ff:ff:ff:ff") / ARP(op=1, dst="192.168.2.99")
sendp(pkt, iface="tapa", verbose=False)

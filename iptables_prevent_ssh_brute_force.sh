#!/bin/bash
# allow vpn and vpc ranges
#iptables -I INPUT -i eth0 -s trusted_ip/32 -j ACCEPT
# TCP packets are going to come in, that will attempt to establish an SSH connection.  Mark them as SSH.  Pay attention to the source of the packet.
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -m state --state NEW -m recent --set --name SSH --rsource
# If a packet attempting to establish an SSH connection comes, and it's the fourth packet to come from the same source in twenty seconds, just reject it with prejudice and stop thinking about it.
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -m recent --rcheck --seconds 20 --hitcount 4 --rttl --name SSH --rsource -j REJECT --reject-with tcp-reset
# If an SSH connection packet comes in, and it's the third attempt from the same guy in twenty seconds, log it to the system log once, then immediately reject it and forget about it.
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -m recent --rcheck --seconds 20 --hitcount 3 --rttl --name SSH --rsource -j LOG --log-prefix "SSH brute force "
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -m recent --update --seconds 20 --hitcount 3 --rttl --name SSH --rsource -j REJECT --reject-with tcp-reset
# Any SSH packet not stopped so far, just accept it.
iptables -A INPUT -i eth0 -p tcp -m tcp --dport 22 -j ACCEPT

# source:
# https://rudd-o.com/linux-and-free-software/a-better-way-to-block-brute-force-attacks-on-your-ssh-server
# https://www.rackaid.com/blog/how-to-block-ssh-brute-force-attacks/
# https://www.digitalsanctuary.com/debian/using-iptables-to-prevent-ssh-brute-force-attacks.html

#!/bin/bash
WAN=eth0
TUN=tun0

iptables -t filter -F INPUT
iptables -t filter -A INPUT -m state --state INVALID -j DROP
iptables -t filter -A INPUT -i lo -s 127.0.0.1 -d 127.0.0.1 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p udp --sport 67 --dport 68 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p icmp --icmp-type 0 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p udp --sport 53 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p udp --sport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 22 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 443 -m state --state ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 22 -m state --state NEW -m limit --limit 3/min --limit-burst 3 -j DROP
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 22 -m state --state NEW -m limit --limit 1/min --limit-burst 2 -j ACCEPT
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 443 -m state --state NEW -m limit --limit 3/min --limit-burst 3 -j DROP
iptables -t filter -A INPUT -i ${WAN} -p tcp --dport 443 -m state --state NEW -m limit --limit 1/min --limit-burst 2 -j ACCEPT
iptables -t filter -A INPUT -j DROP

iptables -t filter -F OUTPUT
iptables -t filter -A OUTPUT -o lo -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT
iptables -t filter -A OUTPUT -o ${WAN} -p udp --dport 67 --sport 68 -j ACCEPT
iptables -t filter -A OUTPUT -o ${WAN} -p udp --dport 53 -j ACCEPT
iptables -t filter -A OUTPUT -o ${WAN} -p icmp --icmp-type 8 -j ACCEPT
iptables -t fitler -A OUTPUT -o ${WAN} -p tcp --dport 443 -j ACCEPT
iptables -t filter -A OUTPUT -o ${WAN} -p tcp --sport 22 -j ACCEPT
iptables -t filter -A OUTPUT -o ${WAN} -p tcp --sport 443 -j ACCEPT
iptables -t filter -A OUTPUT -j DROP

iptables -t filter -F FORWARD
iptables -t filter -A FORWARD -i ${WAN} -o ${TUN} -j ACCEPT
iptables -t filter -A FORWARD -i ${TUN} -o ${WAN} -j ACCEPT
iptables -t filter -j DROP

iptables -t mangle -F POSTROUTING

iptables -t nat -F POSTROUTING
iptables -t nat -A POSTROUTING -o ${WAN} -j MASQUERADE


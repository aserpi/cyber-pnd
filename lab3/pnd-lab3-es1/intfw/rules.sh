#!/bin/bash

## Default policies

iptables -P FORWARD DROP
iptables -P INPUT DROP
iptables -P OUTPUT DROP


## Logging
iptables -I FORWARD -j LOG --log-prefix "[netfilter] Forward DROP"
iptables -I INPUT -j LOG --log-level notice --log-prefix "[netfilter] Input DROP"
iptables -I OUTPUT -j LOG --log-level warning --log-prefix "[netfilter] Output DROP"


## DMZ

# FTP server
iptables -I FORWARD -d 100.64.6.3 -p tcp --dport 21 -j ACCEPT
iptables -I FORWARD -s 100.64.6.3 -p tcp --sport 21 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -s 100.64.6.3 -p tcp --sport 20 -j ACCEPT
iptables -I FORWARD -d 100.64.6.3 -p tcp --dport 20 -m state --state ESTABLISHED,RELATED -j ACCEPT

# Web server
iptables -I FORWARD -d 100.64.6.2 ! -s 100.64.0.0/16 -p tcp --dport 80 -j ACCEPT
iptables -I FORWARD -s 100.64.6.2 ! -d 100.64.0.0/16 -p tcp --sport 80 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -d 100.64.6.2 -s 100.64.2.0/24 -p tcp --dport 80 -j ACCEPT
iptables -I FORWARD -s 100.64.6.2 -d 100.64.2.0/24 -p tcp --sport 80 -m state --state ESTABLISHED,RELATED -j ACCEPT


## Internal network

# Client network
iptables -I FORWARD -s 100.64.2.0/24 ! -d 100.64.0.0/16 -j ACCEPT
iptables -I FORWARD -d 100.64.2.0/24 ! -s 100.64.0.0/16 -m state --state ESTABLISHED,RELATED -j ACCEPT

# DNS server
iptables -I FORWARD -d 100.64.1.2 -s 100.64.0.0/16 -p udp --dport 53 -j ACCEPT
iptables -I FORWARD -s 100.64.1.2 -d 100.64.0.0/16 -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -s 100.64.1.2 -p udp --dport 53 -j ACCEPT
iptables -I FORWARD -d 100.64.1.2 -p udp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I FORWARD -s 100.64.1.2 -p tcp --dport 53 -j ACCEPT
iptables -I FORWARD -d 100.64.1.2 -p tcp --sport 53 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I INPUT -s 100.64.1.2 -p udp --sport 53 -j ACCEPT
iptables -I OUTPUT -d 100.64.1.2 -p udp --dport 53 -j ACCEPT

# Log server
iptables -I FORWARD -d 100.64.1.3 -s 100.64.0.0/16 -p udp --dport 514 -j ACCEPT
iptables -I OUTPUT -d 100.64.1.3 -p udp --dport 514 -j ACCEPT


## SSH

iptables -I FORWARD -s 100.64.2.0/24 -p tcp --dport 22 -j ACCEPT
iptables -I FORWARD -d 100.64.2.0/24 -p tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -I INPUT -s 100.64.2.0/24 -p tcp --dport 22 -j ACCEPT
iptables -I OUTPUT -d 100.64.2.0/24 -p tcp --sport 22 -m state --state ESTABLISHED,RELATED -j ACCEPT


## Spoofing

iptables -I FORWARD -i eth0 -s 100.64.1.0/24,100.64.2.0/24,100.64.254.2 -j DROP
iptables -I INPUT -i eth0 -s 100.64.1.0/24,100.64.2.0/24 -j DROP
iptables -I FORWARD -i eth1 ! -s 100.64.1.0/24 -j DROP
iptables -I INPUT -i eth1 ! -s 100.64.1.0/24 -j DROP
iptables -I FORWARD -i eth2 ! -s 100.64.2.0/24 -j DROP
iptables -I INPUT -i eth2 ! -s 100.64.2.0/24 -j DROP

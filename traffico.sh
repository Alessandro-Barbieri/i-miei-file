#!/bin/sh 

### BEGIN INIT INFO
# Provides:          traffico
# Required-Start:    $local_fs $network
# Required-Stop:     $local_fs
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
### END INIT INFO

## Paths and definitions
tc=/sbin/tc
ext=eth0		# Change for your device!
ext_ingress=ifb0	# Use a unique ifb per rate limiter!
			# Set these as per your provider's settings, at 90% to start with
#2527 478
#2350 440
maxs=252kbit #2527kbit
maxc=478kbit

ext_up=352kbit		# Max theoretical: for this example, up is 1024kbit
ext_down=1880kbit	# Max theoretical: for this example, down is 8192kbit

q=1514                  # HTB Quantum = 1500bytes IP + 14 bytes ethernet.
			# Higher bandwidths may require a higher htb quantum. MEASURE.
			# Some ADSL devices might require a stab setting.

quantum=300		# fq_codel quantum 300 gives a boost to interactive flows
			# At higher bandwidths (50Mbit+) don't bother


modprobe ifb
modprobe sch_fq_codel
modprobe act_mirred

ethtool -K $ext tso off gso off gro off # Also turn of gro on ALL interfaces 
                                        # e.g ethtool -K eth1 gro off if you have eth1
					# some devices you may need to run these 
					# commands independently

# Clear old queuing disciplines (qdisc) on the interfaces
$tc qdisc del dev $ext root
$tc qdisc del dev $ext ingress
$tc qdisc del dev $ext_ingress root
$tc qdisc del dev $ext_ingress ingress

if [ "$1" = "stop" ]
 then
 exit
fi

modemif=ext

iptables -t mangle -N ack
iptables -t mangle -A ack -m tos ! --tos Normal-Service -j RETURN
iptables -t mangle -A ack -p tcp -m length --length 0:128 -j TOS --set-tos Minimize-Delay
iptables -t mangle -A ack -p tcp -m length --length 128: -j TOS --set-tos Maximize-Throughput
iptables -t mangle -A ack -j RETURN
 
iptables -t mangle -A POSTROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK ACK -j ack

iptables -t mangle -N tosfix
iptables -t mangle -A tosfix -p tcp -m length --length 0:512 -j RETURN
#allow screen redraws under interactive SSH sessions to be fast:
iptables -t mangle -A tosfix -m hashlimit --hashlimit 20/sec --hashlimit-burst 20 \
--hashlimit-mode srcip,srcport,dstip,dstport --hashlimit-name minlat -j RETURN
iptables -t mangle -A tosfix -j TOS --set-tos Maximize-Throughput
iptables -t mangle -A tosfix -j RETURN
 
iptables -t mangle -A POSTROUTING -p tcp -m tos --tos Minimize-Delay -j tosfix

iptables -t mangle -A POSTROUTING -o $modemif -p tcp -m tos --tos Minimize-Delay -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 53 -j CLASSIFY --set-class 1:11
#iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 80 -j CLASSIFY --set-class 1:11
#iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 443 -j CLASSIFY --set-class 1:11

iptables -t mangle -A POSTROUTING -o $modemif -p udp --dport 5000:5500 -j CLASSIFY --set-class 1:11

iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 8088 -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p udp --dport 8088 -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 2099 -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 5233 -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p tcp --dport 3724 -j CLASSIFY --set-class 1:11
iptables -t mangle -A POSTROUTING -o $modemif -p udp --dport 3724 -j CLASSIFY --set-class 1:11

iptables -t mangle -A PREROUTING -p icmp -j TOS --set-tos Minimize-Delay
iptables -t mangle -A PREROUTING -p icmp -j RETURN

iptables -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j TOS --set-tos Minimize-Delay
iptables -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN


#########
# INGRESS
#########

# Create ingress on external interface
$tc qdisc add dev $ext handle ffff: ingress 

ifconfig $ext_ingress up # if the interace is not up bad things happen

# Forward all ingress traffic to the IFB device
$tc filter add dev $ext parent ffff: protocol all u32 match u32 0 0 action mirred egress redirect dev $ext_ingress

# Create an EGRESS filter on the IFB device
$tc qdisc add dev $ext_ingress root handle 1: htb default 11

# Add root class HTB with rate limiting

$tc class add dev $ext_ingress parent 1: classid 1:1 htb rate $ext_down burst $maxs
$tc class add dev $ext_ingress parent 1:1 classid 1:11 htb rate $ext_down prio 0 quantum $q burst $maxs

tc class add dev $ext_ingress parent 1:1 classid 1:12 htb rate 10000000kbit prio 0 quantum $q burst $maxs

tc filter add dev $ext_ingress protocol ip parent 1: u32 match ip protocol 0x11 0xff flowid 1:11 

tc filter add dev $ext_ingress protocol ip parent 1: u32 match ip src 192.168.0.0/24 flowid 1:12 


# Add FQ_CODEL qdisc with ECN support (if you want ecn)
$tc qdisc add dev $ext_ingress parent 1:11 fq_codel quantum $quantum ecn

#########
# EGRESS
#########
# Add FQ_CODEL to EGRESS on external interface
$tc qdisc add dev $ext root handle 1: htb default 11 

# Add root class HTB with rate limiting
$tc class add dev $ext parent 1: classid 1:1 htb rate $ext_up burst $maxc
$tc class add dev $ext parent 1:1 classid 1:11 htb rate $ext_up prio 0 quantum $q burst $maxc

tc class add dev $ext parent 1:1 classid 1:12 htb rate 10000000kbit prio 0 quantum $q burst $maxc
tc filter add dev $ext protocol ip parent 1: u32 match ip dst 192.168.0.0/24 flowid 1:12

# Note: You can apply a packet limit here and on ingress if you are memory constrained - e.g
# for low bandwidths and machines with < 64MB of ram, limit 1000 is good, otherwise no point

# Add FQ_CODEL qdisc without ECN support - on egress it's generally better to just drop the packet
# but feel free to enable it if you want.

$tc qdisc add dev $ext parent 1:11 fq_codel quantum $quantum noecn 


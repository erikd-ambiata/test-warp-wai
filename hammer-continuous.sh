#!/bin/bash

clear
echo "Running ..."

output=/tmp/hammer-continuous-$$.txt

port=2000
count=0

while /bin/true ; do
	wget --quiet --header "Connection: close" "http://localhost:${port}/" -O ${output}
	if test $? -eq 4 ; then
		echo "Wget connection fail. Exiting."
		echo
		exit 1
		fi
	if test $(grep -c Warp ${output}) -gt 0 ; then
		cat ${output}
		echo
		hexdump -C ${output}
		exit 1
		fi
	done

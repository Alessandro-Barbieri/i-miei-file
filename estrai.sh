#!/bin/bash
for cartella in */
do
	for file in $cartella/*.raf
	do
		~/raf.sh $file ~/Scrivania/temp
	done	
done

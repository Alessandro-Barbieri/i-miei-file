#!/bin/bash
ping -n -c 1 80.91.245.243 | grep time= | cut -d ' ' -f7 | cut -d = -f2

#!/bin/bash

for (( mass=200; mass<=6000; mass+=200 ))
do
#   echo "$mass GeV "
  ./wpwidth.exe $mass | awk '{print $2 "  "   $4 }'

done

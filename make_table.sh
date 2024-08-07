#!/bin/bash

echo -e "\n### Table of Hardware\n"

cat toh.yml | yq \
'.devices[] | ""
+","+.device_type
+","+.brand
+","+.model
+","+(.status)
+","+(.soc.name)
+","+(.sensor.name)
+","+(.wifi.name)
+","+(.flash_mb // "" | tostring)
+","+(.soc.cpu_clock_mhz // "" | tostring)
+","+(.soc.ram_mb // "" | tostring)
+","+(.ethernet // "" | tostring)
+","+.wifi.w2g
+","+.data_transfer
+","+.sensor.resolution
+","+.power
+","+(.last_price_w_ship // "" | tostring)
+","+""
' \
| tr -d '"' | column -t -s',' -o ' | ' --table-columns \
" ,type,brand,model,status,soc,sensor,wifi,flash MB,CPU MHz,RAM MB,ethernet,wifi,data,resolution,power,price,"

yq '.devices | del(.template)' toh.yml > toh.json


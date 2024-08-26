#!/bin/bash

function addCam() {
	cam_file=$1

	cam=$(basename $cam_file)
	env_file="$repo_dir/$(cat ${cam_file} | fgrep U_BOOT_ENV_TXT | cut -d/ -f2- | cut -d'"' -f1)"

	status=$(echo ${cam} | grep -q '^exp_' && echo wip || echo supported)
	cam=$(echo ${cam} | sed 's/^exp_//')

	device_type=TBD
	brand=$(echo ${cam} | cut -d_ -f1)
	model=$(echo ${cam} | cut -d_ -f2)
	flash_mb=$(cat ${cam_file} | grep -o '^FLASH_SIZE_[0-9]*=y' | sed 's~^.*_\([0-9]*\)=.*$~\1~')
	soc=$(cat ${cam_file} | grep 'MODULE:' | grep -io 't.*_.*_[-0-9A-Z]*' | tr '[:lower:]' '[:upper:]' | cut -d_ -f1)
	sensor=$(cat ${cam_file} | grep 'MODULE:' | grep -io 't.*_.*_[-0-9A-Z]*' | tr '[:lower:]' '[:upper:]' | cut -d_ -f2)
	wifi=$(cat ${cam_file} | grep 'MODULE:' | grep -io 't.*_.*_[-0-9A-Z]*' | tr '[:lower:]' '[:upper:]' | cut -d_ -f3)
	ethernet=$(cat ${env_file} | fgrep -q 'disable_eth=true' && echo false || echo true)
	sd_card=$(cat ${cam_file} | fgrep -q 'BR2_SDCARD=y' && echo true || echo false)
	pan_tilt=$(cat ${cam_file} | fgrep -q 'BR2_MOTORS=y' && echo true || echo false)
	mic=$(cat ${cam_file} | fgrep -q 'BR2_AUDIO=y' && echo true || echo false)
	speaker=$(cat ${env_file} | fgrep -q 'gpio_speaker=' && echo true || echo false)
	ir_cut=$(cat ${env_file} | fgrep -q 'gpio_ircut=' && echo true || echo false)
	ir_850=$(cat ${env_file} | fgrep -q 'gpio_ir850=' && echo true || echo false)
	ir_940=$(cat ${env_file} | fgrep -q 'gpio_ir940=' && echo true || echo false)

	eval "echo \"$(cat device_tpl.yml)\"" >> tmp_devices.yml

}

function addCams() {
	cam_dir=$1

	cams="$(ls -1 ${cam_dir}/)"
	for cam in $cams
	do
		echo "[D] adding cam: " $cam >&2
		cam_file="${cam_dir}/${cam}"
		addCam ${cam_file}
	done
}

# generate list from repo

echo Cloning repo ...
git clone https://github.com/themactep/thingino-firmware.git tmp 2>/dev/null
git -C tmp pull || exit
echo

repo_dir="tmp"
cdir="${repo_dir}/configs/cameras"

echo -e "devices:\n" > tmp_devices.yml

addCams "${repo_dir}/configs/cameras"
echo

addCams "${repo_dir}/configs/testing"
echo


# check for dangling entries and missing data

keys="$(yq -r '.devices | keys[]' tmp_devices.yml)"
for key in $keys
do
	yq -e ".devices.${key}" devices.yml &>/dev/null && true || echo "[I] $key is missing product information" >&2
done
echo

keys="$(yq -r '.devices | keys[]' devices.yml)"
for key in $keys
do
	yq -e ".devices.${key}" tmp_devices.yml &>/dev/null && true || echo "[W] $key missing in auto generated list" >&2
done
echo


# merge, fix links and export json

cat components.yml > toh.yml
yq -s -y --yml-out-ver 1.2 '.[0] * .[1]' <(yq . tmp_devices.yml) <(yq . devices.yml) >> toh.yml

sed -i "/'\*/s~'~~g" toh.yml


yq '.devices | del(.template)' toh.yml > toh.json





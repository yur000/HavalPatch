#!/bin/sh
if [ ! -d "/pps/foryou/androidauto" ]; then
        mkdir /pps/foryou/androidauto;
fi
#hfp = "$(cat /pps/services/bluetooth/services | grep hfp:: | gawk -F:: '{ print $2 }')"
#echo 'fybt_setting:json:{"bt":"on","autoanswer":"off","autoconnect":"off"}'>> /pps/foryou/setting/bt_control
#echo "command::disconnect_all\ndata::"${hfp}"">>/pps/services/bluetooth/control
#echo 'a2dp_avrcp::close' >> /pps/services/bluetooth/settings

on -p 60r -d mm-aoa --maker GWM --model CHB027 --year 2019 --humaker FORYOU --humodel RN6RE3 --huswbuild 20181113 --huswversion V1.01.02-20181113 --vwidth 1280 --vheight 720 --maxfps 30 --wwidth 1280 --wheight 720 --pixelAspectRatio 10000,10667,10000 --density 240,160,240 --logfile /dev/shmem/aoa.log

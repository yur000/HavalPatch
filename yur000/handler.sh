#!/bin/sh

saveParams(){
	mount -uw /base
	echo BACKLIGHT_TIMEOUT=$BACKLIGHT_TIMEOUT > $WORKING_DIR/config
	echo BACKLIGHT_MODE=$BACKLIGHT_MODE >> $WORKING_DIR/config
	echo KEY_MODE=$KEY_MODE >> $WORKING_DIR/config
	echo LOUD=$LOUD >> $WORKING_DIR/config
	echo CAMERA_SOUND=$CAMERA_SOUND >> $WORKING_DIR/config
	echo CAMERA_VOLDOWN=$CAMERA_VOLDOWN >> $WORKING_DIR/config
	echo AOA_MAKET=$AOA_MAKET >> $WORKING_DIR/config
	echo REBOOT_NEEDED=$REBOOT_NEEDED >> $WORKING_DIR/config
	echo PHONE_RECONNECT=$PHONE_RECONNECT >> $WORKING_DIR/config
	echo ASR_BUTTON=$ASR_BUTTON >> $WORKING_DIR/config
	echo CURRENT_SETTING=$CURRENT_SETTING >> $WORKING_DIR/config
	#sync
}

initParams(){
	mount -uw /base
	echo BACKLIGHT_TIMEOUT=0 > $WORKING_DIR/config
	echo BACKLIGHT_MODE=0 >> $WORKING_DIR/config # 0 - Timeout operating | 1 - On/Off display
	echo KEY_MODE=1 >> $WORKING_DIR/config  # 0 - Normal operating | 1 - Extended
	echo LOUD=0 >> $WORKING_DIR/config
	echo CAMERA_SOUND=1 >> $WORKING_DIR/config
	echo CAMERA_VOLDOWN=0 >> $WORKING_DIR/config
	echo AOA_MAKET=2 >> $WORKING_DIR/config
	echo REBOOT_NEEDED=0 >> $WORKING_DIR/config
	echo PHONE_RECONNECT=0 >> $WORKING_DIR/config
	echo ASR_BUTTON=1 >> $WORKING_DIR/config
	echo CURRENT_SETTING=0 >> $WORKING_DIR/config
}

printParams(){
	cat $WORKING_DIR/config
}

postSettingCheck(){
	CURRENT_SETTING=0
	slay -9 wave	
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/setting_saved.wav
	if [ $REBOOT_NEEDED -eq 1 ]; then
		PHONE_RECONNECT=0
		REBOOT_NEEDED=0
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/reboot_needed.wav
		saveParams;
		echo 'fykey:json:{"key":5,"src":"wheel","status":"dn","param":0}' >> /pps/foryou/system/key #send mute
		/scripts/reboot
	fi
	if [ $PHONE_RECONNECT -eq 1 ]; then
		PHONE_RECONNECT=0
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/phone_reconnect_needed.wav
	fi
}

changeBacklightTimeout() {
	if [ $BACKLIGHT_MODE -eq 0 ]; then
		BACKLIGHT_TIMEOUT=$((BACKLIGHT_TIMEOUT+30));
		if [ $BACKLIGHT_TIMEOUT -gt 120 ]; then
			BACKLIGHT_TIMEOUT=0;
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/Speech_Off.wav &
		fi
		echo fyblackout::$BACKLIGHT_TIMEOUT >> /pps/foryou/setting/tft_control #+send to system new value
		echo 'fytime:json:{"hour":61,"minute":'$BACKLIGHT_TIMEOUT',"clock_mode":0}' >> /pps/foryou/setting/time_status
		saveParams;
	else
		if [ ! $BACKLIGHT_TIMEOUT -eq 0 ]; then
			BACKLIGHT_TIMEOUT=0;
			echo fyblackout::$BACKLIGHT_TIMEOUT >> /pps/foryou/setting/tft_control #+send to system reseted
			saveParams;
		fi
		echo 'fykey:json:{"key":157,"src":"ccp","status":"dn","param":0}' >> /pps/foryou/system/key
	fi
}

switchBacklightMode(){
	if [ $BACKLIGHT_MODE -eq 0 ]; then
		BACKLIGHT_MODE=1
	else
		BACKLIGHT_MODE=0
	fi
	saveParams;
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/Windows_Notify.wav &
}

switchKeymode(){
	if [ $KEY_MODE -eq 2 ]; then
		KEY_MODE=0
		postSettingCheck;
	fi
	if [ $KEY_MODE -eq 1 ]; then
		KEY_MODE=0
	else
		KEY_MODE=$((KEY_MODE+1));
	fi
	saveParams;
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/Windows_Notify.wav &
}

switchSettings(){
	if [ ! $KEY_MODE -eq 2 ]; then
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/settings.wav 
		KEY_MODE=2
		settingModeSpeech;
	else
		KEY_MODE=0
		postSettingCheck;
		saveParams;
	fi
}

handleMenuOnPanel(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":214,"src":"panel","status":"dn","param":0}' >> /pps/foryou/system/key  ;;
		"1") switchSettings;;
		"2") if [ $ASR_BUTTON -eq 1 ]; then switchSettings; else settingSwitch; fi ;;
	esac
}

handleKnobL(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":86,"src":"knob","status":"null","param":0}' >> /pps/foryou/system/key  ;;
		"1") echo 'fyvolume::-1' >> /pps/foryou/eq/control ;;
		#"2") settingModeSpeech ;;
	esac
}

handleKnobR(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":85,"src":"knob","status":"null","param":0}' >> /pps/foryou/system/key  ;;
		"1") echo 'fyvolume::1' >> /pps/foryou/eq/control ;;
		"2") settingModeSpeech ;;
	esac
}

handleKeyL(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":208,"src":"ccp","status":"dn","param":0}' >> /pps/foryou/system/key  ;;
		"1") echo 'fykey:json:{"key":21,"src":"wheel","status":"dn","param":0}' >> /pps/foryou/system/key  ;
			 echo 'fykey:json:{"key":21,"src":"wheel","status":"up","param":0}' >> /pps/foryou/system/key  ;;
	esac
}

handleKeyR(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":209,"src":"ccp","status":"dn","param":0}' >> /pps/foryou/system/key  ;;
		"1") echo 'fykey:json:{"key":20,"src":"wheel","status":"dn","param":0}' >> /pps/foryou/system/key ;
			 echo 'fykey:json:{"key":20,"src":"wheel","status":"up","param":0}' >> /pps/foryou/system/key  ;;
	esac
}

handleKnobEnter(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":97,"src":"ccp","status":"dn","param":0}' >> /pps/foryou/system/key ;
		     echo 'fykey:json:{"key":97,"src":"ccp","status":"up","param":0}' >> /pps/foryou/system/key ;;
		"1") echo 'fykey:json:{"key":212,"src":"ccp","status":"dn","param":0}' >> /pps/foryou/system/key ;;
		"2") settingSwitch ;;
	esac
}

handleMute(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":3,"src":"wheel","status":"up","param":0}' >> /pps/foryou/system/key ;;
		"1") echo 'fykey:json:{"key":5,"src":"wheel","status":"dn","param":0}' >> /pps/foryou/system/key;;
		"2") settingModeSpeech ;;
	esac
}

handleASR(){
	case $KEY_MODE in
		"0") echo 'fykey:json:{"key":215,"src":"wheel","status":"dn","param":0}'  >> /pps/foryou/system/key ;
			 echo 'fykey:json:{"key":215,"src":"wheel","status":"up","param":0}'  >> /pps/foryou/system/key ;;
		"1") changeBacklightTimeout ;;
		"2") settingSwitch ;;
	esac
}

switchLoud(){
	if [ $LOUD -eq 1 ]; then
		echo fyloud::off >> /pps/foryou/eq/control
		LOUD=0
	else
		echo fyloud::on >> /pps/foryou/eq/control
		LOUD=1
	fi
	saveParams;
}

getCameraVol(){
	case $CAMERA_VOLDOWN in
		"0") SOUND=off.wav ;;
		"1") SOUND=on.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/camsound_min.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &
}

setCameraVol(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	if [ $CAMERA_VOLDOWN -eq 0 ]; then
		CAMERA_VOLDOWN=1
		/base/scripts/yur000/reverseHandler.sh &
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/on.wav
	else
		REVERSE_PID=$( ps -Ao pid,args | grep [r]everseHa | awk '{ printf $1 }' )
		CAMERA_VOLDOWN=0
		slay -9 $REVERSE_PID
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/off.wav
	fi
}

getCameraSound(){
	case $CAMERA_SOUND in
		"0") SOUND=off.wav ;;
		"1") SOUND=on.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/camera_sound.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &
}

setCameraSound(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	if [ $CAMERA_SOUND -eq 0 ]; then
		CAMERA_SOUND=1
		echo 'fyreverse_sound::on' >> /pps/foryou/setting/general_control
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/on.wav
	else
		CAMERA_SOUND=0
		echo 'fyreverse_sound::off' >> /pps/foryou/setting/general_control
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/off.wav
	fi
	slay -9 AppManager
}

getLowBoost(){
	case $LOUD in
		"0") SOUND=off.wav ;;
		"1") SOUND=on.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/low_freq_boost.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &

}

setLowBoost(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	if [ $LOUD -eq 0 ]; then
		LOUD=1
		echo fyloud::on >> /pps/foryou/eq/control
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/on.wav
	else
		LOUD=0
		echo fyloud::off >> /pps/foryou/eq/control
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/off.wav
	fi
}

getAOAMaket(){
	case $AOA_MAKET in
		"0") SOUND=stock.wav ;;
		"1") SOUND=medium.wav ;;
		"2") SOUND=big.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/aoa_maket.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &
}

setAOAMaket(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	case $AOA_MAKET in
		"0")	AOA_MAKET=1;
			cp -rf  $WORKING_DIR/system/aoa_start_medium.sh /base/etc/usblauncher/aoa_start.sh;
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/medium.wav ;;
		"1")	AOA_MAKET=2;
			cp -rf  $WORKING_DIR/system/aoa_start_big.sh /base/etc/usblauncher/aoa_start.sh;
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/big.wav ;;
		"2")	AOA_MAKET=0;
			cp -rf  $WORKING_DIR/system/aoa_start_stock.sh /base/etc/usblauncher/aoa_start.sh;
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/stock.wav ;;
	esac
	chmod +x /base/etc/usblauncher/aoa_start.sh
	PHONE_RECONNECT=1
}

getBacklightMode(){
	case $BACKLIGHT_MODE in
		"1") SOUND=off.wav ;;
		"0") SOUND=on.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/backlight_mode.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &
}

setBacklightMode(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	if [ $BACKLIGHT_MODE -eq 0 ]; then
		BACKLIGHT_MODE=1
		echo fyblackout::0 >> /pps/foryou/setting/tft_control #+send to system reseted
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/off.wav
	else
		BACKLIGHT_MODE=0
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/on.wav
	fi
}

getASRButtonMode(){
	case $ASR_BUTTON in
		"0") SOUND=stock.wav ;;
		"1") SOUND=backl_trigger.wav ;;
	esac
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/asr_button.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/curr_val.wav &&
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/$SOUND &

}

setASRButtonMode(){
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/param_changed.wav
	if [ $ASR_BUTTON -eq 0 ]; then
		ASR_BUTTON=1
		cp -f $WORKING_DIR/system/keymap_backlight /base/var/pps/foryou/appmanager/keymap
		cp -f $WORKING_DIR/system/keycompound_backlight /base/var/pps/foryou/appmanager/keycompound
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/backl_trigger.wav
	else
		ASR_BUTTON=0
		cp -f $WORKING_DIR/system/keymap_asr /base/var/pps/foryou/appmanager/keymap
		cp -f $WORKING_DIR/system/keycompound_asr /base/var/pps/foryou/appmanager/keycompound
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/stock.wav
	fi
	slay -9 AppManager
}

processUpdate(){
	if [ -e /fs/usb0/patch.update ]; then
		wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/update_found.wav
		mkdir /tmp/patch_updater
		openssl aes-128-cbc -d -pass pass:UpdaAteHhanddelr -in /fs/usb0/patch.update -out /tmp/patch_update.tar
		if [ $? -eq 0 ]; then
			tar -C "/tmp/patch_updater" -xvf /tmp/patch_update.tar
			chmod +x /tmp/patch_updater/update.sh
			/tmp/patch_updater/update.sh
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/update_done.wav
		else 
			wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/update_failed.wav
		fi
		rm -rf /tmp/patch_update.tar
		rm -rf /tmp/patch_updater/
		rm -rf /fs/usb0/patch.update
	fi
}

settingModeSpeech(){
	if [ $CURRENT_SETTING -eq 6 ]; then
		CURRENT_SETTING=0
	fi
	if [ $CURRENT_SETTING -eq 0 ]; then
		processUpdate
	fi
	CURRENT_SETTING=$((CURRENT_SETTING+1));
	[ $CURRENT_SETTING -eq 1 ] && [ $CAMERA_SOUND -eq 0 ] && CURRENT_SETTING=$((CURRENT_SETTING+1));
	
	slay -9 wave
	
	case $CURRENT_SETTING in
		"1") getCameraVol ;;
		"2") getCameraSound ;;
		"3") getBacklightMode ;;
		"4") getLowBoost ;;
		"5") getAOAMaket ;;
		"6") getASRButtonMode ;;
	esac
	saveParams;
}

settingSwitch(){
	slay -9 wave
	case $CURRENT_SETTING in
		"1") setCameraVol ;;
		"2") setCameraSound ;;
		"3") setBacklightMode ;;
		"4") setLowBoost ;;
		"5") setAOAMaket ;;
		"6") setASRButtonMode ;;
	esac
	saveParams;
}

initMods(){
	echo 'fyvolume::-40' >> /pps/foryou/eq/control
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/first_welcome.wav
	cp -rf  $WORKING_DIR/system/aoa_start_big.sh /base/etc/usblauncher/aoa_start.sh
	chmod +x /base/etc/usblauncher/aoa_start.sh
	echo 'fyreverse_sound::on' >> /pps/foryou/setting/general_control
	sleep 1
	wave -a /dev/snd/pcmNavigation  $WORKING_DIR/sound/first_welcome_reboot.wav
	echo 'fykey:json:{"key":5,"src":"wheel","status":"dn","param":0}' >> /pps/foryou/system/key #send mute
	/scripts/reboot
}

startUp(){
	if [ $KEY_MODE -eq 2 ]; then
		KEY_MODE=1
		saveParams;
	fi
	if [ $CAMERA_SOUND -eq 1 ]; then
		if [ $(cat /pps/foryou/setting/general_status | grep fyreverse_sound |  sed 's/.*fyreverse_sound::\{0,1\}\([^,"]*\)\{0,1\}.*/\1/') == "off" ]; then
			echo 'fyreverse_sound::on' >> /pps/foryou/setting/general_control
			#slay -9 AppManager
		fi
	fi	
	if [ $CAMERA_VOLDOWN -eq 1 ]; then
		/base/scripts/yur000/reverseHandler.sh &
	fi
}

WORKING_DIR=/scripts/yur000

running=/dev/shmem/yur000-handler.run
[ -e $running ] && exit
touch $running

if [ ! -f $WORKING_DIR/config ]; then
	initParams;
	initMods;
fi
. $WORKING_DIR/config

case "$1" in
	"switchMode") switchKeymode;;
	"backlight") changeBacklightTimeout;;
	"backlightMode") switchBacklightMode;;
	"knobLeft") handleKnobL;;
	"keyLeft") handleKeyL;;
	"knobRight") handleKnobR;;
	"keyRight") handleKeyR;;
	"knobEnter") handleKnobEnter;;
	"menuOnWheel") handleMute;;
	"menuOnPanel") handleMenuOnPanel;;
	"switchLoud") switchLoud;;
	"enterSettings") switchSettings;;
	"keyASR") handleASR;;
	"init") startUp;;
esac

rm -f $running

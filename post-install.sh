#!/usr/bin/env bash
################################################################################
## Created by  BigRush
#
## Post installation script
################################################################################


Log_Variables () {

	####  Varibale	################################################################

	line="------------------------------------------"

	errorlog="error.log"
	outputlog="output.log"

	logfolder="/var/log/post_install"

	errorpath=$logfolder/$errorlog
	outputpath=$logfolder/$outputlog

	Distro_Validation="empty"

	if ! [ -e $logfolder ]; then
		mkdir -p $logfolder
	fi
}


####  Functions  ###############################################################

Distro_Check () {		## checking the environment the user is currenttly running on to determine which settings should be applied
	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^manjaro$" &> /dev/null

	if [[ $? -eq 0 ]]; then
	  	Distro_Val="manjaro"
	fi

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^arch$" &> /dev/null

	if [[ $? -eq 0 ]]; then
			Distro_Val="arch"
	fi

  cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^debian$|^\"Ubuntu\"$" &> /dev/null

  if [[ $? -eq 0 ]]; then
    	Distro_Val="debian"
  fi

	cat /etc/*-release |grep ID |cut  -d "=" -f "2" |egrep "^\"centos\"$|^\"fedora\"$" &> /dev/null

	if [[ $? -eq 0 ]]; then
	   	Distro_Val="centos"
	fi
}

Arch_Config () {
	if [[ $Distro_Val == arch ]]; then
		printf "$line\n"
		printf "Updating the system...\n"
		printf "$line\n"
		pacman -Syu --noconfirm 2>> $errorpath >> $outputpath

		if [[ $? -eq 0 ]]; then
			printf "$line\n"
			prinf "Update complete\n"
			printf "$line\n"
		else
			printf "$line\n"
			prinf "Somthing went wrong while updating, please check log:\n$errorpath\n"
			printf "$line\n"
			exit 1
		fi

		printf "$line\n"
		printf "Installing Xorg...\n"
		printf "$line\n"

		pacman -S xorg xorg-xinit --nocomfirm --needed 2>> $errorpath >> $outputpath --noconfirm

		if [[ $? -eq 0 ]]; then
			printf "$line\n"
			printf "Xorg installation complete\n"
			printf "$line\n"

		else
			printf "Somthing went wrong while installing Xorg, please check log:\n$errorpath\n"
			exit 1
		fi

		lspci |grep VGA |grep Intel

		if [[ $? -eq 0 ]]; then
			printf "$line\n"
			printf "Installing video drivers...\n"
			printf "$line\n"

			pacman -S xf86-video-intel --nocomfirm --needed 2>> $errorpath >> $outputpath

			if [[ $? -eq 0 ]]; then
				printf "$line\n"
				printf "Video drivers installation complete"
				printf "$line\n"

			else
				printf "Somthing went wrong while installing video drivers, please check log:\n$errorpath\n"
				exit 1
			fi
		fi

		printf "exec startkde\n" > ~/.xinitrc







}

### update the system and install pacaur #####
Manjaro_Sys_Update ()
{
	## update the system, dump errors to /var/log/post_install_error.log and output to /var/log/post_install_output.log
	pacman -Syu 2>> $errorpath >> $outputpath
	printf $line
	printf "System update complete\n"
	printf $line
}

## set desktop theme
xfce_theme ()
{
	wget -O /home/tom/Pictures/archbk.jpg http://getwallpapers.com/wallpaper/full/f/2/a/1056675-download-free-arch-linux-wallpaper-1920x1080.jpg 2>> $errorpath >> $outputpath
	xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "/home/tom/Pictures/archbk.jpg" 2>> $errorpath >> $outputpath
	xfconf-query --channel "xfce4-panel" --property '/panels/panel-1/size' --type int --set 49
	xfconf-query --channel "xfce4-panel" --property '/panels/panel-1/background-alpha' --type int --set 0
	xfconf-query --channel 'xfce4-keyboard-shortcuts' --property '/commands/custom/<Super>t' --type string --set xfce4-terminal --create
	xfconf-query --channel 'xfce4-keyboard-shortcuts' --property '/commands/custom/grave' --type string --set "xfce4-terminal --drop-down" --create
}
## config the grub backgroung and fast boot
Grub_Config ()
{
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=0/' /etc/default/grub ;;
sed -i 's/#GRUB_HIDDEN_TIMEOUT=1/GRUB_HIDDEN_TIMEOUT=1/' /etc/default/grub ;;
sed -i 's/#GRUB_HIDDEN_TIMEOUT_QUIET=true/GRUB_HIDDEN_TIMEOUT_QUIET=true/' /etc/default/grub ;;

update-grub

}


## application's pre-install requirements
App_Req ()
{
	gpg --recv-keys 0FC3042E345AD05D 2>> $errorpath >> $outputpath		## discord key
	return 0
}

## application i want to install with pacaur
Manjaro_application ()
{
		if [[ $Distro_Validation =~ ^manjaro$ ]] ;then
			## install pacaur, dump errors to /var/log/post_install_error.log and output to /var/log/post_install_output.log
			pacman -S pacaur --noconfirm --needed 2>> $errorpath >> $outputpath
			printf $line
			print "Pacaur download complete"
			printf $line

			return 0

			if [[ $? -eq 0 ]] ;then
				app=(ncdu git steam-native-runtime openssh vlc atom discord screenfetch)
				for i in ${app[*]} ;do
					runuser -l tom -c 'pacaur -S $i --noconfirm --needed --noedit 2>> $errorpath >> $outputpath'
				done
				return 0
			else
				prinf $line
				printf "Pacaur installation failed"
				prinf $line
			fi
		else
			continue
		fi
}

## virtualbox installation
Vbox_Installation ()
{
	vb=(virtualbox linux97-virtualbox-host-modules virtualbox-guest-iso virtualbox-ext-vnc virtualbox-ext-oracle)
	for i in ${vb[*]} ;do
		runuser -l tom -c 'pacaur -S $i --noconfirm --needed --noedit'
	done
	modprobe vboxdrv
	gpasswd -a tom vboxusers
}

if [ $UID -ne 0 ] ;then

	printf ""$line"
	printf "You need to be root to run the script\n"
	printf "$line"

	exit 1
else

		update
		sleep 1.5
		grub
		sleep 1.5
		appreq
		sleep 1.5
		application
		sleep 1.5
		virtualbox
fi

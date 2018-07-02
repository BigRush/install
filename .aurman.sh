#!/usr/bin/env bash


################################################################################
# Author :	BigRush
#
# License :	GPLv3
#
# Description :	Update the system
#				Install aurman (AUR helper),
#				Enable multilib repository for pacman
#				Install applications that i want with aurman
#
# Version :	1.0.0
################################################################################

## ToDo	####################################
# Add verbos option
############################################

## Install aurman manually
Aurman_Install () {

	## Propmet the user with what the script will now do (with cosmetics :D)
	printf "$line\n"
	printf "Updating the system...\n"
	printf "$line\n\n"

	## Will be used in Exit_Status function to output text for the user
	output_text="Update"
	error_txt="while updating"

	## Update the system, send stdout and sterr to log files
	sudo pacman -Syu 2>> $errorpath >> $outputpath &
	status=$?
	Progress_Spinner
	Exit_Status

	## Create a tmp-working-dir if it does't exits and navigate into it
	if ! [[ -e $user_path/Automated-Installer-Log/pacaur_install_tmp ]]; then
		mkdir -p $user_path/Automated-Installer-Log/pacaur_install_tmp
	fi

	pushd . 2>> $errorpath >> $outputpath
	cd $user_path/Automated-Installer-Log/pacaur_install_tmp

	## Check if "aurman" exists, if not, install "aurman" from AUR
	if ! [[ -n "$(pacman -Qs aurman)" ]]; then
		output_text="getting aurman with curl from AUR"
		error_txt="while getting aurman with curl from AUR"

		## Get the build files for AUR
    	curl -L -O https://aur.archlinux.org/cgit/aur.git/snapshot/aurman.tar.gz 2>> $errorpath >> $outputpath &
		BPID=$!
		Progress_Spinner
		wait $BPID
		status=$?
		Exit_Status

		tar -xf aurman.tar.gz 2>> $errorpath >> $outputpath

		cd aurman

		output_text="aurman building"
		error_txt="while building aurman"

		## Add gpg key
		gpg --recv-keys 465022E743D71E39 2>> $errorpath >> $outputpath

		## Compile
		makepkg -si PKGBUILD --noconfirm --needed 2>> $errorpath >> $outputpath &
		BPID=$!
		Progress_Spinner
		wait $BPID
		status=$?
		Exit_Status
	fi

	## Clean up on aisle four
	popd 2>> $errorpath >> $outputpath
	rm -rf $user_path/pacaur_install_tmp
}

## Install yay manually
Yay_Install () {

	## Propmet the user with what the script will now do (with cosmetics :D)
	printf "$line\n"
	printf "Updating the system...\n"
	printf "$line\n\n"

	## Will be used in Exit_Status function to output text for the user
	output_text="Update"
	error_txt="while updating"

	## Update the system, send stdout and sterr to log files
	sudo pacman -Syu 2>> $errorpath >> $outputpath &
	status=$?
	Progress_Spinner
	Exit_Status

	## Create a tmp-working-dir if it does't exits and navigate into it
	if ! [[ -e $user_path/Automated-Installer-Log/pacaur_install_tmp ]]; then
		mkdir -p $user_path/Automated-Installer-Log/pacaur_install_tmp
	fi

	pushd . 2>> $errorpath >> $outputpath
	cd $user_path/Automated-Installer-Log/yay_install_tmp

	## Check if "yay" exists, if not, install "yay" from AUR
	if ! [[ -n "$(pacman -Qs yay)" ]]; then
		output_text="getting yay with curl from AUR"
		error_txt="while getting yay with curl from AUR"

		## Get the build files for AUR
    	curl -L -O https://aur.archlinux.org/cgit/aur.git/snapshot/yay.tar.gz 2>> $errorpath >> $outputpath &
		BPID=$!
		Progress_Spinner
		wait $BPID
		status=$?
		Exit_Status

		tar -xf yay.tar.gz 2>> $errorpath >> $outputpath

		cd aurman

		output_text="yay building"
		error_txt="while building yay"

		## Add gpg key
		# gpg --recv-keys 465022E743D71E39 2>> $errorpath >> $outputpath

		## Compile
		makepkg -si PKGBUILD --noconfirm --needed 2>> $errorpath >> $outputpath &
		BPID=$!
		Progress_Spinner
		wait $BPID
		status=$?
		Exit_Status
	fi

	## Clean up on aisle four
	popd 2>> $errorpath >> $outputpath
	rm -rf $user_path/yay_install_tmp
}

## Applications i want to install with pacaur
Aurman_Applications () {
		if [[ $Distro_Val == arch || $Distro_Val == manjaro ]] ;then
			sudo echo
			app=(discord firefox ncdu guake teamviewer openssh vlc atom screenfetch)
			for i in ${app[*]}; do
				printf "$line\n"
				printf "Installing $i\n"
				printf "$line\n\n"
				output_text="$i installation"
				error_txt="while installing $i"
				aurman -S $i --needed --noconfirm --noedit --pgp_fetch 2>> $errorpath >> $outputpath &
				BPID=$!
				Progress_Spinner
				wait $BPID
				status=$?
				Exit_Status
			done

			## special attention packages that out need to be seen
			printf "$line\n"
			printf "Installing steam\n"
			printf "$line\n\n"
			output_text="steam installation"
			error_txt="while installing steam"
			aurman -S steam --needed
			status=$?
			Exit_Status
		fi
}

## Virtualbox installation
Vbox_Installation () {

	read -p "Would you like to install virtualbox?[y/n]: " answer
	printf "\n"
	if [[ -z $answer ]]; then
		:
	elif [[ $answer =~ [y|Y] || $answer =~ [y|Y]es ]]; then
		:
	elif [[ $answer =~ [n|N] || $answer =~ [n|N]o ]]; then
		printf "$line\n"
		printf "Exiting..."
		printf "\n"
		printf "$line\n\n"
		exit 1
	else
		printf "$line\n"
		printf "Invalid answer - exiting\n"
		printf "$line\n\n"
	fi

	vb=(virtualbox linux97-virtualbox-host-modules virtualbox-guest-iso virtualbox-ext-vnc virtualbox-ext-oracle)
	for i in ${vb[*]}; do
		printf "$line\n"
		printf "Installing $i\n"
		printf "$line\n\n"
		output_text="$i installation"
		error_txt="while installing $i"
		aurman -S --needed --noconfirm --noedit $i 2>> $errorpath >> $outputpath &
		status=$?
		Progress_Spinner
		Exit_Status
	done

	sudo modprobe vboxdrv 2>> $errorpath >> $outputpath
	Exit_Status
	sudo gpasswd -a tom vboxusers 2>> $errorpath >> $outputpath
	Exit_Status
}

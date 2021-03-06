#!/usr/bin/env bash


################################################################################
# Author :	BigRush
#
# License :  GPLv3
#
# Description :  Main script that calls the appropriate functions
#                from the other scripts
#
# Version :  2.0.0
################################################################################


## Check if the script doesn't run as root
Non_Root_Check () {
	if [[ $EUID -eq 0 ]]; then
		printf "$line\n"
		printf "This option must run as non-root\n"
		printf "$line\n"
		exit 1
	fi
}

## Check exit status of the last command to see if it completed successfully
Exit_Status () {
	if [[ $status -eq 0 ]]; then
		printf "$line\n"
		printf "$output_text complete...\n"
		printf "$line\n\n"
	else
		printf "$line\n"
		printf "Something went wrong $error_text, please check log under:\n$errorpath\n"
		printf "$line\n\n"

        ## Prompt the user if he want to continue with the script
        ## although the last command failed to execute successfully.
        read -p "Would you like to continue anyway?[y/N]: " answer
        printf "\n"
        if [[ -z $answer ]]; then

			## Prompt the user if he want to read the log files
			read -p "Would you like to read log files?[Y/n]: " answer
	        printf "\n"
	        if [[ -z $answer ]]; then
	            less $errorpath
				exit 1
	        elif [[ $answer =~ [y|Y] || $answer =~ [y|Y]es ]]; then
	            less $errorpath
				exit 1
	        elif [[ $answer =~ [n|N] || $answer =~ [n|N]o ]]; then
	            printf "$line\n"
	            printf "Exiting...\n"
	            printf "$line\n\n"
	            exit 1
	        else
	            printf "$line\n"
	            printf "Invalid answer - exiting\n"
	            printf "$line\n\n"
	            exit 1
			fi

        elif [[ $answer =~ [y|Y] || $answer =~ [y|Y]es ]]; then
			:

        elif [[ $answer =~ [n|N] || $answer =~ [n|N]o ]]; then
			read -p "Would you like to read log files?[Y/n]: " answer
	        printf "\n"
	        if [[ -z $answer ]]; then
	            less $errorpath
	        elif [[ $answer =~ [y|Y] || $answer =~ [y|Y]es ]]; then
	            less $errorpath
	        elif [[ $answer =~ [n|N] || $answer =~ [n|N]o ]]; then
	            printf "$line\n"
	            printf "Exiting...\n"
	            printf "$line\n\n"
	            exit 1
	        else
	            printf "$line\n"
	            printf "Invalid answer - exiting\n"
	            printf "$line\n\n"
	            exit 1
			fi
        else
            printf "$line\n"
            printf "Invalid answer - exiting\n"
            printf "$line\n\n"
            exit 1
		fi
	fi
}

## progress bar that runs while the installation process is running
Progress_Spinner () {

	## Loop until the PID of the last background process is not found
	until [[ -z $(ps aux |awk '{print $2}' |egrep -o "$BPID") ]];do
		## Print text with a spinner
		printf "\r$output_text in progress...  [|]"
		sleep 0.1
		printf "\r$output_text in progress...  [/]"
		sleep 0.1
		printf "\r$output_text in progress...  [-]"
		sleep 0.1
		printf "\r$output_text in progress...  [\\]"
		sleep 0.1
		printf "\r$output_text in progress...  [|]"
	done

	## Print a new line outside the loop so it will not interrupt with the it
	## and will not interrupt with the upcoming text of the script
	printf "\n\n"
}

## Declare variables and log path that will be used by other functions
Log_And_Variables () {

	####  Varibale	####

	## Check the original user that executed the script
	if [[ -z $SUDO_USER ]]; then
		orig_user=$(whoami)
	else
		orig_user=$SUDO_USER
	fi

	tmpdir=$(mktemp -d -p $HOME)
	errorpath=$HOME/.Automated-Installer-Log/error.log
	outputpath=$HOME/.Automated-Installer-Log/output.log
	lightconf=/etc/lightdm/lightdm.conf
	lightwebconf=/etc/lightdm/lightdm-webkit2-greeter.conf
	post_script="https://raw.githubusercontent.com/BigRush/Automated-Installer/master/.post-install.sh"
	appinstall_script="https://raw.githubusercontent.com/BigRush/Automated-Installer/master/.appinstall.sh"
	archfuncs_script="https://raw.githubusercontent.com/BigRush/Automated-Installer/master/.archfuncs.sh"
	deepin_sound_path=/usr/share/sounds/deepin/stereo/
	kernel_ver=$(uname -r |cut -d "." -f 1,2 |tr -d ".s")
	refind_path=$(sudo find /boot -path *refind)
	####  Varibale	####

	## Check if log folder exits, if not, create it
	if ! [[ -d $HOME/.Automated-Installer-Log ]]; then
		sudo runuser -l $orig_user -c "mkdir $HOME/.Automated-Installer-Log"
	fi

	## Check if error log exits, if not, create it
	if ! [[ -e $errorpath ]]; then
		sudo runuser -l $orig_user -c "touch $errorpath"
	fi

	## Check if output log exits, if not, create it
	if ! [[ -e $outputpath ]]; then
		sudo runuser -l $orig_user -c "touch $outputpath"
	fi
}

## Clean tmp directories and file that were created during the script
Clean_Up () {
	rm -rf $tmpdir
}


## Checking the environment the user is currenttly running on to determine which settings should be applied
Distro_Check () {

	## Put all the distros i want to check in an array
	Distro_Array=(manjaro arch ubuntu debian centos fedora)
	## set the initial success variable to 1 (0=success 1=failed)
	status=1
	## Go other each element of the array and check if that element (in this
	## case the element will be a distro) exists in the distro check file
	## (/etc/*-release), if it does, set the Distro_Val to the current element
	## ($i) and set the status to 0 (success), if it doesn't find any element
	## of the array that matches the file, then status will remain 1 (failed)
	## and prompt the user that the script did not find his distribution
	for i in ${Distro_Array[@]}; do
		DistroChk=$(cat /etc/*-release |egrep "^ID" |cut -d '=' -f '2' |tr -d [:punct:] |egrep "^$i$")
		if [[ -n $DistroChk ]]; then
		  	Distro_Val="$i"
		    status=0
			break
		fi
	done

    if [[ $status -eq 1 ]]; then
        printf "$line\n"
        printf "Sorry, but the script did not find your distribution,\n"
        printf "Exiting...\n"
        printf "$line\n\n"
        exit 1
    fi


	if [[ $Distro_Val == debian ]]; then
		debian_cname="$(cat /etc/*-release |egrep ^VERSION=.* |awk '{print $2}' |tr -d [:punct:] |tr [:upper:] [:lower:])"

	elif [[ $Distro_Val == ubuntu ]]; then
		ubuntu_cname="$(cat /etc/*-release |egrep ^VERSION=.* |egrep -o "\(.*\)" |awk '{print $1}' |tr -d [:punct:] |tr [:upper:] [:lower:])"
	fi

	if [[ $Distro_Val == centos || $Distro_Val == fedora ]]; then
		printf "$line\n"
		printf "This script doesn't support $Distro_Val at the moment\n"
		printf "$line\n"

		exit 1
	fi
}

## Update the system
System_Update () {

	output_text="Updating the package lists"
	error_text="Updating the package lists"

	if [[ $Distro_Val == debian || $Distro_Val == ubuntu ]]; then

		sudo apt-get update 2>> $errorpath >> $outputpath &
		BPID=$!
		Progress_Spinner
		wait $BPID
		status=$?
		Exit_Status

	elif [[ $Distro_Val == arch || $Distro_Val == manjaro ]]; then
		## Prompet sudo
		sudo echo

		## Will be used in Exit_Status function to output text for the user
		output_text="Update"
		error_text="while updating"

		## Update the system, send stdout, sterr to log files
		## and move the process to the background for the Progress_Spinner function.
		sudo pacman -Sy --noconfirm 2>> $errorpath >> $outputpath &

		## Save the background PID to a variable for later use with wait command
		BPID=$!

		## Call Progress_Spinner function
		Progress_Spinner

		## Wait until the process is done to get its exit status.
		wait $BPID

		## Save the exit status of last command to a Varibale
		status=$?

		## Call Exit_Status function
		Exit_Status
	fi
}


## Installs dependencies
Dependencies_Installation () {

	## Check if wget is installed,
	## if not then download it
	if [[ -z $(command -v wget) ]]; then
		output_text="wget download"
		error_text="while downloading wget"

		## Download wget
		if [[ $Distro_Val == arch || $Distro_Val == manjaro ]]; then
			sudo echo
			sudo pacman -S wget --needed --noconfirm 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == "debian" || $Distro_Val == ubuntu ]]; then
			sudo echo
			sudo apt-get install wget -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == centos || $Distro_Val == fedora ]]; then
			sudo echo
			sudo yum install wget -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status
		fi
	fi

	## Check if curl is installed,
	## if not then download it
	if [[ -z $(command -v curl) ]]; then
		output_text="curl download"
		error_text="while downloading curl"

		## Download wget
		if [[ $Distro_Val == arch || $Distro_Val == manjaro ]]; then
			sudo echo
			sudo pacman -S curl --needed --noconfirm 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == debian || $Distro_Val == ubuntu ]]; then
			sudo echo
			sudo apt-get install curl -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == centos || $Distro_Val == fedora ]]; then
			sudo echo
			sudo yum install curl -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status
		fi
	fi

	## Check if git is installed,
	## if not then download it
	if [[ -z $(command -v git) ]]; then
		output_text="git download"
		error_text="while downloading git"

		## Download wget
		if [[ $Distro_Val == arch || $Distro_Val == manjaro ]]; then
			sudo echo
			sudo pacman -S git --needed --noconfirm 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == "debian" || $Distro_Val == ubuntu ]]; then
			sudo echo
			sudo apt-get install git -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status

		elif [[ $Distro_Val == centos || $Distro_Val == fedora ]]; then
			sudo echo
			sudo yum install git -y 2>> $errorpath >> $outputpath &
			BPID=$!
			Progress_Spinner
			wait $BPID
			status=$?
			Exit_Status
		fi
	fi
}

## Source functions from other scripts
## If they doesn't exists, pull them from GitHub
Source_And_Validation () {

    ## Source the functions from the other scripts.
    ## Check if it was successfull with exit status,
    ## if it wasn't, get the missing script from GitHub
    source ./.post-install.sh 2>> $errorpath >> $outputpath
    if ! [[ $? -eq 0 ]]; then
		output_text=".post-install.sh download"
		error_text="while downloading .post-install.sh"

		wget --show-progress --progress=bar -a $outputpath -O $tmpdir/post-install.sh $post_script
		wait
		status=$?
		Exit_Status
		sudo printf "\n"

		output_text=".post-install.sh source"
		error_text="while sourcing .post-install.sh"

		source $tmpdir/post-install.sh 2>> $errorpath >> $outputpath
		status=$?
		Exit_Status
    fi

    source ./.appinstall.sh 2>> $errorpath >> $outputpath
    if ! [[ $? -eq 0 ]]; then
		output_text=".appinstall.sh download"
		error_text="while downloading .appinstall.sh"

		wget --show-progress --progress=bar -a $outputpath -O $tmpdir/appinstall.sh $appinstall_script
		wait
		status=$?
		Exit_Status
		sudo printf "\n"

		output_text=".appinstall.sh source"
		error_text="while sourcing .appinstall.sh"

		source $tmpdir/appinstall.sh 2>> $errorpath >> $outputpath
		status=$?
		Exit_Status
    fi

	source ./.archfuncs.sh 2>> $errorpath >> $outputpath
    if ! [[ $? -eq 0 ]]; then
		output_text=".archfuncs.sh download"
		error_text="while downloading .archfuncs.sh"

		wget --show-progress --progress=bar -a $outputpath -O $tmpdir/archfuncs.sh $archfuncs_script
		wait
		status=$?
		Exit_Status
		sudo printf "\n"

		output_text=".archfuncs.sh source"
		error_text="while sourcing .archfuncs.sh"

		source $tmpdir/archfuncs.sh 2>> $errorpath >> $outputpath
		status=$?
		Exit_Status
    fi
}


## prompt the user with a menu to start the script
Main_Menu () {
	IFS=","
	scripts=("Post install","AppInstall","Virtualization & Container","Clean Logs","Exit")
	PS3="Please choose what would you like to do: "
	select opt in ${scripts[*]} ; do
	    case $opt in
	        "Post install")
				if [[ $Distro_Val == arch ]]; then
					Theme_Prompt
					sleep 1
					Arch_Config
					sleep 2.5
					Alias_and_Wallpaper
					sleep 2.5
					Pacman_Multilib
					sleep 2.5
					if [[ "$desktop_env" == "plasma" ]]; then
						KDE_Installation
						sleep 0.5
						KDE_Font_Config
					elif [[ "$desktop_env" == "deepin" ]]; then
						Deepin_Installation
					else
						DE_Menu
					fi
					sleep 2.5
					if [[ "$display_mgr" == "sddm" ]]; then
						SDDM_Installation
					elif [[ "$display_mgr" == "lightdm" ]]; then
						LightDM_Installation
						sleep 0.5
						LightDM_Configuration
					else
						DM_Menu
					fi
					sleep 2.5
					Theme_Config
					sleep 2.5
					Boot_Manager_Config

				elif [[ $Distro_Val == "manjaro" ]]; then
					Theme_Prompt
					sleep 1
					Alias_and_Wallpaper
					sleep 2.5
					Pacman_Multilib
					sleep 2.5
					Theme_Config
					sleep 2.5
					DM_Menu
					sleep 2.5
					Boot_Manager_Config

				elif [[ $Distro_Val == "debian" || $Distro_Val == ubuntu ]]; then
					Theme_Prompt
					sleep 1
					Alias_and_Wallpaper
					sleep 2.5
					Theme_Config
					sleep 2.5
					Boot_Manager_Config
				fi


				printf "$line\n"
				printf "Post-Install completed successfully\n"
				printf "$line\n\n"
				exit 0
				;;

	        "AppInstall")
				if [[ $Distro_Val == arch || $Distro_Val == manjaro ]]; then
					if [[ $aur_helper == "yay" || -z $aur_helper ]]; then
						Yay_Install
						sleep 2.5
						Yay_Applications
						sleep 2.5

					elif [[ $aur_helper == "aurman" ]]; then
						aur_helper="aurman"
						Aurman_Install
						sleep 1
						Aurman_Applications
						sleep 1
						Vbox_Installation
					fi

				elif [[ $Distro_Val == debian || $Distro_Val == ubuntu ]]; then
					Apt_Applications
					sleep 1
					Deb_Packages
					sleep 1
				fi

				printf "$line\n"
				printf "AppInstall completed successfully\n"
				printf "$line\n\n"
				exit 0
				;;

			"Virtualization & Container")
				Vbox_Installation
				Docker_Installation
				Vagrant_Installation

				printf "$line\n"
				printf "Virtualization & Container completed successfully\n"
				printf "$line\n\n"
				exit 0
				;;


			Exit)
				printf "$line\n"
				printf "Exiting, have a nice day!\n"
				printf "$line\n"
				exit 0
				;;

			"Clean Logs")
				output_text="Cleaning log files"
				error_text="while cleaning log files"

				echo > $errorpath
				echo > $outputpath
				;;

			*)
				printf "Invalid option\n"
				;;
		esac
	done
}
## Cosmetic for the script and getopts must be
## declared here so it could be used by getopts
line="\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-\-"


## Use getopts so I'll have the option to
## choose between aurman and yay, desktop environment,
## display manager, and auto install Vagrant, Docker or VirtualBox
while getopts :a:d:e:t:hHDO flag; do
	case $flag in
		a)
			if [[ "aurman" == "$OPTARG" ]]; then
				aur_helper="aurman"
			elif [[ "yay" == "$OPTARG" ]]; then
				aur_helper="yay"
			else
				printf "$line\n"
				printf "Invalid argument, use '-h' for help\n"
				printf "$line\n\n"
				exit 1
			fi
			;;

		d)
			if [[ "sddm" == "$OPTARG" ]]; then
				display_mgr="sddm"
			elif [[ "lightdm" == "$OPTARG" ]]; then
				display_mgr="lightdm"
			else
				printf "$line\n"
				printf "Invalid argument, use '-h' for help\n"
				printf "$line\n\n"
				exit 1
			fi
			;;

		e)
			if [[ "plasma" == "$OPTARG" ]]; then
				desktop_env="plasma"
			elif [[ "deepin" == "$OPTARG" ]]; then
				desktop_env="deepin"
			else
				printf "$line\n"
				printf "Invalid argument, use '-h' for help\n"
				printf "$line\n\n"
				exit 1
			fi
			;;

		t)
			for i in $OPTARG; do
				if [[ $i == 'bibata' || $OPTARG == 'zafiro' || $OPTARG == 'capitaine' \
				|| $OPTARG == 'shadow' || $OPTARG == 'papirus' || $OPTARG == 'arc' \
				|| $OPTARG == 'adapta' || $OPTARG == 'chili' ]]; then

					if [[ $i == 'bibita' ]]; then
						bibata_cursor="yes"

					elif [[ $i == 'zafiro' ]]; then
						zafiro_icons="yes"

					elif [[ $i == 'capitaine' ]]; then
						capitaine_icons="yes"

					elif [[ $i == 'shadow' ]]; then
						shadow_icons="yes"

					elif [[ $i == 'papirus' ]]; then
						papirus_icons="yes"

					elif [[ $i == 'arc' ]]; then
						arc_theme="yes"

					elif [[ $i == 'adapta' ]]; then
						adapta_theme="yes"

					elif [[ $i == 'chili' ]]; then
						chili_theme="yes"

					else
						printf "$line\n"
						printf "Something went wrong, no themes are pre-set...\n"
						printf "$line\n\n"
					fi
				else
					printf "$line\n"
					printf "Invalid theme argument, no themes are pre-set...\n"
					printf "$line\n\n"
				fi
			done
			;;

		O)
			vbox_inst="yes"
			;;

		D)
			docker_inst="yes"
			;;

		H)
			vagrant_inst="yes"
			;;

		h)
			printf "$line\n"
			printf " Usage: -a <argument> -e <argument> -d <argument> -O -D -H\n\n"
			printf " Flags with arguments:\n\n"
			printf " -a <argument>"
			printf "\t\tChoose which AUR helper you would\n"
			printf "      \t\t\tlike to use [ 'aurman' or 'yay' ]\n"
			printf "      \t\t\t('yay' is the default option if '-a' is not triggered)\n\n"
			printf " -d <argument>"
			printf "\t\tChoose which display manager\n\n"
			printf "      \t\t\tyou would tlike to use [ 'SDDM' or 'LightDM' ]\n\n"
			printf " -e <argument>"
			printf "\t\tChoose which desktop environment\n"
			printf "      \t\t\tyou would tlike to use [ 'Plasma' or 'Deepin' ]\n\n"
			printf " -t <arguments>"
			printf "\t\tChoose which theme you would like to install,\n"
			printf "      \t\t\targuments should be separated by spaces.\n"
			printf "      \t\t\tPossible themes:\n"
			printf "      \t\t\t['bibata' 'zafiro' 'capitaine' 'shadow' 'papirus' 'arc' 'adapta' 'chili']\n\n"
			printf " Flags without arguments:\n\n"
			printf " -D"
			printf "\t\t\tInstall Docker\n\n"
			printf " -h"
			printf "\t\t\tShow help\n\n"
			printf " -H"
			printf "\t\t\tInstall Vagrant\n\n"
			printf " -O"
			printf "\t\t\tInstall VirtualBox\n\n"
			printf "$line\n\n"
			exit 0
			;;

		:)
			printf "$line\n"
			printf " Usage: -a <argument> -e <argument> -d <argument> -O -D -H\n\n"
			printf " Flags with arguments:\n\n"
			printf " -a <argument>"
			printf "\t\tChoose which AUR helper you would\n"
			printf "      \t\t\tlike to use [ 'aurman' or 'yay' ]\n"
			printf "      \t\t\t('yay' is the default option if '-a' is not triggered)\n\n"
			printf " -d <argument>"
			printf "\t\tChoose which display manager\n\n"
			printf "      \t\t\tyou would tlike to use [ 'SDDM' or 'LightDM' ]\n\n"
			printf " -e <argument>"
			printf "\t\tChoose which desktop environment\n"
			printf "      \t\t\tyou would tlike to use [ 'Plasma' or 'Deepin' ]\n\n"
			printf " -t <arguments>"
			printf "\t\tChoose which theme you would like to install,\n"
			printf "      \t\t\targuments should be separated by spaces.\n"
			printf "      \t\t\tPossible themes:\n"
			printf "      \t\t\t['bibata' 'zafiro' 'capitaine' 'shadow' 'papirus' 'arc' 'adapta' 'chili']\n\n"
			printf " Flags without arguments:\n\n"
			printf " -D"
			printf "\t\t\tInstall Docker\n\n"
			printf " -h"
			printf "\t\t\tShow help\n\n"
			printf " -H"
			printf "\t\t\tInstall Vagrant\n\n"
			printf " -O"
			printf "\t\t\tInstall VirtualBox\n\n"
			printf "$line\n\n"
			exit 0
			;;

		\?)
			printf "$line\n"
			printf "Invalid option -$OPTARG\ntry -h for help\n"
			printf "$line\n\n"
			exit 1
			;;
	esac
done

## Call Non_Root_Check function
Non_Root_Check

## Make sure there is a clean up by traping the function upon EXIT
trap Clean_Up EXIT

## Call Log_And_Variables function
Log_And_Variables

## Call Distro_Check function
Distro_Check

## Set aur_helper default value 'yay'
if [[ -z $aur_helper ]]; then
	aur_helper="yay"
fi

## Call System_Update function
System_Update

## Call Dependencies_Installation function
Dependencies_Installation

## Call Source_And_Validation function
Source_And_Validation


if [[ $vbox_inst == "yes" ]]; then
	Vbox_Installation
fi

if [[ $vagrant_inst == "yes" ]]; then
	Vagrant_Installation
fi

if [[ $docker_inst == "yes" ]]; then
	Docker_Installation
fi

if [[ -z $vbox_inst && -z $vagrant_inst && -z $docker_inst ]]; then
	Main_Menu
fi

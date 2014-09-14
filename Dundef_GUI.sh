#!/bin/bash
# Bash Trap commmand
#trap bashtrap INT

purple='\e[0;35m'
yellow='\e[1;33m'
red='\e[1;31m'
nc='\e[0m'

# Update your locate
echo "Settings up PATHS..."
sudo updatedb

# SET PATH :
STEAMPATH=`locate "steam.pipe" | head -1 | sed "s/\/steam\.pipe/\//"`
STEAM_LIB_PATH=`locate steam-runtime/i386 | head -1`
STEAMAPPS=`locate SteamApps | grep "SteamApps" | head -1`

# In case of the game path is not the default path :
DUNDEF_LIB_PATH=`locate DunDefEternity | grep "/DunDefEternity/Binaries/Linux" | head -1`
DUNDEF_LAUNCHER_PATH=`locate DunDefEternityLauncher | sort -u`

# List of package used for Debian :
apt="libgconf-2-4:i386 libvorbisfile3:i386 libsfml-dev:i386 libcrypto++-dev:i386 curl:i386 libcurl4-openssl-dev:i386 \
libfreetype6:i386 libxrandr2:i386 libgtk2.0-0:i386 libpango-1.0-0:i386 libnss3-dev:i386 libpangocairo-1.0-0:i386 \
libasound2-dev:i386 libgdk-pixbuf2.0-0:i386"

# List of package used for RedHat :
yum="GConf2.i686 libvorbis.i686 SFML.i686 SFML-devel.i686 cryptopp.i686 libcurl.i686 libcurl-devel.i686 \
freetype.i686 freetype-devel.i686 libXrandr.i686 libXrandr-devel.i686 gtk2.i686 gtk2-devel.i686 \
pango.i686 pango-devel.i686 cairo.i686 cairo-devel.i686 gtk-pixbuf2-devel.i686 gtk-pixbuf2.i686"

# List of package used for Arch :
pacman="gconf lib32-libvorbis sfml crypto++ lib32-libgcrypt curl lib32-nss lib32-openssl lib32-libfreetype \
lib32-libxrandr lib32-gtk2 lib32-pango libtiger lib32-gdk-pixbuf2"

# Bash trap function:
#bashtrap () {
#echo -e "${red}CTRL+C Detected !... If you want exit please use \"Q\" or \"q\".${nc}"
#}

# Function used to ask if the user want to launch the game :
function LaunchGame () {
	local step=true
	while ${step}; do
		echo "Do you want launch Dungeon Defender?(Y/N)"
		read answer

		case ${answer} in
			Y|y)
				steam steam://rungameid/302270 &
				step=false
				;;
			N|n)
				echo "Quiting..."
				step=false
				;;
			*)
				echo "Please use Y or N."
				step=true
				;;
		esac
	done
}

function CheckLibs () {
	## Check for available libs :
	echo "------------------------------------------------------"
	echo "Installed Libs :"
	echo $(ldd ${DUNDEF_LAUNCHER_PATH} | grep lib | tr "\t" " " | cut -d"=" -f1)
	echo "------------------------------------------------------"
	
	## Check for unavailable libs :
	echo "Missing Libs :"
	echo $(ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1)
	echo "------------------------------------------------------"
	echo ""
	echo "Directories used for your libs"
	
	# Prints out all directory used to provide your libs
	sudo ldconfig -v 2>/dev/null | grep -v ^$'\t'
	echo "------------------------------------------------------"
}

function Check64bit () {
	if [ $(getconf LONG_BIT) -eq "64" ]; then
		echo "You use a 64 bit Linux"
		# If debian/Ubuntu
		if [ ${1} = "dpkg" ];then
			echo -e "${yellow}Add i386 arch${nc}"
			sudo dpkg --add-architecture i386
		fi
		
		# If Arch
		if [ ${1} = "pacman" ];then
			line=$(grep -n -A 2 "#\[multilib\]" pacman.conf | grep -o '[0-9]\{2,3\}')

		if [[ -n "${line}" ]]; then
			echo "Enabling 'MultiLib' Repo :"
			for num in ${line}; do
				sed -i ''${num}'s/#//' pacman.conf
			done
		fi
	fi
	## If Redhat nothing to do.
	else
		echo "You use a 32 bit Linux."
		echo "Change package list to 32 bit package."
		
		# Change to 32 bit package (Debian):
		apt="libgconf-2-4 libvorbisfile3 libsfml-dev libcrypto++-dev curl libcurl4-openssl-dev libfreetype6 libxrandr2 \
			libgtk2.0-0 libpango-1.0-0 libnss3-dev libpangocairo-1.0-0 libasound2-dev libgdk-pixbuf2.0-0"
		
		# Change to 32 bit package (RedHat):
		yum="GConf2 libvorbis SFML SFML-devel cryptopp libcurl libcurl-devel freetype freetype-devel libXrandr \
			libXrandr-devel gtk2 gtk2-devel pango pango-devel cairo cairo-devel gtk-pixbuf2-devel gtk-pixbuf2"

		# Change to 32 bit package (Arch):
		pacman="gconf libvorbis sfml crypto++ libgcrypt curl nss openssl libfreetype libxrandr gtk2 pango libtiger \
				gdk-pixbuf2"
	fi
}

function SymLinkFix () {
	CheckLibs
	## Doing job
	ln -sf ${STEAM_LIB_PATH}/usr/lib/i386-linux-gnu/* ${DUNDEF_LIB_PATH}
	ln -sf ${STEAM_LIB_PATH}/lib/i386-linux-gnu/* ${DUNDEF_LIB_PATH}
	clear
	echo "Symlinking Done!"
	echo "------------------------------------------------------"
	echo "Missing libs :"
	echo $(ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1)
	echo "------------------------------------------------------"
}

function PandaFix () {
	CheckLibs
	# Installing Main libs
	## Debian Flavours
	if [[ -x "$(which apt-get)" ]]; then
		Check64bit dpkg
		echo "Installing missing libs :"
		sudo aptitude update && sudo aptitude install ${apt}
	elif [[ -x "$(which aptitude)" ]]; then
		Check64bit dpkg
		echo "Installing missing libs :"
		sudo apt-get update && sudo apt-get install ${apt}
	fi
	
	## Red Hat Flavours
	if [[ -x "$(which yum)" ]]; then
		Check64bit yum
		echo "Installing missing libs :"
		sudo yum update && sudo yum install ${yum}
	fi
	
	## ArchLinux Flavours
	if [[ -x "$(which pacman)" ]]; then
		Check64bit pacman
		echo "Installing missing libs :"
		echo "/!\ Support of pacman package manager is currently in testing..."
		sudo pacman -Syy && sudo pacman -S ${pacman}
	fi
	
	echo "------------------------------------------------------"
	echo "Missing Libs :"
	echo $(ldd ${DUNDEF_LAUNCHER_PATH} | grep "not found" | tr "\t" " " | cut -d"=" -f1)
	echo "------------------------------------------------------"
}

Cleaning () {
	echo "Cleaning symlink fix..."
	find "$DUNDEF_LIB_PATH" -maxdepth 1 -type l -exec rm -f {} \;
	echo "Cleaning done..."
}

#Show menu :
while true; do

	test=$(zenity --list --radiolist --title="Choose your Workaround" --column="Choose" --column="Fix Name" --column="Description" \
		TRUE "[SymLink Fix]" "Create all symlinks needed to fix your issue. (All Linux OS)" \
		FALSE "[Package Fix]" "Le dictionnaire GNOME ne prend pas de proxy en charge" \
		FALSE "[Show my Libs]" "L'édition de menu ne fonctionne pas avec GNOME 2.0" \
		FALSE "[Cleaning]" "Remove Symlink")
	
	case ${test} in
		"[SymLink Fix]")
			SymLinkFix
			LaunchGame
			;;
		"[Package Fix]")
			PandaFix
			LaunchGame
			;;
		"[Show my Libs]")
			# Prints out all directories used to provide your libs
			CheckLibs
			;;
		"[Cleaning]")
			Cleaning
			;;
		*)
			if [[ &? -eq -1 ]]; then
				exit 0;
			fi
			echo "${test} is not available"
			;;
	esac
done

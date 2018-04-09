#!/bin/bash
# Functions:
function add_webcam {
# Install cheese if the device has a webcam
if [ -c /dev/video0 ]; then # check if video0 is a character device (if it exists, it is)
	apt-get -y install cheese
fi	
}
function ask() {
# Function that makes a prompt	
    while true; do
 
        if [ "${2:-}" = "Y" ]; then
            prompt="Y/n"
            default=Y
        elif [ "${2:-}" = "N" ]; then
            prompt="y/N"
            default=N
        else
            prompt="y/n"
            default=
        fi
 
        # Ask the question
        read -p "$1 [$prompt] " REPLY
 
        # Default?
        if [ -z "$REPLY" ]; then
            REPLY=$default
        fi
 
        # Check if the reply is valid
        case "$REPLY" in
            Y*|y*) return 0 ;;
            N*|n*) return 1 ;;
        esac
 
    done
}
function modify_sources_list {
##################################
# Edits to /etc/apt/sources.list #
##################################

# Default sources.list already has:
# <releasename> main restricted universe multiverse
# <releasename>-security main restricted universe multiverse
# <releasename>-updates main restricted

### Disable Source Repos
#
# Check to see if Source repos are set ON and turn OFF
if grep -q "deb-src#" /etc/apt/sources.list; then
    echo "# Already disabled source repositories"
else
    echo "* Commenting out source repositories -- we don't mirror them locally."
    sed -i 's/deb-src /#deb-src# /' /etc/apt/sources.list
fi

### Disable and Remove Any Medibuntu Repos
#

if [ -e /etc/apt/sources.list.d/medibuntu.list ]; then
    echo "* Removing Medibuntu Repos."
    rm /etc/apt/sources.list.d/medibuntu*
else
    echo "# Already removed Medibuntu's libdvdcss repo."
fi

### Enable VideoLAN Repo for libdvdcss
#
# In the future call /usr/share/doc/libdvdread4/install-css.sh
#
if [ -e /etc/apt/sources.list.d/videolan.sources.list ]; then
    echo "# Already added libdvdcss repo, OK."
else
    echo "* Adding VideoLAN's libdvdcss repo, OK."
	echo 'deb http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
#       echo 'deb-src http://download.videolan.org/pub/debian/stable/ /' >> /etc/apt/sources.list.d/videolan.sources.list
	wget -O - http://download.videolan.org/pub/debian/videolan-apt.asc|sudo apt-key add - libdvdcss
fi

#############################################
# Edit /etc/update-manager/release-upgrades #
#############################################

# Check to see if Source repos are set ON and turn OFF
if grep -q "Prompt=never" /etc/update-manager/release-upgrades; then
    echo "# Release Upgrades set to 'never'"
else
    echo "* Setting Release Upgrades to 'never'"
    sed -i 's/Prompt=lts/Prompt=never/' /etc/update-manager/release-upgrades
fi
	}
function install_general_programs {
GENERAL_PROGRAMS=(
'libreoffice' # Office Suite
'ubuntu-restricted-extras' #codecs
'non-free-codecs' #more codecs
'libdvdcss2' #DVD Playback
'gimp' #Image Editing Softwarwe
'krita' #Vector graphics program
'inkscape' #Vector Graphics Program
'vlc' #Multi-format media player
'mplayer' #Movie player
'totem-mozilla' #media playback extension for Firefox.
'gcj-jre' #Java
'ca-certificates' #List of CA certificates (for safer browsing)
'chromium-browser' # open-source web browser
'hardinfo' # system information
'inxi' # system information
'cdrdao' #CD recording software
'language-pack-es' #Spanish language support
'language-pack-gnome-es' #Spanish language support
'linux-firmware-nonfree' #TV capture card drivers.
'firmware-b43-installer' #broadcom wireless drivers 
'b43-fwcutter' #broadcom wireless drivers 
)
for program in ${GENERAL_PROGRAMS[*]};
do
	apt-get -y install "$program"
done
}
function install_14_04_programs {
# Auto-accept the MS Core Fonts EULA
echo "ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true" | debconf-set-selections

# Add Pepper Flash Player support for Chromium
# Note that this temporarily downloads Chrome, and the plugin uses plugin APIs not provided in Firefox
if [ "$(lsb_release -rs)" = '14.04' ]; then
echo "* Customizing Trusty packages"
apt-get -y install pepperflashplugin-nonfree &&
update-pepperflashplugin-nonfree --install
 apt-get -y install fonts-mgopen
 fi
}
function install_kubuntu_programs {
echo "* Customizing Trusty-Kubuntu packages."
apt-get -y install software-center
apt-get -y install kdewallpapers
apt-get -y install kubuntu-restricted-extras
apt-get -y autoremove muon muon-updater muon-discover
}
function install_xubuntu_programs {
echo "* Customizing Trusty-Xubuntu packages."
apt-get -y install xubuntu-restricted-extras
apt-get -y remove gnumeric* abiword*
echo "* Customizing Trusty-Xubuntu settings."
apt-get -y install xmlstarlet
# Make a system-wide fix so that Audio CDs autoload correctly.
xmlstarlet ed -L -u '/channel/property[@name="autoplay-audio-cds"]/property[@name="command"]/@value' -v '/usr/bin/vlc cdda://' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
### And now do it for the current user.
xfconf-query -c thunar-volman -p /autoplay-audio-cds/command -s "/usr/bin/vlc cdda://"

# Make a system-wide fix so that Audio CDs autoload correctly.
xmlstarlet ed -L -u '/channel/property[@name="autoplay-video-cds"]/property[@name="command"]/@value' -v '/usr/bin/vlc dvd://' /etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/thunar-volman.xml
### And now do it for the current user.
xfconf-query -c thunar-volman -p /autoplay-video-cds/command -s "/usr/bin/vlc dvd://"

# Make a system-wide fix so that Mac eject key (X86Eject) is mapped to eject (eject -r) function.
xmlstarlet ed -L -s '/channel/property[@name="commands"]/property[@name="default"]' -t elem -n propertyTMP -v "" \
  -i //propertyTMP -t attr -n "name" -v "X86Eject" \
  -i //propertyTMP -t attr -n "type" -v "string" \
  -i //propertyTMP -t attr -n "value" -v "eject" \
  -r //propertyTMP -v property \
/etc/xdg/xdg-xubuntu/xfce4/xfconf/xfce-perchannel-xml/xfce4-keyboard-shortcuts.xml
### And now do it for the current user.
xfconf-query -c xfce4-keyboard-shortcuts -p /commands/default/XF86Eject -n -t string -s "eject"
}
function install_mint_programs {
mintupdate-tool upgrade -r -k -s -y -l12345 --install-recommends
# Volman controls autoplay settings for xfce
if [ "$(dpkg -s thunar-volman | grep "Status: install ok installed")" == "Status: install ok installed" ]; then
echo "Setting up autoplay for linux mint"
xfconf-query -c thunar-volman -p /autoplay-audio-cds/command -s "/usr/bin/vlc cdda://%d"
xfconf-query -c thunar-volman -p /autoplay-audio-cds/enabled -s true
xfconf-query -c thunar-volman -p /autoplay-video-cds/command -s "/usr/bin/vlc dvd://%d"
xfconf-query -c thunar-volman -p /autoplay-video-cds/enabled -s true
fi
}
function remove_useless_programs {
# Get rid of amarok, since vlc works much better.
apt-get -y remove amarok
}
function apple_hardware {
MANUFACTURER="$(dmidecode -s system-manufacturer)"
if [ "$MANUFACTURER" = "Apple Inc." ]; then
    echo "You are using an $MANUFACTURER."

    # Remove current apple_ubuntu.sh
    if [ -f /usr/local/bin/apple_ubuntu.sh ]; then
    	echo "## Removing old apple_ubuntu.sh, OK."
    	rm /usr/local/bin/apple_ubuntu.sh
    fi

    # Pull fresh install.sh from github, store in /usr/local/bin
    echo "## Pulling fresh apple_ubuntu.sh, OK."
    wget -qO /usr/local/bin/apple_ubuntu.sh https://raw.githubusercontent.com/freegeekchicago/fgc-installscript/master/apple_ubuntu.sh

    # Run install.sh for updates
    echo "## Running apple_ubuntu.sh, BYE!"
    . /usr/local/bin/apple_ubuntu.sh
fi	
}
function fix_bluray_playback {
# set up blu-ray playback
apt-get -y  install libaacs0 libbluray-bdj libbluray1
mkdir -p ~/.config/aacs/
cd ~/.config/aacs/ && wget http://vlc-bluray.whoknowsmy.name/files/KEYDB.cfg
cd ~
}
function fix_chromium_bug {
# Fix Chromium Keyring Bug:
# https://forum.manjaro.org/t/keyring-for-chromium-is-pointless/4328/4
mv /usr/bin/gnome-keyring-daemon /usr/bin/gnome-keyring-daemon-old
killall gnome-keyring-daemon	
}
function end_install_script {
######################
# Install and Run sl #
######################
# Ensure installation completed without errors

    apt-get -y install sl
    echo "Installation complete -- relax, and watch this STEAM LOCOMOTIVE"; sleep 2
    /usr/games/sl

##################
# Ask for reboot #
##################

if ask "Do you want to reboot now?" N; then
    echo "Rebooting now."
    reboot
else
    exit 0
fi
	}
# Main Program Logic:

echo "################################"
echo "#  FreeGeek Chicago Installer  #"
echo "################################"

if [ "$(uname)" == "Linux" ] && [ "$(command -v apt-get)" == "/usr/bin/apt-get" ]; 
	then echo "You're running a version of Linux that incorporates apt-get.";
		modify_sources_list
		apt-get -y update && apt-get -y dist-upgrade
		dpkg --get-selections >before.txt
		install_general_programs
		remove_useless_programs
		add_webcam
		fix_bluray_playback
		fix_chromium_bug
		apple_hardware
	if [ "$(less /etc/os-release | grep DISTRIB_CODENAME)" == "DISTRIB_CODENAME=trusty" ]; 
		then echo "You're running a version of Ubuntu 14.04";
		install_14_04_programs
		if [ "$(dpkg -s xubuntu-desktop | grep "Status: install ok installed")" == "Status: install ok installed" ]; 
			then echo "You're running Xubuntu 14.04";
			install_xubuntu_programs
		fi
		if [ "$(dpkg -s kubuntu-desktop | grep "Status: install ok installed")" == "Status: install ok installed" ];
			then echo "You're running Kubuntu 14.04";
			install_kubuntu_programs
		fi
	fi
	if [ "$(less /etc/os-release | grep UBUNTU_CODENAME)" == "UBUNTU_CODENAME=xenial" ]; 
		then echo "You're running a version of Ubuntu 16.04";
# Install general 16.04 stuff here. 
# Some people have updated from 14.04.
		if [ -x "$(command -v mintupdate-tool)" ]; 
			then echo "You're running Linux Mint."; 
			install_mint_programs
		fi
	fi
	dpkg --get-selections >after.txt
	diff -y before.txt after.txt >comparison.txt
	rm before.txt after.txt
	end_install_script
else
	echo "This script requires a Linux operating system with apt-get to work."
fi

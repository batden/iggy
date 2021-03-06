#!/bin/bash

# This Bash script allows you to easily and safely install Enlightenment along with other
# EFL-based applications, on openSUSE Tumbleweed.

# Note that you need a properly configured 'sudo' to execute this script.
# See README.md for further instructions on how to use IGGY.SH.

# Heads up!
# Enlightenment programs installed from .rpm packages or tarballs will inevitably
# conflict with programs compiled from git repositories——do not mix source code
# with pre-built binaries! So please remove thoroughly any previous binary
# installation of EFL/Enlightenment/E-apps (track down and delete any
# leftover files) before running iggy.sh.

# Once installed, you can update your shiny new Enlightenment desktop whenever you want to.
# However, because software gains entropy over time (performance regression, unexpected
# behavior... and this is especially true when dealing directly with source code), we
# highly recommend doing a complete uninstall and reinstall of your Enlightenment
# desktop every three weeks or so for an optimal user experience.

# IGGY.SH is written and maintained by carlasensa@sfr.fr and batden@sfr.fr,
# feel free to use this script as you see fit.

# ---------------
# LOCAL VARIABLES
# ---------------

BLD="\e[1m"    # Bold text.
ITA="\e[3m"    # Italic text.
BDR="\e[1;31m" # Bold red text.
BDG="\e[1;32m" # Bold green text.
BDY="\e[1;33m" # Bold yellow text.
BDC="\e[1;34m" # Bold cyan text.
BDP="\e[1;35m" # Bold purple text.
OFF="\e[0m"    # Turn off ANSI colors and formatting.

DLDIR=$(xdg-user-dir DOWNLOAD)
DOCDIR=$(xdg-user-dir DOCUMENTS)
SCRFLR=$HOME/.iggy
REBASEF="git config pull.rebase false"
CONFG="./configure --libdir=/usr/local/lib64"
GEN="./autogen.sh --libdir=/usr/local/lib64"
SNIN="sudo ninja -C build install"
SMIL="sudo make install"

# Build dependencies, recommended and script-related packages.
DEPS="acpid alsa-devel aspell autoconf automake bluez-devel ccache check-devel cmake cowsay \
dbus-1-devel ddcutil doxygen fontconfig-devel freetype2-devel fribidi-devel \
gcc gcc-c++ geoclue2-devel gettext-tools giflib-devel glib2-devel graphviz-devel gstreamer-devel \
gstreamer-plugins-base-devel gstreamer-plugins-libav gstreamer-plugins-ugly harfbuzz-devel \
libaom-devel libavif-devel libdrm-devel libexif-devel libgbm-devel libheif-devel libi2c0-devel \
libinput-devel libjpeg62-devel libmount-devel libpng16-compat-devel libopenssl-devel \
libpoppler-devel libspectre-devel libpulse-devel libraw-devel librsvg-devel libsndfile-devel \
libspectre-devel libtiff-devel libtool libudev-devel libwebp-devel libxkbcommon-x11-devel \
Mesa-libGLESv2-devel meson mlocate moonjit-devel nasm openjpeg2-devel pam-devel papirus-icon-theme \
scim-devel systemd-devel valgrind-devel wmctrl xdotool xorg-x11-devel xorg-x11-server-extra"

# Latest development code.
CLONEFL="git clone https://git.enlightenment.org/core/efl.git"
CLONETY="git clone https://git.enlightenment.org/apps/terminology.git"
CLONE25="git clone https://git.enlightenment.org/core/enlightenment.git"
CLONEPH="git clone https://git.enlightenment.org/apps/ephoto.git"
CLONERG="git clone https://git.enlightenment.org/apps/rage.git"
CLONEVI="git clone https://git.enlightenment.org/apps/evisum.git"
CLONEVE="git clone https://git.enlightenment.org/tools/enventor.git"
CLONEXP="git clone https://git.enlightenment.org/apps/express.git"
CLONECR="git clone https://git.enlightenment.org/apps/ecrire.git"
CLONENT="git clone https://github.com/vtorri/entice"

# ('MN' stands for Meson, 'AT' refers to Autotools)
PROG_MN="efl terminology enlightenment ephoto evisum rage express ecrire entice"
PROG_AT="enventor"

# ---------
# FUNCTIONS
# ---------

beep_attention() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-warning.oga
}

beep_question() {
  paplay /usr/share/sounds/freedesktop/stereo/dialog-information.oga
}

beep_exit() {
  paplay /usr/share/sounds/freedesktop/stereo/suspend-error.oga
}

beep_ok() {
  paplay /usr/share/sounds/freedesktop/stereo/complete.oga
}

# Hints.
# 1/2: Plain build with well tested default values.
# 3: A feature-rich, decently optimized build; however, occasionally technical glitches do happen...
# 4: Same as above, but running Enlightenment as a Wayland compositor is still considered experimental.
#
sel_menu() {
  if [ $INPUT -lt 1 ]; then
    echo
    printf "1  $BDG%s $OFF%s\n\n" "INSTALL Enlightenment now"
    printf "2  $BDG%s $OFF%s\n\n" "Update and REBUILD Enlightenment"
    printf "3  $BDC%s $OFF%s\n\n" "Update and rebuild Enlightenment in RELEASE mode"
    printf "4  $BDP%s $OFF%s\n\n" "Update and rebuild Enlightenment with WAYLAND support"

    sleep 1 && printf "$ITA%s $OFF%s\n\n" "Or press Ctrl+C to quit."
    read INPUT
  fi
}

bin_deps() {
  sudo zypper refresh && sudo zypper update

  sudo zypper install $DEPS
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "CONFLICTING OR MISSING .RPM PACKAGES"
    printf "$BDR%s %s\n" "OR DATABASE IS LOCKED."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  fi
}

ls_dir() {
  COUNT=$(ls -d -- */ | wc -l)
  if [ $COUNT == 10 ]; then
    printf "$BDG%s $OFF%s\n\n" "All programs have been downloaded successfully."
    sleep 2
  elif [ $COUNT == 0 ]; then
    printf "\n$BDR%s %s\n" "OOPS! SOMETHING WENT WRONG."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit 1
  else
    printf "\n$BDY%s %s\n" "WARNING: ONLY $COUNT OF 10 PROGRAMS HAVE BEEN DOWNLOADED!"
    printf "\n$BDY%s $OFF%s\n\n" "WAIT 12 SECONDS OR HIT CTRL+C TO QUIT."
    sleep 12
  fi
}

mng_err() {
  printf "\n$BDR%s $OFF%s\n\n" "BUILD ERROR——TRY AGAIN LATER."
  beep_exit
  exit 1
}

e_bkp() {
  # Timestamp: See the date man page to convert epoch to human-readable date
  # or visit https://www.epochconverter.com/
  # To restore a backup, use the same command that was executed but with
  # the source and destination reversed:
  # e.g. cp -aR /home/jamie/Documents/ebackups/E_1622439936/.e* /home/jamie/
  # (Then press Ctrl+Alt+End to restart Enlightenment if you are currently logged into)
  #
  TSTAMP=$(date +%s)
  mkdir -p $DOCDIR/ebackups

  mkdir $DOCDIR/ebackups/E_$TSTAMP &&
    cp -aR $HOME/.elementary $DOCDIR/ebackups/E_$TSTAMP &&
    cp -aR $HOME/.e $DOCDIR/ebackups/E_$TSTAMP
  sleep 2
}

e_tokens() {
  echo $(date +%s) >>$HOME/.cache/ebuilds/etokens

  TOKEN=$(wc -l <$HOME/.cache/ebuilds/etokens)
  if [ "$TOKEN" -gt 3 ]; then
    echo
    # Questions: Enter either y or n, or press Enter to accept the default values (capital letter).
    beep_question
    read -t 12 -p "Do you want to back up your Enlightenment settings now? [y/N] " answer
    case $answer in
    [yY])
      e_bkp
      ;;
    [nN])
      printf "\n$ITA%s $OFF%s\n\n" "(no backup made... OK)"
      ;;
    *)
      printf "\n$ITA%s $OFF%s\n\n" "(no backup made... OK)"
      ;;
    esac
  fi
}

rstrt_e() {
  if [ "$XDG_CURRENT_DESKTOP" == "Enlightenment" ]; then
    enlightenment_remote -restart
  fi
}

build_plain() {
  sudo ln -sf /usr/lib64/preloadable_libintl.so /usr/lib/libintl.so
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/e25/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    case $I in
    efl)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || mng_err
      ;;
    enlightenment)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || mng_err
      ;;
    *)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || true
      ;;
    esac

    beep_attention
    $SNIN || true
    sudo ln -sf /usr/local/lib64/pkgconfig/* /usr/lib64/pkgconfig
    sudo ln -sf /usr/local/lib64/lib* /usr/lib64
    sudo ldconfig
  done

  for I in $PROG_AT; do
    cd $ESRC/e25/$I
    printf "\n$BLD%s $OFF%s\n\n" "Building $I..."

    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
  done
}

rebuild_plain() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  $REBASEF && git pull
  echo
  meson --libdir=/usr/local/lib64 --reconfigure -Dexample=false build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/e25/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    $REBASEF && git pull
    rm -rf build
    echo

    case $I in
    efl)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || mng_err
      ;;
    enlightenment)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || mng_err
      ;;
    *)
      meson --libdir=/usr/local/lib64 build
      ninja -C build || true
      ;;
    esac

    beep_attention
    $SNIN || true
    sudo ldconfig
  done

  for I in $PROG_AT; do
    cd $ESRC/e25/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    $REBASEF && git pull
    echo
    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
  done
}

rebuild_optim_mn() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  $REBASEF && git pull
  echo
  sudo chown $USER build/.ninja*
  meson configure --libdir=/usr/local/lib64 -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/e25/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    $REBASEF && git pull
    echo

    case $I in
    efl)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dnative-arch-optimization=true -Dfb=true \
        -Dharfbuzz=true -Dlua-interpreter=luajit -Delua=true -Dbindings=lua,cxx -Dbuild-tests=false -Dbuild-examples=false \
        -Devas-loaders-disabler= -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    enlightenment)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    *)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dbuildtype=release build
      ninja -C build || true
      ;;
    esac

    $SNIN || true
    sudo ldconfig
  done
}

rebuild_optim_at() {
  export CFLAGS="-O2 -ffast-math -march=native"

  for I in $PROG_AT; do
    cd $ESRC/e25/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    $REBASEF && git pull
    echo
    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
  done
}

rebuild_wld_mn() {
  if [ "$XDG_SESSION_TYPE" == "tty" ] && [ "$XDG_CURRENT_DESKTOP" == "Enlightenment" ]; then
    printf "\n$BDR%s $OFF%s\n\n" "PLEASE LOG IN TO THE DEFAULT DESKTOP ENVIRONMENT TO EXECUTE THIS SCRIPT."
    beep_exit
    exit 1
  fi

  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  bin_deps
  e_tokens

  cd $ESRC/rlottie
  printf "\n$BLD%s $OFF%s\n\n" "Updating rlottie..."
  git reset --hard &>/dev/null
  $REBASEF && git pull
  echo
  sudo chown $USER build/.ninja*
  meson configure --libdir=/usr/local/lib64 -Dexample=false -Dbuildtype=release build
  ninja -C build || true
  $SNIN || true
  sudo ldconfig

  for I in $PROG_MN; do
    cd $ESRC/e25/$I
    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    git reset --hard &>/dev/null
    $REBASEF && git pull

    case $I in
    efl)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dnative-arch-optimization=true -Dfb=true \
        -Dharfbuzz=true -Dlua-interpreter=luajit -Delua=true -Dbindings=lua,cxx -Ddrm=true -Dwl=true -Dopengl=es-egl \
        -Dbuild-tests=false -Dbuild-examples=false \
        -Devas-loaders-disabler= -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    enlightenment)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dwl=true -Dbuildtype=release build
      ninja -C build || mng_err
      ;;
    *)
      sudo chown $USER build/.ninja*
      meson configure --libdir=/usr/local/lib64 -Dbuildtype=release build
      ninja -C build || true
      ;;
    esac

    $SNIN || true
    sudo ln -sf /usr/local/lib64/pkgconfig/* /usr/lib64/pkgconfig
    sudo ln -sf /usr/local/lib64/lib* /usr/lib64
    sudo ldconfig
  done
}

rebuild_wld_at() {
  export CFLAGS="-O2 -ffast-math -march=native"

  for I in $PROG_AT; do
    cd $ESRC/e25/$I

    printf "\n$BLD%s $OFF%s\n\n" "Updating $I..."
    sudo make distclean &>/dev/null
    git reset --hard &>/dev/null
    $REBASEF && git pull
    echo
    $GEN
    make || true
    beep_attention
    $SMIL || true
    sudo ldconfig
  done
}

do_tests() {
  if [ -x /usr/bin/wmctrl ]; then
    if [ "$XDG_SESSION_TYPE" == "x11" ]; then
      wmctrl -r :ACTIVE: -b add,maximized_vert,maximized_horz
    fi
  fi

  printf "\n\n$BLD%s $OFF%s\n" "System check..."

  if systemd-detect-virt -q --container; then
    printf "\n$BDR%s %s\n" "IGGY.SH IS NOT INTENDED FOR USE INSIDE CONTAINERS."
    printf "$BDR%s $OFF%s\n\n" "SCRIPT ABORTED."
    beep_exit
    exit
  fi

  git ls-remote https://git.enlightenment.org/core/efl.git HEAD &>/dev/null
  if [ $? -ne 0 ]; then
    printf "\n$BDR%s %s\n" "REMOTE HOST IS UNREACHABLE——TRY AGAIN LATER"
    printf "$BDR%s $OFF%s\n\n" "OR CHECK YOUR INTERNET CONNECTION."
    beep_exit
    exit 1
  fi

  [[ ! -d $HOME/.cache/ebuilds ]] && mkdir -p $HOME/.cache/ebuilds
}

do_bsh_alias() {
  if [ ! -f $HOME/.bash_aliases ]; then
    touch $HOME/.bash_aliases

    cat >$HOME/.bash_aliases <<EOF
    # ----------------
    # GLOBAL VARIABLES
    # ----------------

    # Compiler and linker flags added by iggy.
    export CC="ccache gcc"
    export CXX="ccache g++"
    export USE_CCACHE=1
    export CCACHE_COMPRESS=1
    export CPPFLAGS=-I/usr/local/include:/usr/include
    export LDFLAGS=-L/usr/local/lib64
    export PKG_CONFIG_PATH=/usr/local/lib64/pkgconfig:/usr/local/lib/pkgconfig:/usr/lib64/pkgconfig

    # Parallel build.
    export MAKE="make -j$(($(nproc) * 2))"
EOF

    source $HOME/.bash_aliases

    cat >>$HOME/.bashrc <<EOL

    # Added by iggy.
    if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
    fi
EOL

    source $HOME/.bashrc
  fi
}

set_p_src() {
  echo
  beep_attention
  # Do not append a trailing slash (/) to the end of the path prefix.
  read -p "Please enter a path to the Enlightenment source folders \
  (e.g. /home/jamie/Documents or /home/jamie/testing): " mypath
  mkdir -p "$mypath"/sources
  ESRC="$mypath"/sources
  echo $ESRC >$HOME/.cache/ebuilds/storepath
  printf "\n%s\n\n" "You have chosen: $ESRC"
  sleep 2
}

get_preq() {
  ESRC=$(cat $HOME/.cache/ebuilds/storepath)
  cd $DLDIR
  printf "\n\n$BLD%s $OFF%s\n\n" "Installing prerequisites..."

  cd $ESRC
  git clone https://github.com/Samsung/rlottie.git
  cd $ESRC/rlottie
  meson --libdir=/usr/local/lib64 build
  ninja -C build || true
  $SNIN || true
  sudo ln -sf /usr/local/lib64/pkgconfig/rlottie.pc /usr/lib64/pkgconfig
  sudo ldconfig
  echo
}

do_lnk() {
  sudo ln -sf /usr/local/etc/enlightenment/sysactions.conf /etc/enlightenment/sysactions.conf
  sudo ln -sf /usr/local/etc/enlightenment/system.conf /etc/enlightenment/system.conf
  sudo ln -sf /usr/local/etc/xdg/menus/e-applications.menu /etc/xdg/menus/e-applications.menu
}

do_wl_lnk() {
  sudo mkdir -p /usr/include/xkbcommon
  sudo ln -sf /usr/include/wayland/wayland-util.h /usr/include/wayland-util.h
  sudo ln -sf /usr/include/wayland/wayland-client-core.h /usr/include/wayland-client-core.h
  sudo ln -sf /usr/include/wayland/wayland-version.h /usr/include/wayland-version.h
  sudo ln -sf /usr/include/wayland/wayland-client.h /usr/include/wayland-client.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon.h /usr/include/xkbcommon/xkbcommon.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon-x11.h /usr/include/xkbcommon/xkbcommon-x11.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon-names.h /usr/include/xkbcommon/xkbcommon-names.h
  sudo ln -sf /usr/include/wayland/wayland-client-protocol.h /usr/include/wayland-client-protocol.h
  sudo ln -sf /usr/include/wayland/wayland-cursor.h /usr/include/wayland-cursor.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon-keysyms.h /usr/include/xkbcommon/xkbcommon-keysyms.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon-compat.h /usr/include/xkbcommon/xkbcommon-compat.h
  sudo ln -sf /usr/include/wayland/wayland-server.h /usr/include/wayland-server.h
  sudo ln -sf /usr/include/wayland/wayland-server-core.h /usr/include/wayland-server-core.h
  sudo ln -sf /usr/include/wayland/wayland-server-protocol.h /usr/include/wayland-server-protocol.h
  sudo ln -sf /usr/include/libinput/libinput.h /usr/include/libinput.h
  sudo ln -sf /usr/include/libxkbcommon/xkbcommon/xkbcommon-compose.h /usr/include/xkbcommon/xkbcommon-compose.h
  sudo ldconfig
}

install_now() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* INSTALLING ENLIGHTENMENT DESKTOP: PLAIN BUILD *"
  beep_attention
  do_bsh_alias
  bin_deps
  set_p_src
  get_preq

  cd $HOME
  mkdir -p $ESRC/e25
  cd $ESRC/e25

  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching source code from the Enlightenment git repositories..."
  $CLONEFL
  echo
  $CLONETY
  echo
  $CLONE25
  echo
  $CLONEPH
  echo
  $CLONERG
  echo
  $CLONEVI
  echo
  $CLONEVE
  echo
  $CLONEXP
  echo
  $CLONECR
  printf "\n\n$BLD%s $OFF%s\n\n" "Fetching source code from vtorri's github repo..."
  $CLONENT
  echo

  ls_dir
  build_plain

  printf "\n%s\n\n" "Almost done..."

  mkdir -p $HOME/.elementary/themes

  sudo mkdir -p /etc/enlightenment
  do_lnk

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  printf "\n\n$BDY%s %s" "Initial setup wizard tips:"
  printf "\n$BDY%s %s" "'Update checking' —— you can disable this feature because it serves no useful purpose."
  printf "\n$BDY%s $OFF%s\n\n\n" "'Network management support' —— Connman is not needed."
  # Enlightenment adds three shortcut icons (namely home.desktop, root.desktop and tmp.desktop)
  # to your Desktop, you can safely delete them if it bothers you.

  echo
  cowsay "Now reboot your computer then select Enlightenment on the login screen... \
  That's All Folks!"
  echo

  cp -f $DLDIR/iggy.sh $HOME/bin
}

update_go() {
  clear
  printf "\n$BDG%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: PLAIN BUILD *"

  cp -f $SCRFLR/iggy.sh $HOME/bin
  chmod +x $HOME/bin/iggy.sh
  sleep 1

  rebuild_plain

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  if [ -f /usr/share/wayland-sessions/enlightenment.desktop ]; then
    sudo rm -rf /usr/share/wayland-sessions/enlightenment.desktop
  fi

  sudo updatedb
  beep_ok
  rstrt_e
  echo
  cowsay -f www "That's All Folks!"
  echo
}

release_go() {
  clear
  printf "\n$BDC%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: RELEASE BUILD *"

  cp -f $SCRFLR/iggy.sh $HOME/bin
  chmod +x $HOME/bin/iggy.sh
  sleep 1

  rebuild_optim_mn
  rebuild_optim_at

  sudo ln -sf /usr/local/share/xsessions/enlightenment.desktop \
    /usr/share/xsessions/enlightenment.desktop

  if [ -f /usr/share/wayland-sessions/enlightenment.desktop ]; then
    sudo rm -rf /usr/share/wayland-sessions/enlightenment.desktop
  fi

  sudo updatedb
  beep_ok
  rstrt_e
  echo
  cowsay -f www "That's All Folks!"
  echo
}

wld_go() {
  clear
  printf "\n$BDP%s $OFF%s\n\n" "* UPDATING ENLIGHTENMENT DESKTOP: WAYLAND BUILD *"

  cp -f $SCRFLR/iggy.sh $HOME/bin
  chmod +x $HOME/bin/iggy.sh
  sleep 1

  do_wl_lnk
  rebuild_wld_mn
  rebuild_wld_at

  sudo mkdir -p /usr/share/wayland-sessions
  sudo ln -sf /usr/local/share/wayland-sessions/enlightenment.desktop \
    /usr/share/wayland-sessions/enlightenment.desktop

  sudo updatedb
  beep_ok

  if [ "$XDG_SESSION_TYPE" == "x11" ] || [ "$XDG_SESSION_TYPE" == "wayland" ]; then
    echo
    cowsay -f www "Now log out of your existing session and press Ctrl+Alt+F3 to switch to tty3, \
        then enter your credentials and type: enlightenment_start"
    echo
    # Wait a few seconds for the Wayland session to start.
    # When you're done, type exit
    # Pressing Ctrl+Alt+F7 will bring you back to the login screen.
  else
    echo
    cowsay -f www "That's it. Now type: enlightenment_start"
    echo
  fi
}

main() {
  trap '{ printf "\n$BDR%s $OFF%s\n\n" "KEYBOARD INTERRUPT."; exit 130; }' INT

  INPUT=0
  printf "\n$BLD%s $OFF%s\n" "Please enter the number of your choice:"
  sel_menu

  if [ $INPUT == 1 ]; then
    do_tests
    install_now
  elif [ $INPUT == 2 ]; then
    do_tests
    update_go
  elif [ $INPUT == 3 ]; then
    do_tests
    release_go
  elif [ $INPUT == 4 ]; then
    do_tests
    wld_go
  else
    beep_exit
    exit 1
  fi
}

main

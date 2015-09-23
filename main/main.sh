#! /bin/bash

ARGS=() #ARGS="$@"

if [ $# -gt 0 ]; then
  while [ "$1" != "" ]; do
    ARGS=("${ARGS[@]}" "$1") # ARGS+=($1)
    shift
  done
fi

SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

U=malex984
I=dockapp
#
PREFIX="$U/$I"

if [ -z "$HIP" ]; then 
  HIP=$(ip route show 0.0.0.0/0 | grep -Eo 'via \S+' | awk '{ print $2 }')
  # HIP=$(netstat -rn | grep "^0.0.0.0 " | cut -d " " -f10)
  export HIP
fi

echo
echo "Current System: `uname -a` (HOST IP: $HIP)"
echo "Current User: `id`"
#USER_UID=$(id -u)
#set
#env

echo

XSOCK=/tmp/.X11-unix/
#X="XAUTHORITY"

if [ ! -z "$XAUTHORITY" ]; then 
  export XAUTHORITY=/tmp/.docker.xauth
fi

case "$OSTYPE" in
 linux*) # For Linux host with X11:

   if [[ -d "$XSOCK" ]] && [[  "$DISPLAY" =~ ^:[0-9]+ ]]; then
     echo "Forwarding X11 via xauth..."

     if [ ! -f $XAUTHORITY ]; then
        touch $XAUTHORITY
        xauth nlist :0 | sed -e "s/^..../ffff/" | xauth -f $XAUTHORITY nmerge -
     fi
     echo "We now enable anyone to connect to this X11..."
     xhost +
     xcompmgr &
     compton &
     # X="DISPLAY -e XAUTHORITY"
   else
# Detect a Virtual Box VM!?
     echo "Please start one of X11 servers before using any GUI apps... "
#     X="NODISPLAY=1"
## TODO: start X11 server here??
   fi
 ;;

 darwin*) # our X11 host ip on Mac OS X via boot2docker:
  echo "TO BE TESTED!!!! Will probaby not work via Boot2Docker for now... Sorry! :("
  echo

  export DISPLAY="192.168.59.3:0"
#  export X="DISPLAY"
  ## $(boot2docker ip) ## ???
  echo "Please make sure to start xsocat.sh from your local X11 server since xeys's X-client will use '-e $X'..."
  echo "X11 should 'Allow connections from network clients & Your firewall should not block incomming connections to X11'"
#  # X11 instead of XQuartz? Xpara?
  open -a XQuartz # --args xterm $PWD/xsocat.sh #?
 ;;
esac

#echo "Will use the following X11 settings: "
#echo "'$X'"
#
# pass CUPS_SERVER if previously set
#if [ ! -z "$CUPS_SERVER" ]; then
#  X="$X -e CUPS_SERVER"
#fi 
#
#export X

echo "Current docker images: "
docker images

echo "Current docker containers: "
docker ps -a
echo


## options for /sbin/my_init:
#OPTS="--skip-startup-files --no-kill-all-on-exit --quiet --skip-runit"
## options for running terminal apps via docker run:
#RUNTERM="--rm -it  -a stdin -a stdout -a stderr"

echo
echo "This is the main glue loop running on ${HOSTNAME}:"
# uname -a

### Handle all possible settings

if [ -r $SELFDIR/settings ]; then
  source $SELFDIR/settings
fi

### infinite loop... 
# mygetenv
main 30

while :
do
 
 echo "Current X: [$X]"
 echo "_____ XID: [$XID]"
 
 ### TODO: CHECK FOR X11 OR MAKE SURE XID & DISPLAY ARE VALID!

 ### TODO: add a choice to go to text mode!!!!
 
 if [ ! ${#ARGS[@]} -gt 0 ]; then
   $SELFDIR/menu.sh \
     "Your choice please?" 200 \
     "A_Test_Application_A LIBGL_CUSTOMIZATION Alsa_Test GUI_Shell Bash_in_MainGlueApp X11_Shell X11Server Xephyr Iceweasel Q3 Skype Cups_Server Media_Players Surfer Test CHANGE_SETTINGS Kiosk X11vnc Xvfb QUIT"
   ARGS=("$?")
 fi
 echo "Current command(s) to be processed first: ${ARGS[@]}"

 APP="${ARGS[0]}" # get 1st  array element
 ARGS=("${ARGS[@]:1}") # remove it from array

 mygetenv

 echo "Processing command '$APP'..."

 case "$APP" in

    219)
      if [ ! -z "$XID" ]; then
        echo "There seems to be our X11 container running already..."
      else
        unset DISPLAY
        echo "Starting virtual X11: Xvfb... "
	export X="$X -e XCMD=Xvfb "
        XID=$($SELFDIR/sv.sh 'dummy' startXephyr.sh -screen 0 800x600x16)
        echo "XID: $XID"

        while :
        do
          sleep 3
	  docker logs $XID 2>&1 | grep DISPLAY
          export DISPLAY=$(docker logs $XID 2>&1 | grep DISPLAY_NUM | tail -n 1 | sed s@DISPLAY_NUM@@g)
	  if [ -z "$DISPLAY" ]; then
	  if [ -r /tmp/x.id ]; then
  	    export DISPLAY=$(cat /tmp/x.id)
          fi	    
	  fi
        ### XAUTH?
	  if [ ! -z "$DISPLAY" ]; then
	    break;
	  fi  
	done 
     fi
    ;;


    218) # x11vnc
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting x11vnc service ... " 
        XVNC=$($SELFDIR/sv.sh 'x11vnc' x11vnc.sh)
        echo "XVNC: $XVNC"
      else
        echo "Please start X11 beforehand!"
      fi
    ;;
    
    217) # Kiosk
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting Kiosk-Mode WebBrowser ... " && $SELFDIR/run.sh 'kiosk' launch.sh 
	#  /usr/lib/node_modules/kiosk/run.sh
	# "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash" ## xterm?
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    216) # Settings Menu!
      main 40
    ;;

    215)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting GUI shell for test... Please build test yourself... " && $SELFDIR/run.sh 'test' launch.sh
	# "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash" ## xterm?
      else
        echo "Please start X11 beforehand!"
      fi
    ;;
    
    214)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting GUI shell for surfer... Please build surfer yourself... " 
	$SELFDIR/run.sh "surfer" launch.sh 
	# /opt/SURFER/SURFER
#	$SELFDIR/run.sh "$PREFIX:appchoo" bash
        # "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash"
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    213)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting GUI shell... Please run cmus/vlc/mplaye/xine yourself... " && $SELFDIR/run.sh "play" launch.sh
        # "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash"
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    212)
      echo "Starting cups... " && $SELFDIR/run.sh "cups" bash -c 'config_cups.sh && bash'
#start_cups.sh
    ;;

    211)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting skype... " && $SELFDIR/run.sh "skype" skype.sh
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    210)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting Q3... "
 	$SELFDIR/run.sh "q3" /usr/games/openarena
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    209)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting iceweasel/firefox?... "
	$SELFDIR/run.sh "iceweasel" firefox
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    208)
      if [ ! -z "$XID" ]; then
        echo "There seems to be our X11 container running already..."
      else
        echo "Starting X11: Xephyr using $DISPLAY... "
	export X="$X -e XCMD=Xephyr "
        XID=$($SELFDIR/sv.sh 'dummy' startXephyr.sh)
        echo "XID: $XID"
	
        while :
        do
          sleep 3
	  docker logs $XID 2>&1 | grep DISPLAY
          export DISPLAY=$(docker logs $XID 2>&1 | grep DISPLAY_NUM | tail -n 1 | sed s@DISPLAY_NUM@@g)
	  if [ -z "$DISPLAY" ]; then
	  if [ -r /tmp/x.id ]; then  
  	    export DISPLAY=$(cat /tmp/x.id)
          fi	    
	  fi
        ### XAUTH?
	  if [ ! -z "$DISPLAY" ]; then
	    break;
	  fi  
	done 
      fi
    ;;

    207)
      if [ ! -z "$XID" ]; then
        echo "There seems to be our X11 container running already..."
      else
        unset DISPLAY
        echo "Starting X11: Xorg... "
#	export X="$X -e XCMD=Xephyr "
        XID=$($SELFDIR/sv.sh 'dummy' startXephyr.sh)
        echo "XID: $XID"

        while :
        do
          sleep 3
	  docker logs $XID 2>&1 | grep DISPLAY
          export DISPLAY=$(docker logs $XID 2>&1 | grep DISPLAY_NUM | tail -n 1 | sed s@DISPLAY_NUM@@g)
	  if [ -z "$DISPLAY" ]; then
	  if [ -r /tmp/x.id ]; then
  	    export DISPLAY=$(cat /tmp/x.id)
          fi	    
	  fi
        ### XAUTH?
	  if [ ! -z "$DISPLAY" ]; then
	    break;
	  fi  
	done 
     fi
    ;;

    206)
      if [ ! -z "$DISPLAY" ]; then
        echo "starting X11-SHELL for testing... " 
   	$SELFDIR/run.sh "xeyes" xterm || $SELFDIR/run.sh "xeyes" bash
        # "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash"
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    201)
      	echo "Starting AppA1... "
	$SELFDIR/A.sh "AAAAAAAAAAAAAA!"
    ;;

    202)
      echo "Generating /tmp/OGL.tgz with the use of malex984/dockapp:dummy... "
      $SELFDIR/generate_ogl.sh "malex984/dockapp:dummy" /tmp/OGL.tgz
      
    ;;

    203)
      echo "Starting Alsa sound test on plughw:0,0/1... " 
      $SELFDIR/run.sh "alsa" soundtest.sh
    ;;

   204)
      if [ ! -z "$DISPLAY" ]; then
        echo "Starting gui shell (with X11-apps)... "
	$SELFDIR/run.sh "gui" launch.sh
        # "rxvt-unicode -fn xft:terminus:pixelsize=12 -e bash"
      else
        echo "Please start X11 beforehand!"
      fi
    ;;

    205)
      echo "Starting BASH..." && bash
    ;;





    *)
      echo
      echo "Thank You!"
      echo
      echo "Quiting... please make sure to kill any services yourself... "
      
      if [ ! -z "$XID" ]; then
        echo "Don't forget to kill X11 docker container: $XID"
        echo "DISPLAY: $DISPLAY"
####        docker rm -vf $XID #### TODO: GRACEFULL X11 SHUTDOWN???
      fi
      echo "Leftover containers: "
      docker ps -a
      
      exit 0
    ;;
  esac

  RET="$?"
  echo "Exit code was: $RET... Any now back to the choice menu:"
done




################ TODO: don't mount all of /dev/! Try to make use of the necessary devices only!

# -v /dev/shm:/dev/shm \
# -v /etc/machine-id:/etc/machine-id \
# -v /var/lib/dbus:/var/lib/dbus \
# -v /run/dbus/system_bus_socket:/run/dbus/system_bus_socket \
# -v /var/run/docker.sock:/var/run/docker.sock \
# -e DOCKER_HOST=unix:///var/run/docker.sock -e NO_PROXY=/var/run/docker.sock \
# -v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket \
# -v /sys/fs/cgroup:/sys/fs/cgroup \
# -v /run/user/${USER_UID}/pulse:/run/user/${USER_UID}/pulse \
# -v /run/user/${USER_UID}/pulse:/run/pulse \
# -v /home/vagrant:/home/docker \
# -v /dev/dri:/dev/dri \
# --device=/dev/video0:/dev/video0 \
# -v /dev/snd:/dev/snd "
# -e PULSE_SERVER=/run/user/${USER_UID}/pulse/native \
#      docker run -it --name sound \
#        --privileged \
#       -e $SND \
#       --lxc-conf='lxc.cgroup.devices.allow=c 226:* rwm' \
#       --lxc-conf='lxc.cgroup.devices.allow=c 81:* rwm' \
#       --lxc-conf='lxc.cgroup.devices.allow=c 116:* rwm' \
#      "$U/$I:sound" /sbin/setuser ur /bin/bash

#echo "Pulling necessary images: "
#docker pull "$U/$I:base"
#docker pull "$U/$I:dd"
#docker pull "$U/$I:main"
#docker pull "$U/$I:menu"
#docker pull "$U/$I:appa"
#docker pull "$U/$I:alsa"
#docker pull "$U/$I:xeyes"
#docker pull "$U/$I:gui"
#docker pull "$U/$I:x11"
#docker pull "$U/$I:skype"
#docker pull "$U/$I:q3"
#docker pull "$U/$I:iceweasel"
#docker pull "$U/$I:cups"

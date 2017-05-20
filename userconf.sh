#!/bin/bash

## Set defaults for environmental variables in case they are undefined
USER=${USER:=docker}
PASSWORD=${PASSWORD:=docker}
USERID=${USERID:=1000}
GROUPID=${GROUPID:=1000}
GROUPNAME=${GROUPNAME:=usergroup}
ROOT=${ROOT:=FALSE}


if [ "$USERID" -ne 1000 ]
## Configure user with a different USERID if requested.
  then
    #echo "deleting user docker"
    #userdel docker
    echo "creating new $USER with UID $USERID"
    groupadd -g $GROUPID $GROUPNAME
    useradd -m $USER -u $USERID -g $GROUPID
    mkdir -p /home/$USER
    chown -R $USER /home/$USER
    usermod -a -G staff $USER
    if [ ! -d "/home/$USER/.c9" ]; then 
    	cp -r /templates/.c9 /home/$USER
    	chown -R $USER /home/$USER/.c9
    fi
elif [ "$USER" != "docker" ]
  then
    ## cannot move home folder when it's a shared volume, have to copy and change permissions instead
    cp -r /home/docker /home/$USER
    ## RENAME the user   
    usermod -l $USER -d /home/$USER docker
    groupmod -n $USER docker
    usermod -a -G staff $USER
    chown -R $USER:$USER /home/$USER
    echo "USER is now $USER"  
fi
  
## Add a password to user
echo "$USER:$PASSWORD" | chpasswd

# Use Env flag to know if user should be added to sudoers
if [ "$ROOT" == "TRUE" ]
  then
    adduser $USER sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
    echo "$USER added to sudoers"
fi

echo export HOME=/home/$USER >/home/$USER/c9.env
echo export C9_DIR=/home/$USER/.c9 >>/home/$USER/c9.env
echo export PATH="/home/$USER/.c9/node/bin/:/home/$USER/.c9/node_modules/.bin:$PATH" >>/home/$USER/c9.env
echo export DOCKER_HOST=dind:2375 >>/home/$USER/c9.env

/usr/sbin/sshd
munged
su -l -c "source /home/$USER/c9.env && node /c9/server.js -w /home/$USER --listen 0.0.0.0 -a $USER:$PASSWORD" $USER

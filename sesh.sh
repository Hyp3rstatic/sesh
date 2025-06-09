#!/bin/bash

export PROJECTSESSIONS=$HOME'/.projectsessions'

if [[ -f $PROJECTSESSIONS'/current' ]]; then
  export CURRENTPROJECTSESSIONID=$(cat $PROJECTSESSIONS/current)
else
  export CURRENTPROJECTSESSIONID=0
fi

function sesh {
  
  #makes sure .projectsessions directory and associated files is created
  if [[ ! -d $PROJECTSESSIONS ]]; then
    mkdir $PROJECTSESSIONS
    export CURRENTPROJECTSESSIONID=0
    touch $PROJECTSESSIONS/current
    echo "${CURRENTPROJECTSESSIONID}" >> $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/idlist
  fi
  
  #ensure idlist file exists
   if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
    touch $PROJECTSESSIONS/idlist
  fi
  
  #enusre current file exists
  if [[ ! -f $PROJECTSESSIONS/current ]]; then
    touch $PROJECTSESSIONS/current
  fi

  #view the sesh directory
  if [[ $1 = 'ls' ]]; then
    ls $PROJECTSESSIONS

  #get the id of the session file in use
  elif [[ $1 = 'current' ]]; then
    cat $PROJECTSESSIONS/current

  #print all the ids in use
  elif [[ $1 = 'ids' ]]; then
    cat $PROJECTSESSIONS/idlist

  #unalias all the shortcuts in the current session file
  elif [[ $1 = 'unal' ]]; then
    if [[ $CURRENTPROJECTSESSIONID -ne 0 ]]; then
      while IFS= read -r line; do
      unalias $(echo $line | awk -F'=' '{print$1}' | awk '{print $2}')
      done < <(grep "alias" $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID)
    fi
  
  #set sesh to have no current session file and unalias all shortcuts
  elif [[ $1 = 'unset' ]]; then
    sesh 'unal'
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    echo "0" >> $PROJECTSESSIONS/current
    
  #set the session file in use to the specified id
  #***add name support later
  elif [[ $1 = 'seti' ]]; then
    #DELETE OLD ALIASES
    sesh 'unal'

    #UPDATE CURRENT
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    export CURRENTPROJECTSESSIONID=$2
    echo "${CURRENTPROJECTSESSIONID}" >> $PROJECTSESSIONS/current
    sesh 'ref'

  elif [[ $1 = 'set' ]]; then
    id=$(grep $2'|' $PROJECTSESSIONS/idlist | cut -d: -f1)
    echo $id
    sesh seti $id
  
  elif [[ $1 = 'ref' ]]; then
    #id=$(grep "SESSION_ID:" $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID | tail -n 1)
    #id=$(echo $id | awk '{print $NF}')
    source $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID

  #add a cd to the current dir with an alias of $2 in the set session file
  elif [[ $1 = 'add' ]]; then
    echo "alias ${2}='cd ${PWD}'" >> $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID
    sesh 'ref'

  #delete session file
  elif [[ $1 = 'del' ]]; then
    echo "deleting session file at ${PROJECTSESSIONS}/${CURRENTPROJECTSESSIONID}"
    sesh 'unal'
    rm $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID
    id_line=$(grep -n $CURRENTPROJECTSESSIONID $PROJECTSESSIONS/idlist | cut -d : -f 1)
    echo $id_line
    sed $id_line'd' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist
    sesh 'unset'    

  #nickname a session file
  elif [[ $1 = 'nick' ]]; then
    sed 's/'$CURRENTPROJECTSESSIONID':/'$CURRENTPROJECTSESSIONID':'$2'|''/' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist

  #create a new session file
  elif [[ $1 = 'new' ]]; then
    #create random id between 1000 and 9999
    session_id=$((RANDOM % 9000 + 1000))
    #check that id is not in use
    #if the random id is in use, look for an unused id starting from 1000
    if grep -q $session_id':' $PROJECTSESSIONS/idlist; then
      session_id=1000
    fi
    while grep -q $session_id':' $PROJECTSESSIONS/idlist; do
      echo "id ${session_id} already exists"
      session_id=$((session_id+1))
      if [[ $session_id -eq 10000 ]]; then
        echo 'maximum number of saved sessions exceeded, cannot create a new session until another is deleted'
        break
      fi
    done
    if [[ $session_id -ne 10000 ]]; then #only create new session file if id does not exceed max
      touch $PROJECTSESSIONS/$session_id
      echo -e "created new session file at ${PROJECTSESSIONS}/${session_id}\nSESSION ID: ${session_id}"
      echo "#SESSION_ID: ${session_id}" >> $PROJECTSESSIONS/$session_id
      echo $session_id':' >> $PROJECTSESSIONS/idlist
    fi
  
  #view the contents of the session file in use
  elif [[ $1 = 'view' && $CURRENTPROJECTSESSIONID -ne 0 ]]; then
    cat $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID
  
  fi
}

#To enable aliases when opening terminal
sesh 'ref'


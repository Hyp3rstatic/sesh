#!/bin/bash

export PROJECTSESSIONS=$HOME'/.projectsessions' #set dotfolder env var

#source shortcut profiles in use
for line in $(cat $PROJECTSESSIONS/current); do
  source $PROJECTSESSIONS/$(echo "$line" | cut -d ':' -f 1)
  echo $line #DEBUG
done

function sesh {

  #ensure .projectsessions directory exists
  if [[ ! -d $PROJECTSESSIONS ]]; then
    mkdir $PROJECTSESSIONS
  fi
  
  #ensure idlist file exists
  if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
    touch $PROJECTSESSIONS/idlist
  fi
  
  #ensure current file exists
  if [[ ! -f $PROJECTSESSIONS/current ]]; then
    touch $PROJECTSESSIONS/current
  fi

  #view the sesh directory
  if [[ $1 = 'list' ]]; then
    ls $PROJECTSESSIONS

  #get the ids of the session files in use
  elif [[ $1 = 'current' ]]; then
    cat $PROJECTSESSIONS/current

  #print all profile ids and their nicks
  elif [[ $1 = 'ids' ]]; then
    cat $PROJECTSESSIONS/idlist

  #view the contents of the specified profile 
  elif [[ $1 = 'view' ]]; then
    cat $PROJECTSESSIONS/$(sesh 'getid' $2)
  
  #unalias all the shortcuts in specific profile
  elif [[ $1 = 'unal' ]]; then
    while IFS= read -r line; do
    unalias $(echo $line | awk -F'=' '{print$1}' | awk '{print $2}')
    done < <(grep "alias" $PROJECTSESSIONS/$2)

  #stop using specified shortcut profile 
  elif [[ $1 = 'unset' ]]; then
    sesh 'unal' $(sesh 'getid' $2)
    id_line=$(grep -n $(sesh 'getid' $2) $PROJECTSESSIONS/current | cut -d : -f 1)
    echo $id_line
    sed $id_line'd' $PROJECTSESSIONS/current > $PROJECTSESSIONS/tmp_current && mv $PROJECTSESSIONS/tmp_current $PROJECTSESSIONS/current

  #get the id associated with a nick
  elif [[ $1 = 'getid' ]]; then
    id=$(grep $2'|' $PROJECTSESSIONS/idlist | cut -d: -f1)
    echo $id

  #set sesh to have no current session file and unalias all shortcuts
  elif [[ $1 = 'blank' ]]; then
    for line in $(cat $PROJECTSESSIONS/current); do
      sesh 'unal' $(echo $line | tr -d '[:space:]')
    done
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    
  #unset all sesssion profiles except the one specified
  elif [[ $1 = 'setx' ]]; then
    sesh 'unset'
    echo "$(sesh 'getid' $2)" >> $PROJECTSESSIONS/current
    sesh 'ref'

  #use a shortcut profile
  elif [[ $1 = set ]]; then
    echo $(sesh 'getid' $2) >> $PROJECTSESSIONS/current
    sesh 'ref'
 
  #source the aliases of profiles in current - making them usable 
  elif [[ $1 = 'ref' ]]; then
    for line in $(cat $PROJECTSESSIONS/current); do
      source $PROJECTSESSIONS/$(echo $line | tr -d '[:space:]')
      echo $line #DEBUG
    done
  
  #add a cd alias to to current directory of the user in the specified shortcut profile
  #TODO: update make use of nick
  elif [[ $1 = 'add' ]]; then
    echo "alias ${2}='cd ${PWD}'" >> $PROJECTSESSIONS/$(sesh 'getid' $3)
    sesh 'ref'
  
  #delete specified session file
  #TODO: delete from current file as well
  elif [[ $1 = 'del' ]]; then
    id=$(sesh 'getid' $2)
    echo "deleting session file at ${PROJECTSESSIONS}/${id}"
    sesh 'unal' $id
    rm $PROJECTSESSIONS/$id
    id_line=$(grep -n $id $PROJECTSESSIONS/idlist | cut -d : -f 1)
    echo $id_line
    sed $id_line'd' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist

  #nickname a session file
  elif [[ $1 = 'nick' ]]; then
    sed 's/'$3':/'$3':'$2'|''/' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist

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
  
  fi
}

#to enable aliases when opening terminal
sesh 'ref'


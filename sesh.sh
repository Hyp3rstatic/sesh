#!/bin/bash

export PROJECTSESSIONS=$HOME'/.projectsessions' #set dotfolder env var

#source shortcut profiles in use
if [[ -f $PROJECTSESSIONS/current ]]; then
  for line in $(cat $PROJECTSESSIONS/current); do
    source $PROJECTSESSIONS/$(echo "$line" | cut -d ':' -f 1)
  done
fi

function sesh {

  #ensure .projectsessions directory exists
  if [[ ! -d $PROJECTSESSIONS ]]; then
    mkdir $PROJECTSESSIONS
    echo "created directory at $PROJECTSESSIONS"
  fi
  
  #ensure idlist file exists
  if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
    touch $PROJECTSESSIONS/idlist
    echo "created file at $PROJECTSESSIONS/idlist"
  fi
  
  #ensure current file exists
  if [[ ! -f $PROJECTSESSIONS/current ]]; then
    touch $PROJECTSESSIONS/current
    echo "created file at $PROJECTSESSIONS/current"
  fi

  # START ARGS

  #TODO: ADD HELP

  #view the sesh directory
  if [[ $1 = 'list' ]]; then
    if [[ ! -d $PROJECTSESSIONS ]]; then
      echo "directory $PROJECTSESSIONS does not exist"
      return
    fi
    ls $PROJECTSESSIONS

  #go to the shortcut directory
  elif [[ $1 = 'go' ]]; then
    if [[ ! -d $PROJECTSESSIONS ]]; then
      echo "directory $PROJECTSESSIONS does not exist"
      return
    fi
    cd $PROJECTSESSIONS

  #get the ids and nicks of the profiles in use
  elif [[ $1 = 'current' ]]; then
    if [[ ! -f $PROJECTSESSIONS/current ]]; then
      echo "file $PROJECTSESSIONS/current does not exist"
      return
    fi 
    if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
      echo "file $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    for line in $(cat $PROJECTSESSIONS/current); do
      echo $(grep $line $PROJECTSESSIONS/idlist)
    done
  
  #print all profile ids and their nicks
  elif [[ $1 = 'ids' ]]; then
    if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
      echo "file $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    cat $PROJECTSESSIONS/idlist

  #print the contents of all profiles in use
  elif [[ $1 = 'contents' ]]; then
    if [[ ! -f $PROJECTSESSIONS/current ]]; then
      echo "file $PROJECTSESSIONS/current does not exist"
      return
    fi
    echo ' '
    for line in $(cat $PROJECTSESSIONS/current); do
      id=$(echo $line | awk -F':' '{print$1}')
      if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
        echo "file $PROJECTSESSIONS/idlist does not exist"
      else
        grep $id $PROJECTSESSIONS/idlist
      fi
      if [[ ! -f $PROJECTSESSIONS/$id ]]; then
        echo "file ${PROJECTSESSIONS}/${id} does not exist"
      else
        cat $PROJECTSESSIONS/$id
      fi
      echo ' '
    done

  #view the contents of the specified profile 
  elif [[ $1 = 'view' && ! -z $2 ]]; then
    id=$(sesh 'getid' $2)
    err=$?
    if [[ $err -eq 100 ]]; then
      echo "getid failed: $err - $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    if [[ $err -eq 101 ]]; then
      echo "getid failed: $err - $id nick does not correspond to shortcut profile"
      return
    fi
    if [[ ! -f $PROJECTSESSIONS/$id ]]; then
      echo "file ${PROJECTSESSIONS}/${id} does not exist"
      return
    fi
    cat $PROJECTSESSIONS/$id
  
  #unalias all the shortcuts in specific profile
  elif [[ $1 = 'unal' && ! -z $2 ]]; then
    while IFS= read -r line; do 
      alias_name=$(echo $line | awk -F'=' '{print$1}' | awk '{print $2}')
      if [[ $(alias | grep $alias_name'=') = '' ]]; then
        echo "alias: $alias_name not in use"
      else
        unalias $alias_name
      fi
    done < <(grep "alias" $PROJECTSESSIONS/$2)

  #stop using specified shortcut profile 
  elif [[ $1 = 'unset' && ! -z $2 ]]; then
    id=$(sesh 'getid' $2)
    err=$?
    if [[ $err -eq 100 ]]; then
      echo "getid failed: $err - $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    if [[ $err -eq 101 ]]; then
      echo "getid failed: $err - $id nick does not correspond to shortcut profile"
      return
    fi
    if [[ $(grep $id $PROJECTSESSIONS/current) = '' ]]; then
      echo "shortcut profile not in use"
      return
    fi
    sesh 'unal' $id
    id_line=$(grep -n $(sesh 'getid' $2) $PROJECTSESSIONS/current | cut -d : -f 1)
    sed $id_line'd' $PROJECTSESSIONS/current > $PROJECTSESSIONS/tmp_current && mv $PROJECTSESSIONS/tmp_current $PROJECTSESSIONS/current

  #get the id associated with a nick
  elif [[ $1 = 'getid' && ! -z $2 ]]; then
    if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
      echo "file $PROJECTSESSIONS/idlist does not exist"
      return 100 #idlist does not exist
    fi
    id=$(grep $2'|' $PROJECTSESSIONS/idlist | cut -d: -f1)
    if [[ $id = '' ]]; then
      echo "'${2}' does not correspond to any shortcut profile"
      return 101
    fi
    echo $id

  #set sesh to have no current session file and unalias all shortcuts
  elif [[ $1 = 'blank' ]]; then
    for line in $(cat $PROJECTSESSIONS/current); do
      sesh 'unal' $(echo $line | tr -d '[:space:]')
    done
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    
  #unset all sesssion profiles except the one specified
  elif [[ $1 = 'setx' && ! -z $2 ]]; then
    sesh 'unset'
    echo "$(sesh 'getid' $2)" >> $PROJECTSESSIONS/current
    sesh 'ref'

  #use a shortcut profile
  elif [[ $1 = 'set' && ! -z $2 ]]; then
    id=$(sesh 'getid' $2)
    err=$?
    if [[ $err -eq 100 ]]; then
      echo "getid failed: $err - $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    if [[ $err -eq 101 ]]; then
      echo "getid failed: $err - $id nick does not correspond to shortcut profile"
      return
    fi
    if [[ $(grep $id $PROJECTSESSIONS/current) != '' ]]; then
      echo "shortcut profile is already in use"
      return
    fi
    echo $(sesh 'getid' $2) >> $PROJECTSESSIONS/current
    sesh 'ref'
 
  #source the aliases of profiles in current - making them usable 
  elif [[ $1 = 'ref' ]]; then
    for line in $(cat $PROJECTSESSIONS/current); do
      source $PROJECTSESSIONS/$(echo "$line" | cut -d ':' -f 1)
    done
  
  #add alias to specified path to a specified shortcut profile 
  elif [[ $1 = 'add' && ! -z $4 ]]; then
    id=$(sesh 'getid' $4)
    if [[ $(grep $3'=' $PROJECTSESSIONS'/'$id) != '' ]]; then
      echo "alias: '$3' is already in use by $4: $id"
      return
    fi
    path=$(readlink -f $2)
    echo "alias ${3}='cd ${path}'" >> $PROJECTSESSIONS/$(sesh 'getid' $4)
    sesh 'ref'
  
  #delete specified session file from idlist and current (if applicable)
  elif [[ $1 = 'del' && ! -z $2 ]]; then
    id=$(sesh 'getid' $2)
    echo "deleting session file at ${PROJECTSESSIONS}/${id}"
    sesh 'unal' $id
    rm $PROJECTSESSIONS/$id
    
    #remove id from idlist
    id_line=$(grep -n $id $PROJECTSESSIONS/idlist | cut -d : -f 1)
    sed $id_line'd' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist
    
    #remove id from current if it exists
    if  grep -q $id $PROJECTSESSIONS/current; then
      id_line=$(grep -n $id $PROJECTSESSIONS/current | cut -d : -f 1)
      sed $id_line'd' $PROJECTSESSIONS/current > $PROJECTSESSIONS/tmp_current && mv $PROJECTSESSIONS/tmp_current $PROJECTSESSIONS/current
    fi

  #nickname a session file
  elif [[ $1 = 'nick' && ! -z $3 ]]; then 
    if [[ $(grep "${2}|" $PROJECTSESSIONS/idlist) != '' ]]; then
      echo "nick: error 101 - '$2' is already in use by $(sesh 'getid' $2)"
      return 101
    fi
    sed 's/'$3':/'$3':'$2'|''/' $PROJECTSESSIONS/idlist > $PROJECTSESSIONS/tmp_idlist && mv $PROJECTSESSIONS/tmp_idlist $PROJECTSESSIONS/idlist

  #modify idlist
  elif [[ $1 = 'modlist' ]]; then
    if [[ ! -f $PROJECTSESSIONS/idlist ]]; then
      echo "file $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    vim $PROJECTSESSIONS/idlist

  #modify current
  elif [[ $1 = 'modcurr' ]]; then
    if [[ ! -f $PROJECTSESSIONS/current ]]; then
      echo "file $PROJECTSESSIONS/current does not exist"
      return
    fi 
    vim $PROJECTSESSIONS/current

  #modify specified profile
  elif [[ $1 = 'mod' ]]; then
    id=$(sesh 'getid' $2)
    err=$?
    if [[ $err -eq 100 ]]; then
      echo "getid failed: $err - $PROJECTSESSIONS/idlist does not exist"
      return
    fi
    if [[ $err -eq 101 ]]; then
      echo "getid failed: $err - $id nick does not correspond to shortcut profile"
      return
    fi
    vim $PROJECTSESSIONS/$id

  #create a new session file with nick
  elif [[ $1 = 'new' && ! -z $2 ]]; then
    
    #check if nick is already in use
    if [[ $(grep "${2}|" $PROJECTSESSIONS/idlist) != '' ]]; then
      echo "new: error 101 - '$2' is already in use by $(sesh 'getid' $2)"
      return 101
    fi

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
        echo "maximum number of saved sessions exceeded, cannot create a new session until another is deleted"
        break
      fi
    done

    if [[ $session_id -ne 10000 ]]; then #only create new session file if id does not exceed max
      touch $PROJECTSESSIONS/$session_id
      echo -e "created new session file at ${PROJECTSESSIONS}/${session_id}\nSESSION ID: ${session_id}"
      echo "#SESSION_ID: ${session_id}" >> $PROJECTSESSIONS/$session_id
      echo $session_id':' >> $PROJECTSESSIONS/idlist
    fi
    
    sesh 'nick' $2 $session_id
     
  fi
}


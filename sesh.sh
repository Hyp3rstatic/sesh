#!/bin/bash

export PROJECTSESSIONS=$HOME'/.projectsessions'

if [[ -f $PROJECTSESSIONS'/current' ]]; then
  export CURRENTPROJECTSESSIONID=$(cat $PROJECTSESSIONS/current)
else
  export CURRENTPROJECTSESSIONID=0
fi

function sesh {
  if [[ ! -d $PROJECTSESSIONS ]]; then
    mkdir $PROJECTSESSIONS
    export CURRENTPROJECTSESSIONID=0
    touch $PROJECTSESSIONS/current
    echo "${CURRENTPROJECTSESSIONID}" >> $PROJECTSESSIONS/current

  elif [[ $1 = 'ls' ]]; then
    ls $PROJECTSESSIONS

  elif [[ $1 = 'current' ]]; then
    cat $PROJECTSESSIONS/current

  elif [[ $1 = 'unal' ]]; then
    if [[ $CURRENTPROJECTSESSIONID -ne 0 ]]; then
      while IFS= read -r line; do
      unalias $(echo $line | awk -F'=' '{print$1}' | awk '{print $2}')
      done < <(grep "alias" $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID)
    fi
  
  elif [[ $1 = 'unset' ]]; then
    sesh 'unal'
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    echo "0" >> $PROJECTSESSIONS/current
    
  elif [[ $1 = 'set' ]]; then
    #DELETE OLD ALIASES
    sesh 'unal'

    #UPDATE CURRENT
    rm $PROJECTSESSIONS/current
    touch $PROJECTSESSIONS/current
    export CURRENTPROJECTSESSIONID=$2
    echo "${CURRENTPROJECTSESSIONID}" >> $PROJECTSESSIONS/current
    sesh 'ref'
  
  elif [[ $1 = 'ref' ]]; then
    #id=$(grep "SESSION_ID:" $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID | tail -n 1)
    #id=$(echo $id | awk '{print $NF}')
    source $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID

  elif [[ $1 = 'add' ]]; then
    echo "alias ${2}='cd ${PWD}'" >> $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID
    sesh 'ref'

  elif [[ $1 = 'del' ]]; then
    echo "deleted session file at ${PROJECTSESSIONS}/${CURRENTPROJECTSESSIONID}"
    rm $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID


  elif [[ $1 = 'new' ]]; then
    session_id=$((RANDOM % 9000 + 1001))
    touch $PROJECTSESSIONS/$session_id
    echo -e "created new session file at ${PROJECTSESSIONS}/${session_id}\nSESSION ID: ${session_id}"
    echo "#SESSION_ID: ${session_id}" >> $PROJECTSESSIONS/$session_id

  elif [[ $1 = 'view' && $CURRENTPROJECTSESSIONID -ne 0 ]]; then
    cat $PROJECTSESSIONS/$CURRENTPROJECTSESSIONID
  fi
}

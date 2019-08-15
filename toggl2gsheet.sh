#!/bin/bash

if [ -f /etc/profile.d/rvm.sh ] ; then
  . /etc/profile.d/rvm.sh
fi

LOG=log/toggl2sheet_`date +%Y%m%d`.log

echo `date +'%Y.%m.%d %H:%M:%S'` start >> $LOG
ruby toggl2gsheet.rb >> $LOG
echo `date +'%Y.%m.%d %H:%M:%S'` end >> $LOG

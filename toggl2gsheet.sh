#!/bin/bash

if [ -f /etc/profile.d/rvm.sh ] ; then
  . /etc/profile.d/rvm.sh
fi

ruby toggl2gsheet.rb

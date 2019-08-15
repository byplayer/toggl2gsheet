#!/bin/bash

if [ -f /etc/profile.d/rvm.sh ] ; then
  . /etc/profile.d/rvm.sh
fi

bundle install --path vendor

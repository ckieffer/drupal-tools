#!/bin/bash

###################################################################################################
#
#  Local and remote Drupal path and connection information
#
#  Author: Chad Kieffer, ckieffer at gmail dot com
#
#  Shared path and directory information for your Drupal 6 installation
#  For use with drupal_update.sh and drupal_module_update.sh
#
#  DO NOT INCLUDE TRAILING SLASHES ON PATHS!
#
###################################################################################################

DownloadsPath="/local/path/to/downloads"

LocalBase="/local/path"
LocalDrupal6="drupal-6"
LocalDrupal7="drupal-7"

RemoteBase="/remote/path"
RemoteDrupal6="drupal-6"
RemoteDrupal7="drupal-7"

SSHConnect="you@www.host.com"

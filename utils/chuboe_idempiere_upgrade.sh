#!/bin/bash

# Author
#   Chuck Boecking
#   chuck@chuboe.com
#   http://chuckboecking.com
# chuboe_idempiere_upgrade.sh
# 1.0 initial release

# NOTE: be aware that this script does not make a backup of the /opt/idempiere-server directory. 
# If the upgrade goes badly, you will need to have a way to restore your previous directory.
# Said another way, always perform this upgrade on a test server before executing on a production server.

# function to help the user better understand how the script works
usage()
{
cat << EOF

usage: $0

This script helps you upgrade your iDempiere server

OPTIONS:
	-h	Help
	-c	Specify connection options
	-m	Specify FILE path to migration scripts
	-M	Specify URL to migration scripts
	-u	Upgrade URL to p2 directory
	-r	Do not restart server
	-s	Skip iDempiere binary upgrade

Outstanding actions:
* check that a .hg file exists. If no, exit. They should have a backup to the binaries first.

EOF
}

SERVER_DIR="/opt/idempiere-server"
CHUBOE_UTIL="/opt/chuboe_utils/"
CHUBOE_UTIL_HG="$CHUBOE_UTIL/idempiere-installation-script/"
CHUBOE_UTIL_HG_PROP="$CHUBOE_UTIL_HG/utils/properties/"
ID_DB_NAME="idempiere"
PG_CONNECT="-h localhost"
MIGRATION_DIR=$CHUBOE_UTIL_HG"/chuboe_temp/migration"
# get JENKINSPROJECT varialble from properties file
JENKINSPROJECT=$(cat $CHUBOE_UTIL_HG_PROP/"JENKINS_PROJECT.txt")
IDEMPIERE_VERSION=$(cat $CHUBOE_UTIL_HG_PROP/"IDEMPIERE_VERSION.txt")
IS_RESTART_SERVER="Y"
IS_GET_MIGRATION="Y"
IS_SKIP_BIN_UPGRADE="N"
MIGRATION_DOWNLOAD="http://jenkins.idempiere.com/job/$JENKINSPROJECT/ws/migration/*zip*/migration.zip"
P2="http://jenkins.idempiere.com/job/$JENKINSPROJECT/ws/buckminster.output/org.adempiere.server_"$IDEMPIERE_VERSION".0-eclipse.feature/site.p2/"

# process the specified options
# the colon after the letter specifies there should be text with the option
while getopts "hc:m:M:u:rs" OPTION
do
	case $OPTION in
		h)	usage
			exit 1;;

		c)	#Specify connection options
			PG_CONNECT=$OPTARG;;

		m)	#Specify FILE path to unzipped migration scripts
			IS_GET_MIGRATION="N"
			MIGRATION_DIR=$OPTARG;;

		M)	#Specify URL to migration scripts zip
			MIGRATION_DOWNLOAD=$OPTARG;;

		u)	#Upgrade URL to p2
			P2=$OPTARG;;

		r)	#Do not restart server
			IS_RESTART_SERVER="N";;

		s)	#Do not upgrade binaries
			IS_RESTART_SERVER="N"
			IS_SKIP_BIN_UPGRADE="Y";;
	esac
done

# show variables to the user (debug)
echo "if you want to find for echoed values, search for HERE:"
echo "HERE: print variables"
echo "SERVER_DIR="$SERVER_DIR
echo "P2="$P2
echo "ID_DB_NAME="$ID_DB_NAME
echo "PG_CONNECT="$PG_CONNECT
echo "MIGRATION_DIR="$MIGRATION_DIR
echo "MIGRATION_DOWNLOAD="$MIGRATION_DOWNLOAD
echo "IS_RESTART_SERVER="$IS_RESTART_SERVER
echo "IS_GET_MIGRATION="$IS_GET_MIGRATION
echo "IS_SKIP_BIN_UPGRADE="$IS_SKIP_BIN_UPGRADE
echo "JENKINSPROJECT="$JENKINSPROJECT
echo "IDEMPIERE_VERSION="$IDEMPIERE_VERSION

#TODO Check if idempiere is running
#If running - notify user and exit

# Get migration scripts from daily build if none specified
if [[ $IS_GET_MIGRATION == "Y" ]]
then
	cd $CHUBOE_UTIL_HG/chuboe_temp
	RESULT=$(ls -l migration.zip | wc -l)
	if [ $RESULT -ge 1 ]; then
		echo "HERE: migration.zip already exists"
		rm -r migration*
	fi #end if migration.zip exists
	wget $MIGRATION_DOWNLOAD
	unzip migration.zip
fi #end if IS_GET_MIGRATION = Y

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere stop
fi #end if IS_RESTART_SERVER = Y

if [[ $IS_SKIP_BIN_UPGRADE == "N" ]]
then
	# update iDempiere binaries
	cd $SERVER_DIR
	./update.sh $P2
fi #end if IS_SKIP_BIN_UPGRADE = N

# create a database backup just in case things go badly
cd $SERVER_DIR/utils/
sh RUN_DBExport.sh

cd $CHUBOE_UTIL_HG/utils/

# run upgrade db script
./syncApplied.sh $ID_DB_NAME "$PG_CONNECT" $MIGRATION_DIR

if [[ $IS_RESTART_SERVER == "Y" ]]
then
	sudo service idempiere start
fi #end if IS_RESTART_SERVER = Y
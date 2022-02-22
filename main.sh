#!/bin/bash
#@autor:https://github.com/victorlaguna

export PATH=/bin:/usr/bin:/usr/local/bin
TODAY=`date +"%d%b%Y"`
DB_BACKUP_PATH='backup'
PWD=`pwd`
HOME=$(echo ~)

################################################################
################## Configuration values  ########################
clear
echo "THE FOLLOWING SCRIPT REMOTELY BACKS UP THE MYSQL DATABASE"
echo "next the script will restore the backup to the selected target" 
echo "IMPORTANT if a database exists on the previous target it will be deleted!"
echo "If you do not want to lose the database please backup before"
echo "Do you want to continue? y/n"
read name1
if [[ $name1 = 'y' ]] || [[ $name1 = 'Y' ]]; then
    clear 
    echo selecciono continuar
else
    exit 1
fi

########## Verify if EXIST the MYSQL Client ################
ispresentmysql=$(type mysql >/dev/null 2>&1 && echo "MySQL esta presente." || echo "MySQL NO esta presente.")
present="MySQL esta presente."
if [[ "$ispresentmysql" == "$present" ]]; then
    echo "`date`: La instalacion del cliente de ${ispresentmysql}"
else
    echo "`date`: La instalacion del cliente de ${ispresentmysql}"
    echo "`date`: por favor instale el cliente de MySQL"
fi

####### input values ############
echo "Enter the host where the backup will taken:"
read MYSQL_HOST
echo "Enter the port of the host where the backup will be taken:"
read MYSQL_PORT
echo "Enter the DB name where the backup will taken:"
read MYSQL_DB
echo "Enter the user name where the backup will taken:"
read MYSQL_USER
echo "Enter the user pass where the backup will taken:"
read MYSQL_PASS

####### output restores values ############
echo "Enter the host where the backup will RESTORE:"
read MYSQL_HOST_TEST
echo "Enter the port of the host where the backup will be RESTORE:"
read MYSQL_PORT_TEST
echo "Enter the DB name where the backup will RESTORE:"
read MYSQL_DB_TEST
echo "Enter the user name where the backup will RESTORE:"
read MYSQL_USER_TEST
echo "Enter the user pass where the backup will RESTORE:"
read MYSQL_PASS_TEST

################ Backup ##############################
mkdir -p ${HOME}/${DB_BACKUP_PATH}/${TODAY}
echo "`date`: Backup from DB - ${MYSQL_DB} - remote"
echo "`date`: you can find the backup on the next directory -> ${HOME}/${DB_BACKUP_PATH}/${TODAY}"
mysqldump -h ${MYSQL_HOST} \
-P ${MYSQL_PORT} \
-u ${MYSQL_USER} \
-p${MYSQL_PASS} \
${MYSQL_DB}| sed -e 's/DEFINER[ ]*=[ ]*[^*]*\*/\*/'|grep -v 'Warning' > ${HOME}/${DB_BACKUP_PATH}/${TODAY}/${MYSQL_DB}-${TODAY}".sql"

############# verify if backup is ok ##########
if [ $? -eq 0 ]; then
  echo "`date`: Database backup completed"
else
  echo "`date`: Error cant backup"
  exit 1
fi

##############################################################
############### restoring the base ############################
##############################################################
########### verify if the database exists ##############
answer=$(mysql -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_PASS_TEST} -e "use ${MYSQL_DB};")
if [[ "$answer" == *"Unknown database"* ]]; then
    echo "`date`: the database DOES NOT EXIST, the database will be created $MYSQL_DB, creating user $MYSQL_USER and restoring"
    mysql -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_PASS_TEST} -e "create database ${MYSQL_DB};"
    mysql -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_PASS_TEST} ${MYSQL_DB} -e "source ${HOME}/${DB_BACKUP_PATH}/${TODAY}/${MYSQL_DB}-${TODAY}.sql"
    if [ $? -eq 0 ]; then
        clear
        echo the database was created and restored with success
    else
        echo database could not be created
    fi
else
    echo "`date`: The database EXISTS, we will proceed to delete the current one and then restore the push database from the remote backup"
    echo "`date`: do you want to continue y/n"
    read name1
    if [[ $name1 = 'y' ]] || [[ $name1 = 'Y' ]]; then
        clear
        echo "you selected continue" 
    else
        exit 1
    fi
    yes|mysqladmin -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_ROOT_PASSWORD} drop ${MYSQL_DB}
    clear
    mysql -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_ROOT_PASSWORD} -e "create database ${MYSQL_DB};"
    mysql -h ${MYSQL_HOST_TEST} -u ${MYSQL_USER_TEST} -p${MYSQL_PASS_TEST} ${MYSQL_DB} -e "source ${HOME}/${DB_BACKUP_PATH}/${TODAY}/${MYSQL_DB}-${TODAY}.sql"
    if [ $? -eq 0 ]; then
        clear
        echo base was created and restored successfully
    else
        echo failed to create the base
    fi
fi
exit
echo "`date`: script end"
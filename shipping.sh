#!/bin/bash

set -euo pipefail
trap 'echo "this is error messag $LINENO, command is $BASH_COMMAND"'  ERR

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log
SCRIPT_DIR=$PWD
mkdir -p $LOGS_FOLDER
echo "Script started executed at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo "ERROR:: Please run this script with root privelege"
    exit 1 # failure is other than 0
fi

VALIDATE(){ # functions receive inputs through args just like shell script args
    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N" | tee -a $LOG_FILE
    fi
} 

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "installed mavan"
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "user permission"
else 
echo "user already exist"
fi
mkdir -p /app 
curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>>$LOG_FILE
cd /app 
rm -rf /app/*
unzip -o /tmp/shipping.zip &>>$LOG_FILE
mvn clean package 
mv target/shipping-1.0.jar shipping.jar 

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service &>>$LOG_FILE

systemctl daemon-reload &>>$LOG_FILE

systemctl enable shipping &>>$LOG_FILE
VALIDATE $? "enabled shipping"
systemctl start shipping &>>$LOG_FILE
VALIDATE $? "started shipping"
dnf install mysql -y 
VALIDATE $? "installed mysql" &>>$LOG_FILE

mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/schema.sql
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/app-user.sql 
mysql -h <MYSQL-SERVER-IPADDRESS> -uroot -pRoboShop@1 < /app/db/master-data.sql
systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarted shipping" 
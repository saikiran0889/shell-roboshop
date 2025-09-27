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

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "disable nodejs"
dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enable nodejs"
dnf install nodejs -y >>$LOG_FILE
VALIDATE $? "install nodejs"
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "user permission"
mkdir /app >>$LOG_FILE
VALIDATE $? "making the app folder"
curl -L -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "download nodejs"
cd /app 
unzip /tmp/user.zip 
VALIDATE $? "unzip the code"

npm install >>$LOG_FILE
VALIDATE $? "install packages"
cp $SCRIPT_NAME/user.service /etc/systemd/system/user.service &>>$LOG_FILE
systemctl daemon-reload >>$LOG_FILE
systemctl enable user >>$LOG_FILE
VALIDATE $? "enable user service"
systemctl start user >>$LOG_FILE
VALIDATE $? "start user service"
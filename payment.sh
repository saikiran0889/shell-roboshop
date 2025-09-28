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


dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "installed Pyton"
if [ $? -ne 0 ]; then
useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
VALIDATE $? "user permission"
else
echo "user already exist"
fi
mkdir -p /app 
VALIDATE $? "created app directory"
curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip 
cd /app 
rm -rf /app/*
VALIDATE $? "Removing existing code"
unzip -o /tmp/payment.zip &>>$LOG_FILE
pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "install packages"
cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service

systemctl daemon-reload &>>$LOG_FILE

systemctl enable payment  &>>$LOG_FILE
VALIDATE $? "enable payment"
systemctl start payment &>>$LOG_FILE
VALIDATE $? "start payment"
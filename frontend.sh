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


dnf module disable nginx -y &>>$LOG_FILE
VALIDATE $? "Diabled nginx"
dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "enabled nginx"
dnf install nginx -y &>>$LOG_FILE
VALIDATE $? "installed nginx"
systemctl enable nginx &>>$LOG_FILE
VALIDATE $? "enabled nginx"
systemctl start nginx &>>$LOG_FILE
VALIDATE $? "start the nginx"
rm -rf /usr/share/nginx/html/* &>>$LOG_FILE
VALIDATE $? "remove the default config nginx"
curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE

cd /usr/share/nginx/html &>>$LOG_FILE
unzip -o /tmp/frontend.zip &>>$LOG_FILE
VALIDATE $? "unzip the frontend nginx"
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf &>>$LOG_FILE
VALIDATE $? "copy nginx"
systemctl restart nginx &>>$LOG_FILE
VALIDATE $? "restart nginx"
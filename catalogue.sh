#!/bin/bash

USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
SCRIPT_DIR=$PWD
MONGODBHOST=mongodb.awsdevops2025.fun
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log" # /var/log/shell-script/16-logs.log

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

dnf module disable nodejs -y &>>LOG_FILE
VALIDATE $? "disable nodejs"
dnf module enable nodejs:20 -y &>>LOG_FILE
VALIDATE $? "enable nodejs"
dnf install nodejs -y &>>LOG_FILE
VALIDATE $? "install nodejs" 

# id roboshop
# if[ $? -ne 0 ]; then
# useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
# else
# echo -e "user has already created... $Y skipped $N"
# fi


id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating system user"
else
    echo -e "User already exist ... $Y SKIPPING $N"
fi



mkdir -p /app 
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
cd /app 
rm -rf /add/* &>>$LOG_FILE
unzip /tmp/catalogue.zip &>>$LOG_FILE
VALIDATE $? "Removing existing code"
npm install &>>LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
systemctl daemon-reload

systemctl enable catalogue 
VALIDATE $? "enable catalogue"
systemctl start catalogue
VALIDATE $? "start catalogue"
cp $SCRIPT_DIRmongo.repo /etc/yum.repos.d/mongo.repo


dnf install mongodb-mongosh -y &>>LOG_FILE
VALIDATE $? "install mongodb"
INDEX=$(mongosh mongodb.daws86s.fun --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")
if [ $INDEX -le 0 ]; then
mongosh --host $MONGODBHOST </app/db/master-data.js &>>LOG_FILE
   VALIDATE $? "Load catalogue products"
else
    echo -e "Catalogue products already loaded ... $Y SKIPPING $N"
fi
systemctl restart catalogue
VALIDATE $? "restart catalogue"



#!/bin/bash

set -euo pipefail

trap 'echo "There is an error in LINENO, Command is: $BASH_COMMAND"' ERR

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
MONGODB_HOST=mongodb.daws86.cloud

mkdir -p $LOGS_FOLDER
echo "Script started executed at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R Error:: Please run this script with root privilages $N"
    exit 1
fi  

#### NodeJS Installation ####

dnf module disable nodejs -y &>>$LOG_FILE
dnf module enable nodejs:20 -y &>>$LOG_FILE
dnf install nodejs -y &>>$LOG_FILE
echo -e "Installing NodeJS 20 ... $G Success $N"

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    
 else
    echo -e "User already exists ... $Y SKIPPIN $N" | tee -a $LOG_FILE
fi   

mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE

cd /app 
rm -rf /app/* &>>$LOG_FILE

unzip /tmp/catalogue.zip &>>$LOG_FILE
npm install &>>$LOG_FILE
cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service &>>$LOG_FILE

systemctl daemon-reload
systemctl enable catalogue &>>$LOG_FILE
echo -e "Catalogue application setup ... $G Success $N"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
dnf install mongodb-mongoshwert -y &>>$LOG_FILE

INDEX=$(mongosh mongodb.daws86.cloud --quiet --eval "db.getMongo().getDBNames().indexOf('catalogue')")

if [ $INDEX -le 0 ]; then
    mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOG_FILE
    
 else
  echo -e "Catalogue products already exist in MongoDB ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

systemctl restart catalogue
echo -e"Loading products and restarting catalogue ... $G Success $N"

 
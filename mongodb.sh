#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

LOGS_FOLDER="/var/log/shell-roboshop"
SCRIPT_NAME=$( echo $0 | cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD
START_TIME=$(date +%s)

mkdir -p $LOGS_FOLDER
echo "Script started executed at : $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]; then
    echo -e "$R Error:: Please run this script with root privilages $N"
    exit 1
fi  

VALIDATE(){

    if [ $1 -ne 0 ]; then
        echo -e "$2 ... $R Failed $N" | tee -a $LOG_FILE
        exit 1
    else
        echo -e "$2 ... $G Successful $N" | tee -a $LOG_FILE
    fi
}
 
 cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo &>>$LOG_FILE
 VALIDATE $? "Adding Mongo repo"

 dnf install mongodb-org -y &>>$LOG_FILE
 VALIDATE $? "Installing MongoDB"

 systemctl enable mongod &>>$LOG_FILE
 VALIDATE $? "Enable MongoDB"

 systemctl start mongod &>>$LOG_FILE
 VALIDATE $? "Start MongoDB"

 sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod. conf &>>$LOG_FILE
 VALIDATE $? "Allowing remote connections to MongoDB"

 systemctl restart mongod &>>$LOG_FILE
  VALIDATE $? "Restarting MongoDB"
  



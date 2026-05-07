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
MONGODB_HOST=mongodb.daws86.cloud
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
        echo -e "$2 ... $G Success $N" | tee -a $LOG_FILE
    fi
}


#### NodeJS Installation ####

dnf module disable nodejs -y &>>$LOG_FILE
VALIDATE $? "Disable NodeJS"

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "Enable NodeJS 20"

dnf install nodejs -y &>>$LOG_FILE
VALIDATE $? "Installing NodeJS" 

id roboshop &>>$LOG_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating a system user for roboshop"
 else
    echo -e "User already exists ... $Y SKIPPIN $N" | tee -a $LOG_FILE
fi   

mkdir -p /app 
VALIDATE $? "Creating a app directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading User application code"

cd /app 
VALIDATE $? "Changing to app directory"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing existing code"

unzip /tmp/user.zip &>>$LOG_FILE
VALIDATE $? "Unzip the User code"

npm install &>>$LOG_FILE
VALIDATE $? "Installing nodejs dependencies for User"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service &>>$LOG_FILE
VALIDATE $? "Copying systemctl service file"

systemctl daemon-reload

systemctl enable user &>>$LOG_FILE
VALIDATE $? "Enabling user service"

systemctl start user &>>$LOG_FILE
VALIDATE $? "Starting User service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME seconds $N"



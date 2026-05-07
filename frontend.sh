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

dnf module disable nginx -y  &>>$LOG_FILE
VALIDATE $? "Disabling existing Nginx module"

dnf module enable nginx:1.24 -y &>>$LOG_FILE
VALIDATE $? "Enabling Nginx module"

dnf install nginx -y  &>>$LOG_FILE
VALIDATE $? "Installing Nginx"

systemctl enable nginx  &>>$LOG_FILE
VALIDATE $? "Enabling Nginx service"

systemctl start nginx  &>>$LOG_FILE
VALIDATE $? "Starting Nginx service"

rm -rf /usr/share/nginx/html/* 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>$LOG_FILE

cd /usr/share/nginx/html 

unzip /tmp/frontend.zip  &>>$LOG_FILE
VALIDATE $? "Downloading and extracting Frontend code"

rm -rf /etc/nginx/nginx.conf   
VALIDATE $? "Removing existing Nginx configuration file"

cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf 
VALIDATE $? "Copying Nginx configuration file"

nginx -t &>>$LOG_FILE
VALIDATE $? "Testing Nginx configuration"

systemctl restart nginx
VALIDATE $? "Restarting Nginx service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME seconds $N"




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

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing Python3 and dependencies"


useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating a system user for roboshop"


mkdir /app 
ValiDATE $? "Creating a app directory"

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>>$LOG_FILE
ValiDATE $? "Downloading Payment application code"

cd /app 
VALIDATE $? "Changing directory to /app"

rm -rf /app/*  &>>$LOG_FILE
VALIDATE $? "Removing existing Payment application code"


unzip /tmp/payment.zip &>>$LOG_FILE
VALIDATE $? "Extracting Payment application code"

pip3 install -r requirements.txt &>>$LOG_FILE
VALIDATE $? "Installing Payment application dependencies"

cp $SCRIPT_DIR/payment.service /etc/systemd/system/payment.service  &>>$LOG_FILE
VALIDATE $? "Copying Payment systemd service file"

systemctl daemon-reload
VALIDATE $? "Reloading systemd daemon"

systemctl enable payment &>>$LOG_FILE
VALIDATE $? "Enabling Payment service"

systemctl restart payment  &>>$LOG_FILE  
VaLIDATE $? "Starting Payment service"
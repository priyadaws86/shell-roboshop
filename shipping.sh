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
MYSQL_HOST=mysql.daws86.cloud

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

dnf install maven -y &>>$LOG_FILE
VALIDATE $? "Installing Maven"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
VALIDATE $? "Creating a system user for roboshop"

mkdir /app &>>$LOG_FILE
VALIDATE $? "Creating a app directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading Shipping application code"

cd /app 

rm -rf /app/*  &>>$LOG_FILE
VALIDATE $? "Removing existing Shipping application code"

unzip /tmp/shipping.zip &>>$LOG_FILE
VALIDATE $? "Extracting Shipping application code"

 
mvn clean package &>>$LOG_FILE
VALIDATE $? "Building Shipping application code"

mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming Shipping application jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service
VALIDATE $? "Copying Shipping service file"

systemctl daemon-reload

systemctl enable shipping &>>$LOG_FILE    
VALIDATE $? "Enabling Shipping service"

systemctl start shipping &>>$LOG_FILE
VALIDATE $? "Starting Shipping service"

dnf install mysql -y &>>$LOG_FILE
VaLIDATE $? "Installing MySQL client"


mysql -h MYSQL_HOST -uroot -pRoboShop@1 -e 'use cities'
 if [ $? -ne 0 ]; then
       mysql -h MYSQL_HOST -uroot -pRoboShop@1 < /app/db/schema.sql
       mysql -h MYSQL_HOST -uroot -pRoboShop@1 < /app/db/app-user.sql 
       mysql -h MYSQL_HOST -uroot -pRoboShop@1 < /app/db/master-data.sql

else
         echo -e "Shipping database already exists ... $Y SKIPPING $N"
     fi

systemctl restart shipping &>>$LOG_FILE
VaLIDATE $? "Restarting Shipping service"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))
echo -e "Script executed in: $Y $TOTAL_TIME seconds $N"

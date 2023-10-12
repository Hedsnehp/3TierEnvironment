# 3TierEnvironment
Challenge #1
A 3-tier environment is a common setup. Use a tool of your choosing/familiarity create these resources. Please remember we will not be judged on the outcome but more focusing on the approach, style and reproducibility.

3-tier Solution :

Overview : The Solution includes Web Servers, Application Servers and Database Servers.Following best practices for running a 3 tier common environmrnt setup in Cloud/on-perm given Architecture model will help to achive the build/setup.
This repository contains code for a 3 tier architecture.
It uses terraform to create Infra over AWS cloud and deploys a basic apache server. The repo has two file main.tf and install_apache.sh to install apache server on the instances and create a unique landing page for each so that we can verify the ALB is working.
MANUAL STEPS:
VPC creation
Public and Private creation
Route tables
edit subnet associations
Internet gateway creation | Attach to VPC 
Nat-gateway creation 
Creation of load balancer
Edit routes : IG --> Web server | Nat Gateway --> App server
Creating EC2 instances as per the private and public subnets as web server , app server & Db server 
Connect to web server using keypair 
Then connect to rest two App server instances and iinstall PHP and Apache : https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html
Then validate thrpugh using ALB DNS : check test page is coming 
Then do shh -i "keypair*" ec2-user@IP of app server 1
cd /var/www/html/ ---> echo "php server 1" >>index.html
You will see desired results .
Create RDS db and Autoscaling group (for high availability)

END


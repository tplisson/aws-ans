# VPC Flow Logs

### VPC Flow Logs to monitor traffic to a web server deployed using Terraform and clout-init
Terraform config file for the webserver EC2 instance and associated VPC Flow Log profile: [`main.tf`](main.tf)

[cloud-init](https://learn.hashicorp.com/tutorials/terraform/cloud-init) initialization for a simple Python web server based on the EC2 Ubuntu server (for those like me who don't have access to the AWS AMI marketplace):
[`cloud-init-script-webserver.yaml`](cloud-init-script-webserver.yaml)

---

In your web browser, navigate to the Public IP address of your EC2 instance to verify that your app was actually deployed.  

You can also SSH to the EC2 instance:  
```
ssh -i key lab@$(terraform output -raw instance_public_ip)
```

### CloudWatch Logging

Check the flow logs in CloudWatch after a few minutes.
You should see logs such as this:
```
-------------------------------------------------------------------------------------------------------------------------------------------
|   timestamp   |                                                         message                                                         |
|---------------|-------------------------------------------------------------------------------------------------------------------------|
| 1617789312000 | 2 416496057868 eni-0aa22b3f1bb9a1209 91.163.25.152 10.10.10.10 5813 80 6 6 678 1617789312 1617789366 ACCEPT OK          |
| 1617789312000 | 2 416496057868 eni-0aa22b3f1bb9a1209 10.10.10.10 91.163.25.152 80 12268 6 5 1059 1617789312 1617789366 ACCEPT OK        |
| 1617789312000 | 2 416496057868 eni-0aa22b3f1bb9a1209 162.142.125.150 10.10.10.10 30909 17780 6 1 44 1617789312 1617789366 REJECT OK     |
| 1617789312000 | 2 416496057868 eni-0aa22b3f1bb9a1209 91.163.25.152 10.10.10.10 2122 22 6 40 5837 1617789312 1617789486 ACCEPT OK        |
| 1617789312000 | 2 416496057868 eni-0aa22b3f1bb9a1209 10.10.10.10 91.163.25.152 22 2122 6 32 6582 1617789312 1617789486 ACCEPT OK        |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 45.227.254.10 10.10.10.10 10196 22 6 4 204 1617789366 1617789426 ACCEPT OK         |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 162.142.125.152 10.10.10.10 39638 2222 6 1 44 1617789366 1617789426 REJECT OK      |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 45.227.254.10 10.10.10.10 56472 22 6 12 1740 1617789366 1617789426 ACCEPT OK       |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 185.236.11.7 10.10.10.10 48787 33900 6 1 40 1617789366 1617789426 REJECT OK        |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 10.10.10.10 45.227.254.10 22 56472 6 11 1994 1617789366 1617789426 ACCEPT OK       |
| 1617789366000 | 2 416496057868 eni-0aa22b3f1bb9a1209 10.10.10.10 45.227.254.10 22 10196 6 3 206 1617789366 1617789426 ACCEPT OK         |
-------------------------------------------------------------------------------------------------------------------------------------------  

```

<p align="center">
<img src="https://d2908q01vomqb2.cloudfront.net/da4b9237bacccdf19c0760cab7aec4a8359010b0/2019/09/13/2019-08-13_10-41-04.png">
</p>
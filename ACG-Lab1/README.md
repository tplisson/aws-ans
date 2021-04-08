# ACG Lab 1 - Multi-Subnet VPC with Secure Access to Private Servers with Outbound Internet Access

[Lab 1 Diagram](ACG-Lab1.png)

### VPC 
Terraform config file: [`main.tf`](main.tf)

[cloud-init](https://learn.hashicorp.com/tutorials/terraform/cloud-init) initialization for a simple Python web server based on the EC2 Ubuntu server (for those like me who don't have access to the AWS AMI marketplace):
[`cloud-init-script-webserver.yaml`](cloud-init-script-webserver.yaml)

---


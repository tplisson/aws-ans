# DNS Route53 Lab

cmcloudlab1634.info

## Setup

AWS configuration settings and credentials, using the AWS cli:
```
aws configure
```

Create SSH keys for the EC2 instances:
```
ssh-keygen -C "lab@example.com" -f key
```

## Terraform 
Terraform config file: 

- [`main.tf`](main.tf) file main set of configuration
- [`variables.tf`](variables.tf) file provides the values for the various CIDR ranges and IP adddresses.
- [`outputs.tf`](outputs.tf) file allows to output the public IP address of the Bastion Host

Initialize and apply the Terraform code:
```
terraform init

terraform apply -auto-approve
```

## Results

Ping each web server:
```
ping -c 3 $(terraform output -raw instance_public_ip)
```

Ping each web server:
```
ping -c 3 <YOUR-DNS-FQDN>
ping -c 3 www.<YOUR-DNS-FQDN>
```

In your browser, navigate to `www.<YOUR-DNS-FQDN>` and refresh several times the page to verify that the HTTP requests are distributed in a round robin fashion. 

---
## Tasks:
- Create the VPC skeleton
    - Create a VPC with two public subnets.
- Create the Internet Gateway, then a public and a private route table
    - Create an Internet Gateway and attach it to the VPC. 
    - Create a public route table with a default route to the internet gateway and create a private route table.
- Configure the web servers
    - Create a Security Group for the web servers.
    - Set up two Amazon EC2 instances `web1` and `web2` that each run a simple static website on Python
- Configure Route53 records for `www.<YOUR-DNS-FQDN>`
    - Create an A record for `web1` instance as a weighted routing policy 
    - Create an A record for `web2` instance as a weighted routing policy
- Verify the HTTP requests are load balanced between the two instances.


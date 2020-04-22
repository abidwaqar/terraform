# Terraform
Automated the making of infrastructure on AWS using terraform.



Automated the following tasks:

1. Created two public subnets in different availability zones. Named them **public_subnet_1** and **public_subnet_2**.

2. Create two private subnets in different availability zones. Named them **private_subnet_1** and **private_subnet_2.**

3. Created a security group named **project-sg-1** which allows inbound traffic for port 22 and port 80 from 0.0.0.0/0.

4. Created a key pair named **project_key_pair**

5. Created a launch template with following specifications. 

| Resource       | Selection                                |
| -------------- | ---------------------------------------- |
| AMI            | Amazon Linux 2 (64 bit x86)              |
| Instance Type  | t2-micro                                 |
| VPC            | Default                                  |
| Security Group | project-sg-1                             |
| Key Pair       | paroject_key_pair                        |
| User data      | Added a file automation.sh in this field |

6. Created an autoscaling group using the created launch template and private subnets. In config select, kept it to initial size.

7. Created a target group and attached this target group to the autoscaling group.

8. Created application load balancer and selected existing target group for load balancer.

9. Voila!!!
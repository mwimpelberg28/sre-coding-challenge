# Flask App Deployed to EKS Via Jenkins
## Terraform
1. Build a VPC in AWS with two availibility zones each with a public and private subnet.  The private subnets are not accessible from outside but can reach the internet through NAT gateways.
2. Deploy an EC2 instance and use the user data script to completely configure an installation of Jenkins complete with a pipeline job.  An A record in route53 is defined to point to the public IP of the Jenkins EC2 instance.
3. Build an ECR repository and EKS cluster that spans across availability zones for application HA.  The code also deploys a helm chart to install the nginx ingress controller which will help us reach our application.
## Jenkins Pipeline
Once the Jenkins instance is configured from the user_data script we find a pipeline already built which performs the following steps
1. Clone the git repository with our code
2. Builds the docker image for our application
3. Logs into ECR and pushes the image
4. Updates kubectl to log into our EKS cluster
5. Deploys application to EKS as a deployment with two replicas with a service in front of it and an ingress pointing to the service




# Requirements
1. You must have terraform and awscli installed
2. AWS credentials must be configured.  In my case I ran aws configure and entered my access key, secret key and region.

# Steps To Run
1. Update the ssh key and aws credential values that show REPLACEME in tf/ec2.yaml with the values for your environment

2. Update route53 DNS Zone ID in tf/route53.tf to reflect your environment and FQDN for jenkins

3. Navigate to terraform directory 
    ```bash
    cd tf
    ```
4. Initialize Terraform
   ```bash
   terraform init
   ```

5. Apply code after reviewing the plan that's automatically generated
   ```bash
   terraform apply
   ```

6. SSH to the instance and obtain the admin password
```bash
ssh -i SSHKEY ubuntu@jenkins.mwdevops.com
cat /var/lib/jenkins/secrets/initialAdminPassword
```

7. Navigate to the web ui at FQDN:8080

8. Log into Jenkins with admin and the value from /var/lib/jenkins/secrets/initialAdminPassword

9. Build scm-job

10. Log into your EKS cluster and run 
```bash
kubectl get svc
```
This will give you the load balancer DNS name for your ingress controller.  If you run curl <ALB>/test you will access the application that's been deployed.

11. To clean up, you can run the terminate script.  Update the terminate script to match the ecr name and region that you're using.  The ECR must be cleaned before terraform can destroy it which is why that script has to be run.
```bash
cd tf
bash terminate.sh
```

# Bonus
The xml file that I set up in the user data script has a token that can be used to trigger a build within a github webhook.  http://FQDN:8080/job/scmjob/build?token=TOKEN_NAME

All of the infrastructure is managed in Terraform.

Setting up monitoring in NewRelic for containers running Python involves nesting containers and without a license I didn't attempt this but did read the documentation.

# Areas for improvement
1. The user data script is not the place for sensitive credentials like aws access key/secret key pairs.  In my research I found a credential provider for Jenkins (https://plugins.jenkins.io/aws-credentials/) but it's not supported by CASC and thus I used secret strings.  In the future, I would set up the AWS credentials in the GUI.  The SSH key had the same issue.  I'd rather do this whole configuration with Ansible vs user_data but that's beyond the scope here :)
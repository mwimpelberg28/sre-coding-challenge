module "jenkins-0" {
  source          = "terraform-aws-modules/ec2-instance/aws"
  name            = var.ec2_name
  instance_type   = var.instance_size
  key_name        = var.key_name
  vpc_security_group_ids = [aws_security_group.jenkins.id]
  subnet_id       = module.vpc.public_subnets[0]
  associate_public_ip_address = true
  ami             = data.aws_ami.ubuntu.id
  root_block_device = [
    {
      encrypted   = true
      volume_type = "gp3"
      throughput  = 200
      volume_size = 50
    }
  ]
  user_data = <<EOF
#!/bin/bash
## Add ssh key
cat << EOSSH > /tmp/privatekey
REPLACEME
EOSSH

## Add docker-ce and  jenkins apt sources
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee \
  /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

## Update aptitude and install necessary packages
sudo apt update
sudo apt-get install openjdk-17-jdk openjdk-17-jre awscli apt-transport-https ca-certificates curl software-properties-common unzip jenkins docker-ce -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --update
snap install kubectl --classic

## Prevent issues ssh known hosts cloning from github
mkdir -p /var/lib/jenkins/.ssh
ssh-keyscan github.com >> /var/lib/jenkins/.ssh/known_hosts

## Configure jenkins to run docker and start the docker service
usermod -aG docker jenkins
sudo systemctl enable docker
sudo systemct start docker

## Start Jenkins, install plugins and create directory that will store our configuration as code files
sudo systemctl start jenkins
wget -O /jenkins-cli.jar http://localhost:8080/jnlpJars/jenkins-cli.jar
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin workflow-aggregator
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin groovy
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin configuration-as-code
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin aws-credentials
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin matrix-auth
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin credentials
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin github
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) install-plugin pipeline-groovy-lib
mkdir -p /var/lib/jenkins/casc_configs
systemctl restart jenkins

## Create configuration as code files
cat << EOC > /var/lib/jenkins/casc_configs/jenkins.yaml
jenkins:
  systemMessage: "Jenkins configured automatically by Jenkins Configuration as Code plugin\n\n"
  numExecutors: 5
  scmCheckoutRetryCount: 2
  mode: NORMAL
credentials:
  system:
    domainCredentials:
      - credentials:
          - string:
              id: "my-aws-credentials"
              scope: GLOBAL
              secret: "REPLACEME:REPLACEME"

          - basicSSHUserPrivateKey:
              scope: GLOBAL
              id: github
              username: git
              description: "github private key"
              privateKeySource:
                directEntry:
                  privateKey: "\$${readFile:/tmp/privatekey}" 
EOC



cat << EOD > /var/lib/jenkins/casc_configs/job.xml 
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@1360.vc6700e3136f5">
  <actions>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobAction plugin="pipeline-model-definition@2.2151.ve32c9d209a_3f"/>
    <org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction plugin="pipeline-model-definition@2.2151.ve32c9d209a_3f">
      <jobProperties/>
      <triggers/>
      <parameters/>
      <options/>
    </org.jenkinsci.plugins.pipeline.modeldefinition.actions.DeclarativeJobPropertyTrackerAction>
  </actions>
  <description></description>
  <keepDependencies>false</keepDependencies>
  <properties/>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@3806.va_3a_6988277b_2">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@5.2.1">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>git@github.com:Mwimpelberg28/sre-coding-challenge.git</url>
          <credentialsId>github</credentialsId>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="empty-list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <authToken>kifmulwlnregjnfs</authToken>
  <disabled>false</disabled>
</flow-definition>
EOD

## Update the systemd file for Jenkins to point to the configuration as code directory
sed -i "s#Environment=\"JAVA_OPTS=-Djava.awt.headless=true\"#Environment=\"JAVA_OPTS=-Djava.awt.headless=true -Dcasc.jenkins.config=/var/lib/jenkins/casc_configs -Djenkins.install.runSetupWizard=false\"#g" /lib/systemd/system/jenkins.service
systemctl daemon-reload
sudo systemctl restart jenkins

## Create our pipeline job
java -jar /jenkins-cli.jar -s http://localhost:8080/ -auth admin:$(cat /var/lib/jenkins/secrets/initialAdminPassword) create-job scmjob < /var/lib/jenkins/casc_configs/job.xml 
systemctl restart jenkins
EOF
}
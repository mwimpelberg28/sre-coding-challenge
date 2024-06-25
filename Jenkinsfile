pipeline {
    agent any

    stages {
        stage('Step 1: Build Container and Push to ECR') {
            steps {
                script {
                  withCredentials([string(credentialsId: 'my-aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            set +x
                            export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | cut -d':' -f1)
                            export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | cut -d':' -f2)
                            rm -rf sre-coding-challenge
                            GIT_SSH_COMMAND='ssh -i /tmp/privatekey -o IdentitiesOnly=yes' git clone git@github.com:Mwimpelberg28/sre-coding-challenge.git
                            cd flaskapp; docker build . -t flaskapp:latest
                            aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin 850471083155.dkr.ecr.us-west-2.amazonaws.com
                            docker tag flaskapp:latest 850471083155.dkr.ecr.us-west-2.amazonaws.com/flaskapp:latest
                            docker push 850471083155.dkr.ecr.us-west-2.amazonaws.com/flaskapp:latest
                        '''
                  }
            }
        }
    }
        stage('Step 2: Deploy to EKS') {
            steps {
                script {
                  withCredentials([string(credentialsId: 'my-aws-credentials', variable: 'AWS_CREDENTIALS')]) {
                        sh '''
                            set +x
                            export AWS_ACCESS_KEY_ID=$(echo $AWS_CREDENTIALS | cut -d':' -f1)
                            export AWS_SECRET_ACCESS_KEY=$(echo $AWS_CREDENTIALS | cut -d':' -f2)
                            export AWS_DEFAULT_REGION=us-west-2
                            aws eks update-kubeconfig --name test-cluster --region us-west-2
                            kubectl create secret docker-registry regcred --docker-server=850471083155.dkr.ecr.us-west-2.amazonaws.com --docker-username=AWS  --docker-password=$(aws ecr get-login-password)
                            rm -rf sre-coding-challenge
                            GIT_SSH_COMMAND='ssh -i /tmp/privatekey -o IdentitiesOnly=yes' git clone git@github.com:Mwimpelberg28/sre-coding-challenge.git
                            cd yamls; kubectl apply -f deployment.yaml; kubectl apply -f service.yaml; kubectl apply -f ingress.yaml
                            kubectl delete secret regcred

                        '''
                  }
            }
        }
    }
  }
}


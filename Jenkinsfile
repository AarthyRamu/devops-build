pipeline {
  agent any

  environment {
    DOCKER_USER = "aarthyramu"
    DOCKERHUB_CREDENTIALS_ID = "docker-hub-creds"
    DEV_REPO = "${DOCKER_USER}/devops-build-dev"
    PROD_REPO = "${DOCKER_USER}/devops-build-prod"
    
    DEVOPS_IP = "65.2.81.58"
    DEVOPS_SSH_CREDS = "ec2-ssh-key"
  }

  stages {
    stage('Checkout') {
      steps {
        checkout scm
        echo "Source code checked out successfully."
        script {
          env.BRANCH_NAME = env.BRANCH_NAME ?: sh(script: 'echo ${GIT_BRANCH##*/}', returnStdout: true).trim()
          echo "Current branch: ${env.BRANCH_NAME}"
        }
      }
    }

    stage('Build Docker Image') {
      steps {
        sh 'docker build -t $DEV_REPO:latest .'
      }
    }

    stage('Push & Deploy Dev') {
      when { 
        expression { 
          return (env.BRANCH_NAME == 'dev' || env.GIT_BRANCH == 'origin/dev')
        }
      }
      steps {
        script {
          echo "Running Push & Deploy Dev on branch: ${env.BRANCH_NAME}"
          
          // 1. PUSH TO DOCKERHUB DEV REPO
          echo "1. Pushing to DockerHub DEV repo..."
  withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", usernameVariable: 'DBUSER', passwordVariable: 'DBPASS')]) {
            sh '''
              echo "$DBPASS" | docker login -u "$DBUSER" --password-stdin
              docker push $DEV_REPO:latest
              docker logout
            '''
          }
          
          // 2. DEPLOY DEV IMAGE VIA SSH
          echo "2. Deploying DEV image to DevOps EC2 at $DEVOPS_IP..."
          sshagent(credentials: ["${DEVOPS_SSH_CREDS}"]) { 
            sh """
              # Deploy using direct docker commands
              ssh -o StrictHostKeyChecking=no ubuntu@$DEVOPS_IP '
                # Pull the latest image
                docker pull ${DEV_REPO}:latest
                
                # Stop and remove existing container if it exists
                docker stop react-app 2>/dev/null || true
                docker rm react-app 2>/dev/null || true
                
                # Run new container on port 80
                docker run -d -p 80:80 --name react-app ${DEV_REPO}:latest
                
                # Verify container is running
                echo "Container status:"
                docker ps --filter "name=react-app"
              '
            """
          }
        }
      }
    }

    stage('Push & Deploy Prod') {
      when { 
        expression { 
          return (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master' || env.GIT_BRANCH == 'origin/main')
        }
      }
      steps {
        script {
          echo "Running Push & Deploy Prod on branch: ${env.BRANCH_NAME}"
          
          // 1. TAG FOR PROD
          echo "1. Tagging DEV image for PROD repo..."
          sh 'docker tag $DEV_REPO:latest $PROD_REPO:latest'
 // 2. PUSH TO DOCKERHUB PROD REPO
          echo "2. Pushing to DockerHub PROD repo..."
          withCredentials([usernamePassword(credentialsId: "${DOCKERHUB_CREDENTIALS_ID}", usernameVariable: 'DBUSER', passwordVariable: 'DBPASS')]) {
            sh '''
              echo "$DBPASS" | docker login -u "$DBUSER" --password-stdin
              docker push $PROD_REPO:latest
              docker logout
            '''
          }
          
          // 3. DEPLOY PROD IMAGE VIA SSH
          echo "3. Deploying PROD image to DevOps EC2 at $DEVOPS_IP..."
          sshagent(credentials: ["${DEVOPS_SSH_CREDS}"]) { 
            sh """
              # Deploy production using port 3000 (to avoid conflict with Jenkins on 8080)
              ssh -o StrictHostKeyChecking=no ubuntu@$DEVOPS_IP '
                # Pull the latest prod image
                docker pull ${PROD_REPO}:latest
                
                # Stop and remove existing prod container if it exists
                docker stop react-app-prod 2>/dev/null || true
                docker rm react-app-prod 2>/dev/null || true
                
                # Run prod container on port 3000
                docker run -d -p 3000:80 --name react-app-prod ${PROD_REPO}:latest
                
                # Verify container is running
                echo "Prod container status:"
                docker ps --filter "name=react-app-prod"
              '
            """
          }
        }
      }
    }
  }

  post {
    success { echo " Pipeline completed successfully!" }
    failure { echo "Pipeline failed — check build logs for errors." }
  }
}

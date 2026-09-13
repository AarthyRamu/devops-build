pipeline {
    agent any

    environment {
        DOCKER_USER = "aarthyramu"

        DOCKERHUB_CREDENTIALS_ID = "docker-hub-creds"

        DEV_REPO  = "${DOCKER_USER}/devops-build-dev"
        PROD_REPO = "${DOCKER_USER}/devops-build-prod"

        DEVOPS_IP = "65.2.81.58"
        DEVOPS_SSH_CREDS = "ec2-ssh-key"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm

                sh '''
                    echo "Branch: $BRANCH_NAME"
                    echo "Git Branch: $GIT_BRANCH"
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t "$DEV_REPO:latest" .
                '''
            }
        }

        stage('Push & Deploy Dev') {
            when {
                branch 'dev'
            }

            steps {
                script {

                    echo "===== DEV DEPLOYMENT ====="

                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKERHUB_CREDENTIALS_ID}",
                            usernameVariable: 'DBUSER',
                            passwordVariable: 'DBPASS'
                        )
                    ]) {

                        sh '''
                            echo "$DBPASS" | docker login \
                                -u "$DBUSER" \
                                --password-stdin

                            docker push "$DEV_REPO:latest"

                            docker logout
                        '''
                    }

                    sshagent(credentials: ["${DEVOPS_SSH_CREDS}"]) {

                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DEVOPS_IP} '
                                docker pull ${DEV_REPO}:latest

                                docker stop react-app 2>/dev/null || true
                                docker rm react-app 2>/dev/null || true

                                docker run -d \
                                    -p 80:80 \
                                    --name react-app \
                                    ${DEV_REPO}:latest

                                echo "DEV container:"
                                docker ps --filter "name=react-app"
                            '
                        """
                    }
                }
            }
        }

        stage('Push & Deploy Prod') {
            when {
                branch 'master'
            }

            steps {
                script {

                    echo "===== PROD DEPLOYMENT ====="

                    sh '''
                        docker tag \
                            "$DEV_REPO:latest" \
                            "$PROD_REPO:latest"
                    '''

                    withCredentials([
                        usernamePassword(
                            credentialsId: "${DOCKERHUB_CREDENTIALS_ID}",
                            usernameVariable: 'DBUSER',
                            passwordVariable: 'DBPASS'
                        )
                    ]) {

                        sh '''
                            echo "$DBPASS" | docker login \
                                -u "$DBUSER" \
                                --password-stdin

                            docker push "$PROD_REPO:latest"

                            docker logout
                        '''
                    }

                    sshagent(credentials: ["${DEVOPS_SSH_CREDS}"]) {

                        sh """
                            ssh -o StrictHostKeyChecking=no ubuntu@${DEVOPS_IP} '
                                docker pull ${PROD_REPO}:latest

                                docker stop react-app-prod 2>/dev/null || true
                                docker rm react-app-prod 2>/dev/null || true

                                docker run -d \
                                    -p 3000:80 \
                                    --name react-app-prod \
                                    ${PROD_REPO}:latest

                                echo "PROD container:"
                                docker ps --filter "name=react-app-prod"
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "Pipeline completed successfully!"
        }

        failure {
            echo "Pipeline failed. Check the console output."
        }
    }
}

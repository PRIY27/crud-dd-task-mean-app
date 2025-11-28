pipeline {
    agent any

    parameters {
        string(name: 'DEPLOY_HOST', defaultValue: 'your.vm.ip.or.hostname', description: 'Target VM hostname or IP for deployment')
        string(name: 'DEPLOY_USER', defaultValue: 'ubuntu', description: 'SSH user on the target VM')
        string(name: 'COMPOSE_PATH', defaultValue: '/home/ubuntu/crud-dd-task-mean-app', description: 'Path on VM containing docker-compose.yml')
        string(name: 'SSH_PORT', defaultValue: '22', description: 'SSH port on VM')
    }

    environment {
        DOCKER_HUB_USERNAME = 'priyadarshankhavtode'
        BACKEND_IMAGE_BASE = 'priyadarshankhavtode/crud-dd-task-mean-app-backend'
        FRONTEND_IMAGE_BASE = 'priyadarshankhavtode/crud-dd-task-mean-app-frontend'
        BUILD_TAG = "${env.BUILD_NUMBER}"
        DOCKER_CREDENTIALS_ID = 'dockerhub-creds'
        SSH_CREDENTIALS_ID = 'deploy-ssh-key'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '[Checkout] Cloning repository...'
                checkout scm
                echo '[Checkout] Code retrieved successfully'
            }
        }

        stage('Build Backend Image') {
            steps {
                echo "[Build Backend] Building backend Docker image: ${BACKEND_IMAGE_BASE}:${BUILD_TAG}"
                script {
                    sh "docker build -t ${BACKEND_IMAGE_BASE}:${BUILD_TAG} ./backend"
                    sh "docker tag ${BACKEND_IMAGE_BASE}:${BUILD_TAG} ${BACKEND_IMAGE_BASE}:latest"
                    echo "[Build Backend] Image built: ${BACKEND_IMAGE_BASE}:${BUILD_TAG} and :latest"
                }
            }
        }

        stage('Build Frontend Image') {
            steps {
                echo "[Build Frontend] Building frontend Docker image: ${FRONTEND_IMAGE_BASE}:${BUILD_TAG}"
                script {
                    sh "docker build -t ${FRONTEND_IMAGE_BASE}:${BUILD_TAG} ./frontend"
                    sh "docker tag ${FRONTEND_IMAGE_BASE}:${BUILD_TAG} ${FRONTEND_IMAGE_BASE}:latest"
                    echo "[Build Frontend] Image built: ${FRONTEND_IMAGE_BASE}:${BUILD_TAG} and :latest"
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                echo '[Push] Authenticating with Docker Hub and pushing images...'
                withCredentials([usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS')]) {
                    script {
                        sh '''
                            echo "Logging in to Docker Hub..."
                            echo "$DH_PASS" | docker login --username "$DH_USER" --password-stdin
                            
                            echo "Pushing backend images..."
                            docker push ${BACKEND_IMAGE_BASE}:${BUILD_TAG}
                            docker push ${BACKEND_IMAGE_BASE}:latest
                            
                            echo "Pushing frontend images..."
                            docker push ${FRONTEND_IMAGE_BASE}:${BUILD_TAG}
                            docker push ${FRONTEND_IMAGE_BASE}:latest
                            
                            echo "Logging out from Docker Hub..."
                            docker logout
                        '''
                    }
                }
                echo '[Push] Images pushed successfully to Docker Hub'
            }
        }

        stage('Deploy to VM') {
            steps {
                echo '[Deploy] Starting deployment to VM...'
                withCredentials([
                    usernamePassword(credentialsId: "${DOCKER_CREDENTIALS_ID}", usernameVariable: 'DH_USER', passwordVariable: 'DH_PASS'),
                    sshUserPrivateKey(credentialsId: "${SSH_CREDENTIALS_ID}", keyFileVariable: 'SSH_KEY_FILE', usernameVariable: 'SSH_USER')
                ]) {
                    script {
                        sh '''
                            set -e
                            echo "[Deploy] Setting up SSH connection to ${DEPLOY_HOST}:${SSH_PORT}..."
                            mkdir -p ~/.ssh
                            chmod 700 ~/.ssh
                            
                            # Trust the host key
                            ssh-keyscan -p ${SSH_PORT} ${DEPLOY_HOST} >> ~/.ssh/known_hosts 2>/dev/null || true
                            
                            # Execute deployment script on remote VM
                            ssh -o StrictHostKeyChecking=no -i ${SSH_KEY_FILE} -p ${SSH_PORT} ${DEPLOY_USER}@${DEPLOY_HOST} << 'DEPLOY_EOF'
                            set -e
                            echo "[Remote Deploy] Logging in to Docker Hub..."
                            echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                            
                            echo "[Remote Deploy] Pulling latest backend image..."
                            docker pull ${BACKEND_IMAGE_BASE}:latest || true
                            
                            echo "[Remote Deploy] Pulling latest frontend image..."
                            docker pull ${FRONTEND_IMAGE_BASE}:latest || true
                            
                            echo "[Remote Deploy] Navigating to compose directory..."
                            cd ${COMPOSE_PATH}
                            
                            echo "[Remote Deploy] Pulling service images via docker compose..."
                            docker compose pull || true
                            
                            echo "[Remote Deploy] Starting services..."
                            docker compose up -d --remove-orphans
                            
                            echo "[Remote Deploy] Verifying service status..."
                            docker compose ps
                            
                            echo "[Remote Deploy] Logging out from Docker Hub..."
                            docker logout
                            
                            echo "[Remote Deploy] Deployment completed successfully!"
                            DEPLOY_EOF
                        '''
                    }
                }
                echo '[Deploy] Deployment to VM completed'
            }
        }
    }

    post {
        success {
            echo "✅ Pipeline completed successfully! Build #${BUILD_NUMBER}"
            echo "Backend image: ${BACKEND_IMAGE_BASE}:${BUILD_TAG} and :latest"
            echo "Frontend image: ${FRONTEND_IMAGE_BASE}:${BUILD_TAG} and :latest"
        }
        failure {
            echo "❌ Pipeline failed at stage: ${env.STAGE_NAME}"
            echo "Build #${BUILD_NUMBER} failed. Check console logs for details."
        }
        always {
            echo "Pipeline execution finished. Check logs above for details."
        }
    }
}

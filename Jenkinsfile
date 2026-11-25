// CICD multibranch pipeline - the same file is used on the main and dev branches.
// main -> image nodemain:v1.0, port 3000 | dev -> image nodedev:v1.0, port 3001
pipeline {
    agent any

    tools {
        nodejs 'node-7.8.0'
    }

    environment {
        CI        = 'true'   // run the jest tests once (no watch mode)
        IMAGE_TAG = 'v1.0'
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Set environment') {
            steps {
                script {
                    if (env.BRANCH_NAME == 'main') {
                        env.APP_PORT   = '3000'
                        env.IMAGE_NAME = 'nodemain'
                    } else if (env.BRANCH_NAME == 'dev') {
                        env.APP_PORT   = '3001'
                        env.IMAGE_NAME = 'nodedev'
                    } else {
                        error "Branch ${env.BRANCH_NAME} has no environment"
                    }
                    env.CONTAINER_NAME = "app-${env.BRANCH_NAME}"
                }
                echo "Branch=${env.BRANCH_NAME} image=${env.IMAGE_NAME}:${env.IMAGE_TAG} port=${env.APP_PORT}"
            }
        }

        stage('Build') {
            steps {
                sh 'node --version && npm --version'
                sh 'npm install'
            }
        }

        stage('Test') {
            steps {
                sh 'npm test'
            }
        }

        stage('Lint Dockerfile (Hadolint)') {
            steps {
                sh 'docker run --rm -i hadolint/hadolint:v2.12.0 hadolint --failure-threshold error - < Dockerfile'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .'
            }
        }

        stage('Scan Image (Trivy)') {
            steps {
                sh '''
                    docker run --rm \
                      -v /var/run/docker.sock:/var/run/docker.sock \
                      -v trivy-cache:/root/.cache/ \
                      aquasec/trivy:0.58.1 image --scanners vuln --severity HIGH,CRITICAL \
                      --exit-code 0 --no-progress ${IMAGE_NAME}:${IMAGE_TAG}
                '''
            }
        }

        stage('Deploy') {
            steps {
                // The new image is already built, so the old container is replaced
                // only now (short downtime). Only this env's container is removed;
                // the other env keeps running.
                sh '''
                    OLD=$(docker ps -aq --filter "name=^${CONTAINER_NAME}$")
                    if [ -n "$OLD" ]; then docker rm -f $OLD; fi
                    docker run -d --name ${CONTAINER_NAME} --expose ${APP_PORT} -p ${APP_PORT}:3000 ${IMAGE_NAME}:${IMAGE_TAG}
                    docker ps --filter "name=^app-"
                '''
                echo "Deployed: http://localhost:${env.APP_PORT}"
            }
        }
    }
}

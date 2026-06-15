pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'spring-petclinic'
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
    }

    tools {
        maven 'Maven'
        jdk   'JDK17'
    }

    stages {
        // Checkout Git Repo
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Compile') {
            steps {
                sh 'mvn compile -DskipTests' // Skip tests because we are running them later
            }
        }

        stage('Test') {
            steps {
                sh 'mvn test'
            }
            post {
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests' //Package into JAR file to build docker image onto
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${DOCKER_IMAGE}:${DOCKER_TAG} ."
                sh "docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest"
            }
        }

    }

    post {
        success {
            echo "Build ${env.BUILD_NUMBER} succeeded. Image: ${DOCKER_IMAGE}:${DOCKER_TAG}"
        }
        failure {
            echo "Build ${env.BUILD_NUMBER} failed."
        }
        always {
            cleanWs()
        }
    }
}

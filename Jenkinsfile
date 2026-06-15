pipeline {
    agent any
    // Set environment variables 
    environment {
        ARTIFACTORY_URL     = 'http://localhost:8082/artifactory'
        ARTIFACTORY_REPO    = 'petclinic-libs-release'
        DOCKER_IMAGE        = 'spring-petclinic'
        DOCKER_TAG          = "${env.BUILD_NUMBER}"
        ARTIFACTORY_CREDS   = credentials('artifactory-credentials')
    }

    tools {
        maven 'Maven'
        jdk   'JDK17'
    }
    // Set build stages
    stages {

        // Checkout Git Repo
        stage('Checkout') {
            steps {
                checkout scm 
            }
        }

        stage('Hello Print'){
            steps {
                echo 'Hello World'
            }
        }
    }

}
pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'spring-petclinic'
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
        ARTIFACTORY_REPO = 'spring-petclinic'
        ARTIFACTORY_URL  = 'http://localhost:8082/artifactory'
        ARTIFACTORY_CREDS = credentials('artifactory-credentials')
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
        stage('Configure JCenter via Artifactory') {
            steps {
                writeFile file: 'settings.xml', text: """
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
  <servers>
    <server>
      <id>artifactory</id>
      <username>${ARTIFACTORY_CREDS_USR}</username>
      <password>${ARTIFACTORY_CREDS_PSW}</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>artifactory</id>
      <mirrorOf>*</mirrorOf>
      <url>${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}</url>
    </mirror>
  </mirrors>
</settings>
"""
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
        stage('Publish Artifact to Artifactory') {
            steps {
                sh """
                    mvn -s settings.xml deploy \
                        -DskipTests \
                        -DaltDeploymentRepository=artifactory::default::${ARTIFACTORY_URL}/${ARTIFACTORY_REPO}
                """
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

pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'spring-petclinic'
        DOCKER_TAG   = "${env.BUILD_NUMBER}"
        ARTIFACTORY_REPO = 'spring-petclinic-virtual'
        ARTIFACTORY_URL  = 'http://localhost:8082/artifactory' // In an actual system we would have correct URL since it would run in it's own server.
        ARTIFACTORY_CREDS = credentials('artifactory-credentials')
    }

    tools {
        maven 'Maven'
        jdk   'JDK17'
    }

    stages {
        // Checkout Git Repo that pipeline is attached to
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Configure JCenter via Artifactory') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'artifactory-credentials',
                    usernameVariable: 'ART_USER',
                    passwordVariable: 'ART_PASS'
                )]) {
            sh '''
                cat > settings.xml << EOF
<settings xmlns="http://maven.apache.org/SETTINGS/1.0.0">
  <servers>
    <server>
      <id>artifactory</id>
      <username>$ART_USER</username>
      <password>$ART_PASS</password>
    </server>
  </servers>
  <mirrors>
    <mirror>
      <id>artifactory</id>
      <mirrorOf>*</mirrorOf>
      <url>$ARTIFACTORY_URL/$ARTIFACTORY_REPO</url>
    </mirror>
  </mirrors>
</settings>
EOF
            '''
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
            post { // Collects test reports, this way we can visualize even if they fail.
                always {
                    junit '**/target/surefire-reports/*.xml'
                }
            }
        }

        stage('Package') {
            steps {
                sh 'mvn package -DskipTests' //Package into JAR file to build docker image onto , if desire to skip previous 2 steps simply run 'mvn clean package'
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
            cleanWs() //Wipe workspace to save disk space.
        }
    }
}


    // stages {
    //     stage('Checkout Repo') {
    //         steps {
    //             checkout scm
    //         }
    //     }
    //     stage('Configure Artifactory') {
    //         steps {
    //             rtMavenResolver(
    //                 id: 'maven-resolver',
    //                 serverId: 'artifactory',
    //                 releaseRepo: "${ARTIFACTORY_REPO}",
    //                 snapshotRepo: "${ARTIFACTORY_REPO}"
    //             )
    //             rtMavenDeployer(
    //                 id: 'maven-deployer',
    //                 serverId: 'artifactory',
    //                 releaseRepo: "${ARTIFACTORY_REPO}",
    //                 snapshotRepo: "${ARTIFACTORY_REPO}"
    //             )
    //         }
    //     }        
    //     stage('Compile') {
    //         steps {
    //             rtMavenRun(
    //                 tool: 'Maven',
    //                 pom: 'pom.xml',
    //                 goals: 'compile -DskipTests -U -e', // force maven to update snapshot/releases
    //                 resolverId: 'maven-resolver'
    //             )
    //         }
    //     }
    //     stage('Test') {
    //         steps {
    //             rtMavenRun(
    //                 tool: 'Maven',
    //                 pom: 'pom.xml',
    //                 goals: 'test',
    //                 resolverId: 'maven-resolver'
    //             )
    //         }
    //         post {
    //             always {
    //                 junit '**/target/surefire-reports/*.xml'
    //             }
    //         }
    //     }

    //     stage('Package & Deploy to Artifactory') {
    //         steps {
    //             rtMavenRun(
    //                 tool: 'Maven',
    //                 pom: 'pom.xml',
    //                 goals: 'package -DskipTests',
    //                 resolverId: 'maven-resolver',
    //                 deployerId: 'maven-deployer'
    //             )
    //         }
    //     }
    // }


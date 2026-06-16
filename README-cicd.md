# Spring Pet Clinic — JFrog DevOps Pipeline

This project demonstrates a CI/CD pipeline for the [Spring Pet Clinic](https://github.com/spring-projects/spring-petclinic) application using Jenkins, Docker, and JFrog Artifactory.

---

## Overview

The pipeline automates the full build lifecycle:

1. Compiles the source code
2. Runs the test suite
3. Packages the application as a JAR
4. Builds a runnable Docker image
5. Publishes the artifact to JFrog Artifactory 

---

## Prerequisites

- Java 17 (Eclipse Temurin utilized)
- Maven 3.9+
- Docker + Colima (for local Docker daemon on Mac)
- Jenkins (Ideally on a server, in this case running locally on Mac)
- JFrog Artifactory OSS (running via Docker Compose on Mac)

---

## Jenkins Setup

### 1. Install Jenkins locally

```bash
brew install jenkins-lts
brew services start jenkins-lts
```

Access Jenkins at `http://localhost:8080`.

### 2. Configure Global Tools

Go to **Manage Jenkins → Global Tool Configuration** and register:

- **JDK**: Name `JDK17`, JAVA_HOME set to output of `/usr/libexec/java_home -v 17`
- **Maven**: Name `Maven`, MAVEN_HOME set to output of `mvn --version`

### 3. Configure PATH for Docker

Go to **Manage Jenkins → System → Environment Variables** and add:

- Name: `PATH+EXTRA`
- Value: `/usr/local/bin:/opt/homebrew/bin`
***OPTIONAL*** Go to **Manage Jenkins → Plugins → j-frog artifactory** and add:
- Complete install of j-frog artifactory install.
- I ended up not utilizing this plugin because of version clashes when running in local set up, but if this was running on server the plugin would help the Jenkinsfile look cleaner and not require xml file build.

### 4. Add Artifactory Credentials

Go to **Manage Jenkins → Credentials → Global → Add Credentials**:

- Kind: `Username with password`
- Username: `admin`
- Password: your Artifactory password
- ID: `artifactory-credentials`

### 5. Create the Pipeline Job

1. New Item → Pipeline
2. Pipeline definition: **Pipeline script from SCM**
3. SCM: **Git**
4. Repository URL: `https://github.com/jmaraboli/spring-petclinic-jfrog-interview.git`
5. Branch: `*/main`
6. Jenkins will automatically detect the `Jenkinsfile` at the repo root

---

## Artifactory Setup

Artifactory runs locally via Docker Compose.

### Start Artifactory

```bash
# Generate master key
mkdir -p ~/artifactory-setup/artifactory/var/etc/security
openssl rand -hex 32 > ~/artifactory-setup/artifactory/var/etc/security/master.key
chmod 777 ~/artifactory-setup/artifactory/var/etc/security/master.key

# Start Artifactory
docker-compose up
```

Access Artifactory at `http://localhost:8082` (default credentials: `admin` / `password`, update password with the one previously stored in jenkins).

### Repository Configuration

Create the following repositories in Artifactory:

| Name | Type | URL |
|------|------|-----|
| `spring-petclinic` | Local | — |
| `spring-petclinic-remote` | Remote | `https://jcenter.bintray.com` |
| `spring-petclinic-virtual` | Virtual | Includes all 2 above |

`spring-petclinic-remote` is needed for jcenter requirement

There is a default repo built that is utilized to bring the maven requirements in, this needs to be added to the list of  `spring-petclinic-virtual`
| `maven-central-remote` | Remote | `https://repo1.maven.org/maven2` |


> In a production environment, Artifactory would run on a dedicated server or managed cloud instance (e.g. JFrog Cloud), eliminating local resource constraints.

---

## Docker Setup (Mac with Apple Silicon)

This project uses Colima as a lightweight Docker daemon, compatible with Apple Silicon (ARM64):

```bash
brew install colima
brew services start colima  # auto-starts on login
```

The Dockerfile uses `eclipse-temurin:17-jre-jammy` (Ubuntu 22.04 LTS) for multi-architecture support across both ARM64 and AMD64 systems.

---

## Running the Docker Image

### Build the image

```bash
docker build -t spring-petclinic:latest .
```

### Run the container

```bash
docker run -p 8083:8080 spring-petclinic:latest
```
If running the app from the tar file follow below
```bash
docker load -i spring-petclinic.tar
docker run -p 8083:8080 spring-petclinic:latest
```

Access the app at `http://localhost:8083`.

> Port `8083` is used on the host to avoid conflict with Jenkins and Artifactory running on `8080-2`.

---

## Pipeline Stages

| Stage | Description |
|-------|-------------|
| Checkout Repo | Clones the repo via SCM |
| Configure JCenter via Artifactory | Generates `settings.xml` securely routing all Maven deps through Artifactory virtual repo |
| Compile | `mvn compile -DskipTests` |
| Test | `mvn test` — results published to Jenkins UI |
| Package | `mvn package -DskipTests` — produces runnable JAR |
| Build Docker Image | Builds and tags the Docker image using the pre-built JAR |
| Publish Artifact to Artifactory | Deploys JAR and POM to Artifactory local repository |

---

## Notes

- The `settings.xml` is generated dynamically in the pipeline using `writeFile` — no static config file needed in the repo. `withCredentials` is utilized to be able to block interpolation of the credentials, ensuring secrets aren't shared through Jenkins logs.
- Jenkins credentials are injected securely via the credentials store in Jenkins — never hardcoded
- The Dockerfile copies the pre-built JAR from the `target/` directory produced by the Package stage — Maven does not run inside the container, keeping the image lean and the build fast
- Virtual repo is used for dependency resolution; local repo is used for artifact publishing — these are intentionally separate in Artifactory
- In production, the Docker image would also be pushed to Artifactory's Docker registry

## Alternative: Artifactory Jenkins Plugin

The pipeline can alternatively use the `rtMavenResolver`, `rtMavenDeployer`, and `rtMavenRun` steps that are commented out in the Jenkinsfile provided by the [Artifactory Jenkins Plugin](https://plugins.jenkins.io/artifactory/). This approach integrates more deeply with Artifactory (build info, traceability, artifact promotion) but requires version compatibility between the plugin and Maven.
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: tools
    image: maven:3.9.6-eclipse-temurin-17-slim
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
"""
            defaultContainer 'tools'
        }
    }

    environment {
        GCS_BUCKET = "artifacts-javas"
        GCP_CREDENTIAL_ID = "gcloud-service-account-json"
        SERVICES = "account-service,auth-service,notification-service,config,gateway,mongodb,monitoring,registry,statistics-service,turbine-stream-service"
    }

    stages {
        stage('Checkout') {
            steps {
                container('tools') {
                    sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/MyApp-Multibranch_main'
                    checkout scm
                }
            }
        }

        stage('Build Services') {
            steps {
                container('tools') {
                    script {
                        def services = env.SERVICES.split(',')
                        services.each { service ->
                            dir(service) {
                                sh 'mvn clean package -DskipTests=false -Dmaven.repo.local=.m2/repository'
                            }
                        }
                    }
                }
            }
        }

        stage('Push Artifacts to GCS') {
            steps {
                container('tools') {
                    script {
                        def timestamp = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                        def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()

                        withCredentials([file(credentialsId: "${env.GCP_CREDENTIAL_ID}", variable: "GOOGLE_APPLICATION_CREDENTIALS")]) {
                            sh """
                                apt-get update
                                apt-get install -y curl python3 python3-pip
                                curl -sSL https://sdk.cloud.google.com | bash
                                export PATH=\$PATH:/root/google-cloud-sdk/bin
                                gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                            """

                            services.each { service ->
                                sh """
                                    gsutil cp ${service}/target/*.jar gs://${env.GCS_BUCKET}/${service}/${service}-${timestamp}-${commit}.jar
                                """
                            }
                        }
                    }
                }
            }
        }
    }
}
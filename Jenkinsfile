pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: tools
    image: maven:3.9.6-eclipse-temurin-17
    command:
    - cat
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
"""
            defaultContainer 'tools'
        }
    }

    environment {
        GCS_BUCKET = "artifacts-javas"
        GCP_CREDENTIAL_ID = "gcloud-service-account-json"
        SERVICES = "account-service,auth-service,notification-service,config,gateway,mongodb,monitoring,registry,statistics-service,turbine-stream-service"
    }

    options { skipDefaultCheckout() }

    stages {
        stage('Checkout') {
            steps {
                // Ensure checkout runs in the 'tools' container
                container('tools') {
                    checkout scm
                }
            }
        }

        stage('Detect Changed Services') {
            steps {
                container('tools') {
                    script {
                        def changedFiles = sh(script: "git diff --name-only HEAD~1", returnStdout: true).trim().split('\n')
                        def services = SERVICES.split(',').findAll { svc ->
                            changedFiles.any { it.startsWith("${svc}/") }
                        }
                        if (!services || services.isEmpty()) {
                            echo "No service directories changed. Skipping build."
                            currentBuild.result = 'NOT_BUILT'
                            error("No relevant changes.")
                        }
                        env.CHANGED_SERVICES = services.join(',')
                        echo "Changed services: ${env.CHANGED_SERVICES}"
                    }
                }
            }
        }

        stage('Build & Deploy Pipeline per Service') {
            when { expression { env.CHANGED_SERVICES?.trim() } }
            steps {
                container('tools') {
                    script {
                        for (svc in env.CHANGED_SERVICES.split(',')) {
                            dir(svc) {
                                sh "mvn clean package -DskipTests=false"
                                // Steps redacted for brevity
                            }
                        }
                    }
                }
            }
        }
    }

    post {
        failure {
            echo "Pipeline failed. Please check logs for details."
        }
    }
}
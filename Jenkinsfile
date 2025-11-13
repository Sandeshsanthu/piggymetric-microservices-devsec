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
                container('tools') {
                sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/MyApp-Multibranch_main'
                    // Fetch full git history for correctness in all detached HEAD contexts
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        extensions: [
                            [$class: 'CloneOption', depth: 2, noTags: false, reference: '', shallow: true]
                        ],
                        userRemoteConfigs: [
                            [url: 'https://github.com/Sandeshsanthu/piggymetric-microservices-devsec'] // Change if needed
                        ]
                    ])
                }
            }
        }

        stage('Build Config Service') {
            steps {
                container('tools') {
                    dir('config') {
                        sh 'mvn clean package -DskipTests=false'
                    }
                }
            }
        }

        stage('Push Artifact to GCS') {
            steps {
                container('tools') {
                    script {
                        def timestamp = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                        def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                        def jar = sh(script: "ls config/target/*.jar | head -n 1", returnStdout: true).trim()
                        def artifact = "config-${timestamp}-${commit}.jar"
                        withCredentials([file(credentialsId: "${env.GCP_CREDENTIAL_ID}", variable: "GOOGLE_APPLICATION_CREDENTIALS")]) {
                            sh """
                                gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                                gsutil cp ${jar} gs://${env.GCS_BUCKET}/config/${artifact}
                            """
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
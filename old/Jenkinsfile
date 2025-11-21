pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: tools
    image: sandeshsanthu/jenkins-maven-gcloud:latest
    command: [cat]
    tty: true
    volumeMounts:
    - name: docker-sock
      mountPath: /var/run/docker.sock
    - name: m2-cache
      mountPath: /root/.m2
  volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
  - name: m2-cache
    emptyDir: {}
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
                    // Ensure safe directory for git
                    sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/${JOB_NAME}'
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/main']],
                        extensions: [[$class: 'CloneOption', depth: 10, noTags: false, reference: '', shallow: false]],
                        userRemoteConfigs: [[url: 'https://github.com/Sandeshsanthu/piggymetric-microservices-devsec']]
                    ])
                }
            }
        }

        stage('Build Changed Services') {
            steps {
                container('tools') {
                    script {
                        sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/${JOB_NAME}'
                        // Parse services list and check which changed
                        def changedServices = []
                        def allServices = env.SERVICES.split(",")

                        for (service in allServices) {
                            service = service.trim()
                            def diff = sh(
                                script: "git diff --name-only HEAD^ HEAD | grep '^${service}/' || true",
                                returnStdout: true
                            ).trim()
                            if (diff) {
                                changedServices << service
                            }
                        }

                        if (changedServices) {
                            echo "Services changed: ${changedServices.join(', ')}"
                            for (changedService in changedServices) {
                                dir(changedService) {
                                    sh "echo 'Building ${changedService}...'"
                                    sh 'mvn clean package -DskipTests=false'
                                }
                            }
                        } else {
                            echo "No service directory changed. Skipping build."
                        }
                    }
                }
            }
        }

        stage('Push Artifact to GCS') {
            steps {
                container('tools') {
                    script {
                        sh 'git config --global --add safe.directory /home/jenkins/agent/workspace/${JOB_NAME}'
                        def changedServices = []
                        def allServices = env.SERVICES.split(",")

                        for (service in allServices) {
                            service = service.trim()
                            def diff = sh(
                                script: "git diff --name-only HEAD^ HEAD | grep '^${service}/' || true",
                                returnStdout: true
                            ).trim()
                            if (diff) {
                                changedServices << service
                            }
                        }

                        for (changedService in changedServices) {
                            def jarPath = sh(
                                script: "ls ${changedService}/target/*.jar | head -n 1",
                                returnStdout: true
                            ).trim()
                            def timestamp = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                            def commit = sh(script: "cd ${changedService} && git rev-parse --short HEAD", returnStdout: true).trim()
                            def artifact = "${changedService}-${timestamp}-${commit}.jar"
                            withCredentials([file(credentialsId: "${env.GCP_CREDENTIAL_ID}", variable: "GOOGLE_APPLICATION_CREDENTIALS")]) {
                                sh """
                                    export PATH=\$PATH:/root/google-cloud-sdk/bin
                                    gcloud --version
                                    gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                                    gsutil cp ${jarPath} gs://${env.GCS_BUCKET}/${changedService}/${artifact}
                                """
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
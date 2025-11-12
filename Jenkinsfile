pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: tools
    image: ghcr.io/delivery-microservices/devsecops-ci:latest # <--- Use a custom/premium image, or public image if needed
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
            steps { checkout scm }
        }
        stage('Detect Changed Services') {
            steps {
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
        stage('Build & Deploy Pipeline per Service') {
            when { expression { env.CHANGED_SERVICES?.trim() } }
            steps {
                script {
                    for (svc in env.CHANGED_SERVICES.split(',')) {
                        dir(svc) {
                            // 1. Maven Build
                            sh "mvn clean package -DskipTests=false"
                            // 2. Dependency-Check Scan (disabled for now)
                            // sh "dependency-check.sh --project ${svc} --scan ."
                            // 3. SonarQube Analysis (disabled for now)
                            // withSonarQubeEnv('SonarQube') {
                            //     sh "mvn sonar:sonar -Dsonar.projectKey=${svc}"
                            // }
                            // 4. Build Docker Image
                            def timestamp = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                            def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                            def imageTag = "${svc}:${timestamp}-${commit}"
                            sh "docker build -t ${imageTag} ."
                            // 5. Trivy Scan (disabled for now)
                            // sh "trivy image --exit-code 0 --no-progress ${imageTag}"
                            // 6. Push Artifact to GCS
                            def jar = sh(script: "find target -name '*.jar' | head -n 1", returnStdout: true).trim()
                            def artifact = "${svc}-${timestamp}-${commit}.jar"
                            withCredentials([file(credentialsId: "${env.GCP_CREDENTIAL_ID}", variable: "GOOGLE_APPLICATION_CREDENTIALS")]) {
                                sh """
                                    gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                                    gsutil cp ${jar} gs://${env.GCS_BUCKET}/${svc}/${artifact}
                                """
                            }
                            // 7. Ansible Playbook for Deploy/Infra
                            // Uncomment and modify if you have a playbook
                            // sh "ansible-playbook -i inventory/hosts deploy.yml --extra-vars='service=${svc} image_tag=${imageTag}'"
                            // 8. Kubernetes Deployment (optional, uncomment if configured)
                            // sh "kubectl set image deployment/${svc} ${svc}=${imageTag}"
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
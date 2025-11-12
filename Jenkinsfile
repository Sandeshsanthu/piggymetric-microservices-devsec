pipeline {
    agent any

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
                    if (!services) {
                        echo "No service directories changed. Skipping build."
                        currentBuild.result = 'NOT_BUILT'
                        error("No relevant changes.")
                    }
                    env.CHANGED_SERVICES = services.join(',')
                    echo "Changed services: ${env.CHANGED_SERVICES}"
                }
            }
        }
        stage('DevSecOps Pipeline per Service') {
            when { environment name: 'CHANGED_SERVICES', value: { it?.length() > 0 } }
            steps {
                script {
                    for (svc in env.CHANGED_SERVICES.split(',')) {
                        dir(svc) {
                            // Maven build
                            sh "mvn clean package -DskipTests=false"
                            // Dependency-Check (ensure installed)
//                             sh "dependency-check.sh --project ${svc} --scan ."
//                             // SonarQube scan (ensure Jenkins Sonar plugin is setup)
//                             withSonarQubeEnv('SonarQube') {
//                                 sh "mvn sonar:sonar -Dsonar.projectKey=${svc}"
//                             }
                            // Versioned artifact naming
                            def timestamp = sh(script: "date +%Y%m%d-%H%M%S", returnStdout: true).trim()
                            def commit = sh(script: "git rev-parse --short HEAD", returnStdout: true).trim()
                            def jar = sh(script: "find target -name '*.jar' | head -n 1", returnStdout: true).trim()
                            def artifact = "${svc}-${timestamp}-${commit}.jar"

                            // GCS upload
                            withCredentials([file(credentialsId: "${env.GCP_CREDENTIAL_ID}", variable: "GOOGLE_APPLICATION_CREDENTIALS")]) {
                                sh """
                                    gcloud auth activate-service-account --key-file=\$GOOGLE_APPLICATION_CREDENTIALS
                                    gsutil cp ${jar} gs://${env.GCS_BUCKET}/${svc}/${artifact}
                                """
                            }

                            // Placeholders for Docker, Trivy, K8s steps (see your diagram)
                            // Example:
                            // sh "docker build -t gcr.io/your-project/${svc}:${timestamp}-${commit} ."
                            // sh "trivy image gcr.io/your-project/${svc}:${timestamp}-${commit}"
                            // sh "ansible-playbook deploy.yml"
                        }
                    }
                }
            }
        }
    }
}
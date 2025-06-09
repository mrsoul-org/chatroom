pipeline{
    agent any
    tools {
        maven 'maven3'
    }

    stages{
        stage('CleanWorkspace') {
            steps {
                cleanWs()
                checkout scm
            }
        }
        stage('compile'){
            steps {
                sh 'mvn clean compile -DskipTests'
            }
        }
        stage('Package') {
            steps {
                sh 'mvn package -DskipTests'
            }
        }
        stage('Trivy File Scan') {
            steps{
                sh 'trivy fs --severity HIGH,CRITICAL --format json -o trivy-fs.json .'
            }
            post {
                always {
                    // Convert JSON results to HTML
                    sh ''' trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-fs.html trivy-fs.json '''
                }
            }
        }
    }
}
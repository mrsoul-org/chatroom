pipeline{
    agent any
    tools {
        maven 'maven3'
    }
    environment {
        SCANNER_HOME = tool 'sonarqube-scanner'
        BUILD_NO = "${env.BUILD_NUMBER}"
    }
    stages  {
        stage('clean workspace') {
            steps{
                cleanWs()
                checkout scm // re-fetch your source code after cleaning
            }
        }
        stage('Show Branch') {
            steps {
                echo "Current Branch Name: ${env.BRANCH_NAME}"
            }
        }
        stage('validation') {
            steps{
                sh 'mvn clean validate'
            }
        }
        stage('compile') {
            steps{
                sh 'mvn compile'
            }
        }
        stage('Package') {
            steps{
                sh 'mvn package -DskipTests'
            }
        }
        stage('trivy file scan') {
            steps{
                sh 'trivy fs --severity HIGH,CRITICAL --format json -o trivy-fs.json .'
            }
            post{
                always {
                    // Convert JSON results to HTML
                    sh ''' trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-fs.html trivy-fs.json '''
                }
            }
        }
        stage('OWASP Scan') {
            steps{
                withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
                    sh 'mkdir -p reports/dependency-check' // linux
                    dependencyCheck additionalArguments: '''--scan ./ --out reports/dependency-check --project chatroom --format ALL --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}''', odcInstallation: 'DP-Check'
                }
            }
        }
        stage('sonarqube analysis') {
            steps{
                withSonarQubeEnv('sonarqube-server') {
                    sh ''' ${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=chatroom  \
                    -Dsonar.projectName=chatroom -Dsonar.java.binaries=target '''
                }
            }
        }
        stage('sonarqube quality gate') {
            steps{
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true, credentialsId: 'sonarqube-cred'
                    // True if you want to abort the pipeline if the quality gate fails
                    // False if you want to continue the pipeline even if the quality gate fails
                }
            }
        }
        stage('Docker build') {
            steps{
                sh 'docker build -t vootlasaicharan/chatroom-application:${BUILD_NUMBER} .'
            }
        }
        stage('Trivy image scan') {
            steps{
                sh ''' trivy image --severity LOW,MEDIUM,HIGH --format json -o trivy-image-HIGH-result.json --exit-code 0 vootlasaicharan/chatroom-application:${BUILD_NUMBER}
                 trivy image --severity CRITICAL --format json -o trivy-image-CRITICAL-result.json --exit-code 0 vootlasaicharan/chatroom-application:${BUILD_NUMBER}'''
            }
            post{
                always {
                    // Convert JSON results to HTML
                    sh ''' trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-image-HIGH-result.html trivy-image-HIGH-result.json
                    trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-image-CRITICAL-result.html trivy-image-CRITICAL-result.json '''
                }
            }
        }
        stage('Docker Repository'){
            steps{
                script{
                    withDockerRegistry(credentialsId: 'docker-cred') {
                        sh 'docker push vootlasaicharan/chatroom-application:${BUILD_NUMBER}'
                    }
                }
            }
        }
        stage('Deploy to EC2 Instance') {
            when {
                branch 'feature'
            }
            steps {
                script {
                    sshagent(['aws-dev-instance']) {
                        withAWS(credentials: 'aws-ec2-s3-cred', region: 'us-east-1') {
                            ssh '''
                                scp -o StrictHostKeyChecking=no deploy.sh ubuntu@35.174.14.246:/tmp/deploy.sh
                                ssh -o StrictHostKeyChecking=no ubuntu@35.174.14.246 'bash /tmp/deploy.sh' 
                            '''
                        }
                    }
                }
            }
        }
    }
    post{
        always{
            // Publish the Trivy report
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-fs.html', reportName: 'Trivy fs HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            // Publish the OWASP Dependency Check report
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: 'reports/dependency-check/', reportFiles: 'dependency-check-jenkins.html', reportName: 'OWASP Dependency Check HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            // Publish the Trivy image scan report
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-HIGH-result.html', reportName: 'Trivy image HIGH HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: true, alwaysLinkToLastBuild: true, icon: '', keepAll: true, reportDir: './', reportFiles: 'trivy-image-CRITICAL-result.html', reportName: 'Trivy image CRITICAL HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}
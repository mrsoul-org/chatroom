pipeline{
    agent any
    tools {
        maven 'maven3'
    }
    environment {
        SCANNER_HOME = tool 'sonarqube-scanner'
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
        // stage('OWASP Dependency Scan') {
        //     steps {
        //         withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
        //             sh 'mkdir -p reports/dependency-check' // linux
        //             dependencyCheck additionalArguments: '''--scan ./ --out reports/dependency-check --project chatroom --format ALL --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}''', odcInstallation: 'DP-Check'
        //         }
        //     }
        // }
        stage('Sonarqube analysis'){
            steps{
                withSonarQubeEnv('sonarqube-server') {
                    sh ''' ${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=chatroom \
                    -Dsonar.java.binaries=target -Dsonar.projectName=chatroom '''
                }
            }
        }
        stage('Sonarqube Quality Gate') {
            steps{
                timeout(time: 1, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: false, credentialsId: 'soarqube-cred'
                }
            }
        }
        stage('Nexus Artifactory'){
            steps{
                withMaven(globalMavenSettingsConfig: 'chatapp', jdk: '', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
                    sh 'mvn deploy -DskipTests'
                }
            }
        }
        stage('Docker Build') {
            steps {
                sh 'docker build -t vootlasaicharan/chatroom:latest .'
            }
        }
        stage('Trivy Image Scan') {
            steps {
                sh ''' trivy image --severity LOW,MEDIUM,HIGH --format json -o trivy-HIGH-image.json --exit-code 0 vootlasaicharan/chatroom-application:latest
                trivy image --severity CRITICAL --format json -o trivy-CRITICAL-image.json --exit-code 0 vootlasaicharan/chatroom-application:latest'''
            }
            post {
                always {
                    // Convert JSON results to HTML
                    sh ''' trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-HIGH-image.html trivy-HIGH-image.json
                    trivy convert \
                    --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
                    -o trivy-CRITICAL-image.html trivy-CRITICAL-image.json '''
                }
            }
        }
        stage('Docker Push') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-cred', url: 'https://index.docker.io/v1/')  {
                    sh 'docker push vootlasaicharan/chatroom:latest'
                }
            }
        }
        stage('Deploy to EC2 Instance') {
            steps {
                sshagent(['aws-dev-instance']) {
                    withAWS(credentials: 'aws-cred', region: 'us-east-1') {
                        sh ''' 
                            ssh -o StrictHostKeyChecking=no ubuntu@3.84.82.241 "
                                docker stop $(docekr ps -aq) || true
                                docker rm $(docker ps -aq) || true
                                docker rmi $(docker images -q) || true
                            
                                docker run --rm -itd --name chatroom-app -p 8080:8080 vootlasaicharan/chatroom:latest
                            "
                        '''
                    }
                }
            }
        }
    }
    post {
        always {
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-fs.html', reportName: 'trivy fs HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-HIGH-image.html', reportName: 'trivy HIGH image HTML Report', reportTitles: '', useWrapperFileDirectly: true])
            publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-CRITICAL-image.html', reportName: 'trivy CRITICAL image HTML Report', reportTitles: '', useWrapperFileDirectly: true])
        }
    }
}
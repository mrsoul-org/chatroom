pipeline{
    agent any
    tools {
        maven 'maven3'
    }
    // environment {
    //     SCANNER_HOME = tool 'sonarqube-scanner'
    // }

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
        // stage('Trivy File Scan') {
        //     steps{
        //         sh 'trivy fs --severity HIGH,CRITICAL --format json -o trivy-fs.json .'
        //     }
        //     post {
        //         always {
        //             // Convert JSON results to HTML
        //             sh ''' trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
        //             -o trivy-fs.html trivy-fs.json '''
        //         }
        //     }
        // }
        // stage('OWASP Dependency Scan') {
        //     steps {
        //         withCredentials([string(credentialsId: 'nvd-api-key', variable: 'NVD_API_KEY')]) {
        //             sh 'mkdir -p reports/dependency-check' // linux
        //             dependencyCheck additionalArguments: '''--scan ./ --out reports/dependency-check --project chatroom --format ALL --disableYarnAudit --disableNodeAudit --nvdApiKey ${NVD_API_KEY}''', odcInstallation: 'DP-Check'
        //         }
        //     }
        // }
        // stage('Sonarqube analysis'){
        //     steps{
        //         withSonarQubeEnv('sonarqube-server') {
        //             sh ''' ${SCANNER_HOME}/bin/sonar-scanner -Dsonar.projectKey=chatroom \
        //             -Dsonar.java.binaries=target -Dsonar.projectName=chatroom '''
        //         }
        //     }
        // }
        // stage('Sonarqube Quality Gate') {
        //     steps{
        //         timeout(time: 1, unit: 'MINUTES') {
        //             waitForQualityGate abortPipeline: false, credentialsId: 'soarqube-cred'
        //         }
        //     }
        // }
        // stage('Nexus Artifactory'){
        //     steps{
        //         withMaven(globalMavenSettingsConfig: 'chatapp', jdk: '', maven: 'maven3', mavenSettingsConfig: '', traceability: true) {
        //             sh 'mvn deploy -DskipTests'
        //         }
        //     }
        // }
        stage('Docker Build') {
            steps {
                sh 'docker build -t vootlasaicharan/chatroom-application:${BUILD_NUMBER} .'
            }
        }
        // stage('Trivy Image Scan') {
        //     steps {
        //         sh ''' trivy image --severity LOW,MEDIUM,HIGH --format json -o trivy-HIGH-image.json --exit-code 0 vootlasaicharan/chatroom-application:${BUILD_NUMBER}
        //         trivy image --severity CRITICAL --format json -o trivy-CRITICAL-image.json --exit-code 0 vootlasaicharan/chatroom-application:${BUILD_NUMBER} '''
        //     }
        //     post {
        //         always {
        //             // Convert JSON results to HTML
        //             sh ''' trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
        //             -o trivy-HIGH-image.html trivy-HIGH-image.json
        //             trivy convert \
        //             --format template --template "@/usr/local/share/trivy/templates/html.tpl" \
        //             -o trivy-CRITICAL-image.html trivy-CRITICAL-image.json '''
        //         }
        //     }
        // }
        stage('Docker Push') {
            steps {
                withDockerRegistry(credentialsId: 'dockerhub-cred', url: 'https://index.docker.io/v1/')  {
                    sh 'docker push vootlasaicharan/chatroom-application:${BUILD_NUMBER}'
                }
            }
        }
        stage('Deploy to EC2 Instance') {
            when {
                branch 'feature'
            }
            steps {
                sshagent(['aws-dev-instance']) {
                    withAWS(credentials: 'aws-cred', region: 'us-east-1') {
                        sh ''' 
                            ssh -o StrictHostKeyChecking=no ubuntu@3.85.243.243 "
                                docker stop chatroom-app || true
                                docker rm chatroom-app || true
                                docker rmi $(docker images -q) || true
                            
                                docker run --rm -itd --name chatroom-app -p 8080:8080 vootlasaicharan/chatroom-application:${BUILD_NUMBER}
                            "
                        '''
                    }
                }
            }
        }
        stage('K8s Manifest file Update'){
            when {
                branch 'PR*'
            }
            steps {
                script {
                    def DOCKER_IMAGE = "vootlasaicharan/chatroom-application:${BUILD_NUMBER}"
                    def DEPLOYMENT_FILE = "kubernetes/chatroom-application.yaml"

                    // Clone and enter the repo
                    sh 'git clone -b master https://github.com/mrsoul-org/chatroom-k8s.git'

                    dir('chatroom-k8s') {
                        // Update the YAML file
                        sh """
                            sed -i 's|image: vootlasaicharan/chatroom-application:.*|image: ${DOCKER_IMAGE}|g' ${DEPLOYMENT_FILE}
                        """

                        withCredentials([string(credentialsId: 'github-token', variable: 'GITHUB_CRED')]) {
                            sh """
                                git config --global user.name "vscharan"
                                git config --global user.email "charanv369@gmail.com"
                                git add ${DEPLOYMENT_FILE}
                                git commit -m "Updated deployment image to ${DOCKER_IMAGE}"
                                git push https://${GITHUB_CRED}@github.com/mrsoul-org/chatroom-k8s.git master
                            """
                        }
                    }
                }
            }

        }
    }
    // post {
    //     always {
    //         publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-fs.html', reportName: 'trivy fs HTML Report', reportTitles: '', useWrapperFileDirectly: true])
    //         publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-HIGH-image.html', reportName: 'trivy HIGH image HTML Report', reportTitles: '', useWrapperFileDirectly: true])
    //         publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, icon: '', keepAll: false, reportDir: './', reportFiles: 'trivy-CRITICAL-image.html', reportName: 'trivy CRITICAL image HTML Report', reportTitles: '', useWrapperFileDirectly: true])
    //     }
    // }
}


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
    }
}
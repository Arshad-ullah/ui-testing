pipeline {

    agent any

    stages {

        stage('Build') {
            steps {
                echo 'Building...'

                sh 'pwd'
                // sh 'node conditions.js'
                // sh 'python3 devops.py'
                // sh 'dart test.dart'

                // Flutter commands
                sh 'flutter clean'
                sh 'flutter pub get'
                sh 'flutter build apk --release'
            }
        }

        stage('Test') {
            steps {
                sh 'flutter test'
            }
        }

        stage('Deploy') {
         steps {

            slackSend channel: '#ai-team', message: "Build and Test completed successfully. Ready for deployment."
            }
}
    }
}

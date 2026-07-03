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
          emailext(
            to: 'jahan665577@gmail.com',
            subject: 'APK Build Successful',
            body: 'Hi,\n\nAPK created successfully.\n\nRegards,\nJenkins'
        )
    }
}
    }
}

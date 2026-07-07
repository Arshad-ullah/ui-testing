pipeline {

    agent any

    environment {
        FIREBASE_APP_ID = '1:520200426032:android:d5570b33c7fd8abf0413f5'
        FIREBASE_TOKEN  = credentials('firebase-token')   // Replace with your Jenkins Credential ID
    }

    stages {

        stage('Build') {
            steps {
                echo 'Building Flutter APK...'

                sh 'pwd'
                sh 'flutter clean'
                sh 'flutter pub get'
                sh 'flutter build apk --release'
            }
        }

        stage('Test') {
            steps {
                echo 'Running Flutter Tests...'
                sh 'flutter test'
            }
        }

        stage('Upload to Firebase App Distribution') {
            steps {
                echo 'Uploading APK to Firebase...'

                sh '''
                firebase appdistribution:distribute \
                build/app/outputs/flutter-apk/app-release.apk \
                --app $FIREBASE_APP_ID \
                --groups qa-team \
                --release-notes "Jenkins Build #${BUILD_NUMBER}" \
                --token $FIREBASE_TOKEN
                '''
            }
        }

        stage('Notify Slack') {
            steps {
                slackSend(
                    channel: '#ai-team',
                    color: 'good',
                    message: "✅ Flutter APK uploaded to Firebase App Distribution.\nBuild #${BUILD_NUMBER}"
                )
            }
        }
    }

    post {
        success {
            echo 'Pipeline completed successfully.'
        }

        failure {
            slackSend(
                channel: '#ai-team',
                color: 'danger',
                message: "❌ Jenkins Build #${BUILD_NUMBER} failed."
            )
        }
    }
}
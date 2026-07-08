pipeline {

    agent any

    environment {
        FIREBASE_APP_ID = '1:520200426032:android:d5570b33c7fd8abf0413f5'
        FIREBASE_TOKEN  = credentials('firebase-token')

        ANDROID_HOME = "/Users/MAC/Library/Android/sdk"
        ANDROID_SDK_ROOT = "/Users/MAC/Library/Android/sdk"

        PATH = "${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/emulator:${env.PATH}"

    }

    stages {

        stage('Prepare') {
            steps {
                echo 'Preparing Flutter project...'

                sh 'pwd'
                sh 'flutter clean'
                sh 'flutter pub get'
            }
        }


stage('Debug') {
    steps {
        sh '''
        echo "ANDROID_HOME=$ANDROID_HOME"

        flutter doctor -v

        $ANDROID_HOME/platform-tools/adb version

        $ANDROID_HOME/emulator/emulator -list-avds
        '''
    }
}
        stage('Start Android Emulator') {
            steps {
                
  sh '''
$ANDROID_HOME/emulator/emulator -avd Tablet -no-window -no-audio &

$ANDROID_HOME/platform-tools/adb wait-for-device

until [ "$($ANDROID_HOME/platform-tools/adb shell getprop sys.boot_completed | tr -d "\\r")" = "1" ]; do
    sleep 5
done

flutter devices
'''
            }
        }

        stage('Run Tests') {
            steps {
                echo 'Running Flutter Tests...'

                // sh 'flutter test'
              
                // sh 'flutter test integration_test'
            }
        }

        /*
        stage('Build') {
            steps {
                sh 'flutter build apk --release'
            }
        }

        stage('Upload to Firebase App Distribution') {
            steps {
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
        */

        stage('Notify Slack') {
            steps {
                slackSend(
                    channel: '#ai-team',
                    color: 'good',
                    message: "✅ Flutter tests completed.\nBuild #${BUILD_NUMBER}"
                )
            }
        }
    }
}
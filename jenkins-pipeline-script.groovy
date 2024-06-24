pipeline {
    agent any

    environment {
        GITHUB_REPO = 'https://github.com/djoksa4/svia-ci-cd-repo.git'
    }

    stages {
        stage('Clean Workspace') {
            steps {
                deleteDir()
            }
        }

        stage('Clone Repository') {
            steps {
                script {
                    checkout([$class: 'GitSCM',
                              branches: [[name: '*/master']],
                              doGenerateSubmoduleConfigurations: false,
                              extensions: [[$class: 'CloneOption', shallow: true]],
                              submoduleCfg: [],
                              userRemoteConfigs: [[credentialsId: 'djoksa4_github', url: "${GITHUB_REPO}"]]])
                }
            }
        }

        stage('Add New Files') {
            steps {
                script {
                    // Copy new files from the Windows sc11 machine
                    sh 'scp -i /var/lib/jenkins/secrets/interinstance -o StrictHostKeyChecking=no -O Administrator@10.0.0.94:/C:/Users/Administrator/Desktop/Approved/20240119/* ./JS'
                }
            }
        }

        stage('Commit Changes') {
            steps {
                script {
                    // Stage changes and commit
                    sh 'git add .'
                    sh 'git commit -m "v1.14"' // hard coded for now
                }
            }
        }

        stage('Push Changes') {
            steps {
                script {
                    // Ensure the local "master" branch is created and then push
                    sh 'git checkout -B master'
                    withCredentials([usernamePassword(credentialsId: 'djoksa4_github', passwordVariable: 'GIT_PASSWORD', usernameVariable: 'GIT_USERNAME')]) {
                        sh 'git push https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/djoksa4/svia-ci-cd-repo.git master'
                    }
                }
            }
		}
			
		stage('Deploy to Remote Server') {
			steps {
				script {
					// Copy files to the remote app-server using SCP
					sh "scp -i /var/lib/jenkins/secrets/interinstance -o StrictHostKeyChecking=no /var/lib/jenkins/workspace/SVIA_job/JS/* root@10.0.0.73:/home/ec2-user/live_files/JS"
				}
			}
		}
    
    }
}

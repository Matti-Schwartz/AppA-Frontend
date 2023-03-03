def aws_ip = ""

pipeline {
	agent any
	environment {
		DOCKER_HUB_CREDS = credentials('Docker-Hub-Creds-ms')
	}
	stages {
		stage ('Tooling versions') {
			steps {
				sh 'docker --version'
				sh 'docker compose version'
				sh 'terraform --version'
				sh 'ansible --version'
			}
		}
		stage ('Build docker image') {
			steps {
				sh 'docker context use default'
				sh 'docker compose build'
				sh 'echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin'
				sh 'docker compose push'
			}
		}
        stage ('Instatiate instances') {
            steps {
				sh 'terraform init'
				sh 'terraform destroy -var \'sshPublicKeyPath=~/.ssh/operator.pub\' --auto-approve'
                sh 'terraform apply -var \'sshPublicKeyPath=~/.ssh/operator.pub\' --auto-approve'
				script {
					aws_ip = sh(returnStdout: true, script: "terraform output publicIPv4").trim()
				}
            }
        }
		stage ('Install packages') {
			steps {
				sh """ansible-playbook playbook.yaml -e HOSTS=${aws_ip} -i ${aws_ip},"""
			}
		}
	}
}
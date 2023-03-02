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
        stage ('Terraform') {
            steps {
				sh 'terraform init'
				sh 'terraform destroy -var \'sshPublicKeyPath=~/.ssh/.ssh/operator.pub\' --auto-approve'
                sh 'terraform apply -var \'sshPublicKeyPath=~/.ssh/.ssh/operator.pub\' --auto-approve'
				script {
					aws_ip = sh(returnStdout: true, script: "terraform output publicIPv4").trim()
				}
            }
        }
		stage ('Ansible') {
			steps {
				sh """ansible-playbook playbook.yaml -e HOSTS=${aws_ip} -i ${aws_ip},"""
			}
		}
	}
}
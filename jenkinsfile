pipeline {
	agent any
	stages {
		stage ('Tooling versions') {
			steps {
				sh 'docker --version'
				sh 'docker compose version'
				sh 'terraform --version'
				sh 'ansible --version'
			}
		}
	}
}
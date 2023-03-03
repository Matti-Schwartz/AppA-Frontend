# Devops-Test-Webapp

A small Web-Application a simple backend created with **Java-Spring-Boot** and **MySQL** to store the user data. This project is a test and learn project for *Devops* topics like: create a full automated build and deploy pipeline. So the focus of this project lies on the devops pipeline which consists of the toolchain, which is discribed in the next section.

## Toolchain

The following section describes all the tools which are used to create the pipeline.

- Jenkins

    Defines the entrypoint of the pipeline and uses the most of the other tools to build and deploy the Web-App on **AWS EC2-Instances**.

- Docker / Docker-Compose

    Creates the *Container-Image* for the Web-App from the source code in this repository which bases on the official Java-Image: **eclipse-temurin:17-jdk-alpine**. It also defines the Image for the MySQL-Database which uses the official MySQL-Image: **mysql:8**.

- Terraform

    Instantiates and configurates the **AWS EC2-Instances**. After the initialization, Terraform outputs the Ip-Addresses, to use them later.

- Ansible

    Installs the all packages to run Docker-Container on the instances. Also install or rather pull the Docker-Images of this Web-App from *Dockerhub* and starts the container on the instances.

## Jenkins

### Stages

The first stage is just a tooling test stage to verfy that all required tool are installed and accessable.

```groovy
stage ('Tooling versions') {
	steps {
		sh 'docker --version'
		sh 'docker compose version'
		sh 'terraform --version'
		sh 'ansible --version'
	}
}
```

In the second stage creates *Docker* the image for the Webapp. The first step is to ensure that the default *Docker Context* is used. After this, *Docker Compose* builds the image. To make the accessable on the aws-ec2-instance which will be created in the next stage, the newly created image gets pushed to **Dockerhub**.

``` groovy
stage ('Build docker image') {
	steps {
		sh 'docker context use default'
		sh 'docker compose build'
		sh 'echo $DOCKER_HUB_CREDS_PSW | docker login -u $DOCKER_HUB_CREDS_USR --password-stdin'
		sh 'docker compose push'
    }
}
```

In the next stage, the aws-ec2-instance will be created with *Terraform*. Firstly initialize *Terraform*, then to ensure there is no outdated instance running after this pipeline, terraform should destroy this instance. If there is no instance, this step has no effects. The next step actually creates the instance. To do the destruction and the creation terraform need a *ssh-key* to communicate. For this terraform needs the path to the public part of the ssh-key-file. The parameter **--auto-approve** is used to automatically confirm the confirmation prompt. After the instance is created, terraform output the *public IP* of the ec2-instance. This ip will be saved in a variable to use them in the next stage.

``` groovy
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
```

In the last stage, ansible comes into play. This steps invokes the *ansible-playbook* to install all the required packages and finally the docker images on the instance. To reach the newly created instance, ansible obtains the public ip of the instance from the variable which is created in the previous stage. More details later.

``` groovy
stage ('Install packages') {
	steps {
		sh """ansible-playbook playbook.yaml -e HOSTS=${aws_ip} -i ${aws_ip},"""
	}
}
```

## Ansible-Playbook

In this section we will look at the **playbook.yaml** whoich is used in the last stage of the pipeline.

At the beginning, there are a few settings. Firstly a name, not so importent. The second variable is the *host* on which this playbook would be executed. In this case it is an parameter which ansible gets from terraform, this is described in the previous section. The third variable is for the priviledge escalation, means this will be executed as user with *sudo* permissions. After this a few variables which are used later in the script are defined. The *default_container_name* is the name of the docker container which will be created in this script. The second var *default_container_image* is the name of the image from which the container should be created.

``` yaml
- name: Installation
  hosts: "{{ HOSTS }}"
  become: true
  vars:
    container_count: 1
    default_container_name: appa_container
    default_container_image: mattischwartz/appa-frontend:latest
```

After this are the tasks defined, which will be executed on the instance. The first tasks are just package installations to ensure that all required packages are installed.

``` yaml
    - name: Install aptitude
      apt:
        name: aptitude
        state: latest
        update_cache: true

    - name: Install required system packages
      apt:
        pkg:
          - apt-transport-https
          - ca-certificates
          - curl
          - software-properties-common
          - python3-pip
          - virtualenv
          - python3-setuptools
        state: latest
        update_cache: true
```

Than docker will be installed.

``` yaml
    - name: Add Docker GPG apt Key
      apt_key:
        url: https://download.docker.com/linux/ubuntu/gpg
        state: present

    - name: Add Docker Repository
      apt_repository:
        repo: deb https://download.docker.com/linux/ubuntu focal stable
        state: present

    - name: Update apt and install docker-ce
      apt:
        name: docker-ce
        state: latest
        update_cache: true

    - name: Install Docker Module for Python
      pip:
        name: docker
```

After docker is installed, the image which is defined at the beginning of the file, will be pulled from *Dockerhub*.

``` yaml      
    - name: Pull Docker Image
      community.docker.docker_image:
        name: "{{ default_container_image }}"
        source: pull
```

Last but not least, the container will be created from the image and the ports will be exposed, so the service is reachable the standard *http* port 80.

``` yaml
    - name: Create container
      community.docker.docker_container:
        name: "{{ default_container_name }}"
        image: "{{ default_container_image }}"
        state: started
        exposed_ports:
        - "80"
        ports:
        - "80:8081"
      with_sequence: count={{ container_count }}
```

---
## Providers

- AWS-Academy

  For instance creation and as deployment targets.

- Digital Ocean

  As jenkins build server, to make jenkins reachable via the internet. This is required to use GitHub-Webhooks. Which can be used to trigger the build pipeline vie a *git push* on the specified branch.
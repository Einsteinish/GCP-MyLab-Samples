# GCP-MyLab-Samples

GCP samples - How to use Terraform (Provision & Configuration) with Ansible and Salt to deploy a Flask app

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project on a live system.

### Prerequisites

GCP account and terraform 12 


### Repos

* terraform-gcp-flask - provision an instace via terraform and deploy the flask app via terraform
* terraform-ansible-gcp-flask - provision an instace via terraform and deploy the flask app via ansible
* terraform-salt-master-gcp - provision/configure a salt master via terraform. The salt state copies the app to minion and runs it
* terraform-salt-minion-flask-gcp - provision/configure a salt minion on which the flask app runs

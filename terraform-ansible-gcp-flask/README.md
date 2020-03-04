# Deploy a Flask app via Ansible

This repo will configure GCP instance via Terraform and deploy a sample Flask app from your local machine via Ansible.


![Output](https://github.com/Einsteinish/GCP-MyLab-Samples/blob/master/terraform-ansible-gcp-flask/terraform-ansible-flask.png)



## Getting Started

These instructions will let you know how to provision via Terraform and configure via Ansible. 

### Prerequisites

Terraform 12

Ansible

### Terraform run
* terraform init
* terraform plan
* terraform apply
* terraform taint resource resource_name (google_compute_instance.default) 

### Provision
* google_compute_instance
* google_compute_firewall (port 80/5000)

### Configuration
Copy a Flask app from local to the GCP vm using Terraform's file provisioner

```
  provisioner "file" {
    # Copies the file using SSH
    source = "./flask-teraform.py"
    destination = "~/flask-teraform.py"
  }
```

* Installs python-pip and Flask using a Terraform's remote-exec provisioner. Then runs the app in background.

```
  provisioner "remote-exec" {
    // a list of command strings and they are executed in the order 
    inline = [
       "sudo apt-get update",
       "sudo apt-get install -yq build-essential python-pip",
       "sudo pip -q install flask",
       // This app can also be run ansible playbook via local-exec 
       "nohup python flask-teraform.py &",
       // sleep prevents remote-exec from Terraform getting away with shutting down 
       // the connection before the child process has a chance to start up, despite the nohup.
       "sleep 10",
    ]
  }
```

* Runs the app via local-exec provisioner using a playbook (play.yml)
```
  provisioner "local-exec" {
    command  = "sleep 10; ansible-playbook ./ansible/play.yml -v -i '${self.network_interface.0.access_config.0.nat_ip},' -u ki_hong"
  }
```

where play.yml looks like this:

```
---
- hosts: all
  become: yes
  become_user: ki_hong
  tasks:     
  - name: Running python app
    become: yes
    become_user: ki_hong
    shell: nohup python flask-terraform-ansible.py &
```

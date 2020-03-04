# Deploy a Flask app via Salt-master

This repo will configure Sal-master instance via Terraform and deploy a sample Flask app from salt-master to salt-minion via salt.


![Output](https://github.com/Einsteinish/GCP-MyLab-Samples/blob/master/terraform-salt-master-gcp/images/salt-output.png)


## Getting Started

These instructions will let you know how to provision a salt-mastger via Terraform and see how the state files are working between salt-master and salt-minion. 

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
* google_compute_firewall (salt-minion: port 22/80/5000) (salt-master: 22/4505/4506)

### Configuration
Copy a Flask app from local to the GCP vm using Terraform's file provisioner

```
  // copy an app file from local to salt master
  provisioner "file" {
    // Copies the file using SSH
    source = "./${var.app_name}"
    destination = "/home/ki_hong/${var.app_name}"
  }
```

* Configs salt-master using a Terraform's remote-exec provisioner. Then creates salt state files. Running the app on minion is done via salt's cmd.run

```
  provisioner "remote-exec" {
    // a list of command strings and they are executed in the order 
    inline = [
      // create a /srv/salt directory for app 
      // and state dir /srv/salt/demo
      "sudo mkdir -p /srv/salt/demo",
       
      // create a directory for configure base and fileserver_backend
      "sudo mkdir -p /etc/salt/master.d",

      // copying the app file to /srv/salt where state directory is located
      "sudo cp /home/ki_hong/${var.app_name} /srv/salt/.",

      "sleep 2",

      // writing salt state files in demo directory
      "sudo bash -c 'cat << EOF > /srv/salt/demo/app.sls",
      "app-state:",
      " cmd.run:",
      "   - name: /usr/bin/python /home/ki_hong/${var.app_name} &",
      "EOF'",

      "cat << EOF | sudo tee -a /srv/salt/demo/demo.sls",
      "demo-state:",
      " file.managed:",
      "   - source: salt://${var.app_name}",
      "   - name: /home/ki_hong/${var.app_name}",
      "   - user: ki_hong",
      "   - group: root",
      "   - mode: 777",
      "EOF",

      "sudo bash -c 'cat << EOF > /srv/salt/demo/init.sls",
      "include:",
      " - .demo",
      " - .app", 
      "EOF'",


      // configure base env and fileserver_backend
      "sudo bash -c 'cat << EOF > /etc/salt/master.d/myconf.conf",
      "base:",
      " - /srv/salt",
      "fileserver_backend:",
      " - roots",
      "EOF'",    

      // restart the salt-master
      "sudo systemctl restart salt-master",
    ]
  }
```

### Steps 
(This is the quick and dirty steps not intending to replace any official salt docs or salt experts's opinion)

* Minion - how to set master: 
add master's ip to /etc/salt/minion:
```
master: 10.138.15.201
```

* Then, restart salt-minion:
```
$ sudo systemctl restart salt-minion
```

* On the salt-master, list the keys:
```
$ sudo salt-key --list-all
```
![listing keys](https://github.com/Einsteinish/GCP-MyLab-Samples/blob/master/terraform-salt-master-gcp/images/keys-listed-unaccepted.png)

* On the salt-master, accept the key:
```
$ sudo salt-key -A
```
![accepting keys](https://github.com/Einsteinish/GCP-MyLab-Samples/blob/master/terraform-salt-master-gcp/images/accept-the-minion-key.png)

* On the salt-master, apply the state file.
First, get the minion info (ki-salt-minion-flask-2-5680237f6fc38cab.c.cicd-devops-265916.internal) from the master, and then apply it:

![accepting keys](https://github.com/Einsteinish/GCP-MyLab-Samples/blob/master/terraform-salt-master-gcp/images/salt-manage-version.png)

```
$ sudo salt 'ki-salt-minion-flask-5680237f6fc38cab.c.cicd-devops-265916.internal' state.apply demo 
```

* The demo directory has the following state files:
```
$ tree /srv/salt/demo
/srv/salt/demo
├── app.sls
├── demo.sls
└── init.sls
```

* By applying the demo folder, salt will run init.sls that looks like this:
```
[ki_hong@ki-salt-master-2d20cc91d8368e79 demo]$ cat init.sls
include:
 - .demo
 - .app
```
So, it ends up running the two state files.


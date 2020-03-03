provider "google" {
  // private key for a service account downloaded from GCP
  credentials = file("~/.ssh/my-gcp-key.json")
  project     = "cicd-devops-265916"
  region      = "us-west2"
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
 byte_length = 8
}

// A single Google Cloud Engine instance
resource "google_compute_instance" "default" {
  name         = "ki-flask-vm-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  zone         = "us-west2-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
      //image = "centos-cloud/centos-7"
    }
  }

  // This 'metadata_startup_script' works but it is moved to ansible 'remote-exec'
  // metadata_startup_script = "sudo apt-get update; sudo apt-get install -yq build-essential python-pip rsync; pip install flask;pip install ansible"

  metadata = {
    // ki.hong is my username but on gcp, it is ki_hong
    //ssh-keys = "ki.hong:${file("~/.ssh/id_rsa.pub")}"  
    ssh-keys = "ki_hong:${file("~/.ssh/id_rsa.pub")}"
  }

  network_interface {
    network = "default"

    access_config {
     // Include this section to give the VM an external ip address
    }
  }

  connection { 
    type    = "ssh"
    user    = "ki_hong"
    timeout = "30s"
    private_key = file("~/.ssh/id_rsa")
    host  = self.network_interface.0.access_config.0.nat_ip
  }

  provisioner "file" {
    # Copies the file using SSH
    source = "./${var.app_name}"
    destination = "~/${var.app_name}"
  }

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
}

resource "google_compute_firewall" "default" {
  name    = "ki-flask-app-firewall"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "5000"]  // port 80 requires running app.py as sudo
  }
}

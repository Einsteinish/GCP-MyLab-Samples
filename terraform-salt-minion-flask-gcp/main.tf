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
  name         = "ki-salt-minion-flask-2-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  //machine_type = "n1-standard-1"
  zone         = "us-west2-a"

  boot_disk {
    initialize_params {
      // image = "debian-cloud/debian-9"
      image = "centos-cloud/centos-7"
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

  provisioner "remote-exec" {
    // a list of command strings and they are executed in the order 
    inline = [
       "sudo yum -y update",
       "sudo yum install -yq python-pip salt-minion bind-utils nmap-ncat.x86_64",
       "sudo pip -q install flask",
       "sleep 10",
       "sudo systemctl start salt-minion",
    ]
  }
}

resource "google_compute_firewall" "default" {
  name    = "ki-salt-minion-flask-firewall-2"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "5000"]  // port 80 requires running app.py as sudo
  }
}

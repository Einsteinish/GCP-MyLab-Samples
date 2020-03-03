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
  name         = "ki-salt-master-2-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  //machine_type = "n1-standard-1"
  zone         = "us-west1-a"

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
       "sudo yum install -yq salt-master salt-minion",
       "sleep 10",
       "sudo systemctl start salt-master",
    ]
  }

  // copy an app file from local to salt master
  provisioner "file" {
    // Copies the file using SSH
    source = "./${var.app_name}"
    destination = "/home/ki_hong/${var.app_name}"
  }

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


}

resource "google_compute_firewall" "default" {
  name    = "ki-salt-master-firewall-2"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22", "4505", "4506"]  // port 4505 for minion
  }
}


output "instance_id" {
  value = google_compute_instance.default.*.instance_id
}

output "network_ip" {
  value = google_compute_instance.default.*.network_interface.0.network_ip
}


// A variable for extracting the external ip of the instance
output "public_ip" {
 value = "${google_compute_instance.default.*.network_interface.0.access_config.0.nat_ip}"
}



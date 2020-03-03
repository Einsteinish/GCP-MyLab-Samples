# GCP-Lab
Files from the GCP training lab. This is just a simple example of creating a module for a single GCP project.  It is also not fully functional, please do not just copy/paste this when building your own, it is for refrence only.

* **main.tf** - This file just calls the module in the subdirectory.  It is the module that does all the real work.

* **terraform-gcp-compute/main.tf** - This file has the provider information, the credientials and the bulk of the infrastucture definitions.  

* **terraform-gcp-compute/output.tf** - This file provides various outputs so that a human can get useful feedback.  Right now it is set to provide network data, but it can provide a lot more information.

* **terraform-gcp-compute/variables.tf** - This file is where you will define the variables that are called in the main.tf file.  This allows for a single location to change configs while leaving the rest of the terraform files untouched.
  * In this example we use variables for the number of instances in total, the zones and the number of instances in each zone.

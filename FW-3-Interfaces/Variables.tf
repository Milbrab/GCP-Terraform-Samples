// PROJECT Variables
# Define your project name
variable "my_gcp_project" {
  default = " "
}

# Define your region
variable "region" {
  default = "us-central1"
}

# Define your subnets 
variable "mgmt-cidr" {
  default = " "
}
variable "untrust-cidr" {
  default = " "
}
variable "trust-cidr" {
  default = " "
}
# Define your zone
variable "zone" {
  default = " "
}
# Define your RSA public key (optional)
variable "public_key" {
  default = " "
}

// VM-Series Firewall Variables
# Name your instance
variable "firewall_name" {
  default = "firewall"
}

variable "image_fw" {
  # default = "Your_VM_Series_Image"
  # run the following gcloud command to find all the applicable images
  #     gcloud compute images list --project paloaltonetworksgcp-public --no-standard-images --uri
  # /Cloud Launcher API Calls to images/
  # default = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-byol-810"
  default = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-bundle2-810"
  # default = "https://www.googleapis.com/compute/v1/projects/paloaltonetworksgcp-public/global/images/vmseries-bundle1-814"

}

variable "machine_type_fw" {
  default = "n1-standard-4"
}

variable "machine_cpu_fw" {
  default = "Intel Skylake"
}
# Define the name of your bucket
variable "bootstrap_bucket_fw" {
  default = " "
}

# Define the name of your interfraces (defaults are set)
variable "interface_0_name" {
  default = "management"
}

variable "interface_1_name" {
  default = "untrust"
}

variable "interface_2_name" {
  default = "trust"
}

variable "scopes_fw" {
  default = ["https://www.googleapis.com/auth/cloud.useraccounts.readonly",
    "https://www.googleapis.com/auth/devstorage.read_only",
    "https://www.googleapis.com/auth/logging.write",
    "https://www.googleapis.com/auth/monitoring.write",
  ]
}
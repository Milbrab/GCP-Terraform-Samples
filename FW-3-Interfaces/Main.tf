# This tempalte utilizes additional functionality whereas we are uploading a dummy.txt file to have terraform create the bucket and folders
# needed for the bootstrapping functionality. Dependencies are built in so that the PA-VM will not be created until the bucket, folders and
# files are all uploaded. In order to utilize the dummy file you will want to either keep the dummyfile in the same terraform directory or
# define the directory where the dummy file is stored. This will be used the same way as you define your *.json file used for credentials.

// Configure the Google Cloud provider
provider "google" {
  credentials = "${file(" ")}"
  project     = "${var.my_gcp_project}"
  region      = "${var.region}"
}

// Configure the bucket resource 
resource "google_storage_bucket" "bootstrap_bucket_fw" {
  name = "${var.bootstrap_bucket_fw}"
  storage_class = "MULTI_REGIONAL"
}

// Adding SSH Public Key Project Wide
resource "google_compute_project_metadata_item" "ssh-keys" {
  key   = "ssh-keys"
  value = "${var.public_key}"
}

// Adding VPC Networks to Project  MANAGEMENT
resource "google_compute_subnetwork" "management-sub" {
  name          = "management-sub"
  ip_cidr_range = "${var.mgmt-cidr}"
  network       = "${google_compute_network.management.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "management" {
  name                    = "${var.interface_0_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  UNTRUST
resource "google_compute_subnetwork" "untrust-sub" {
  name          = "untrust-sub"
  ip_cidr_range = "${var.untrust-cidr}"
  network       = "${google_compute_network.untrust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "untrust" {
  name                    = "${var.interface_1_name}"
  auto_create_subnetworks = "false"
}

// Adding VPC Networks to Project  TRUST
resource "google_compute_subnetwork" "trust-sub" {
  name          = "trust-sub"
  ip_cidr_range = "${var.trust-cidr}"
  network       = "${google_compute_network.trust.self_link}"
  region        = "${var.region}"
}

resource "google_compute_network" "trust" {
  name                    = "${var.interface_2_name}"
  auto_create_subnetworks = "false"
}

// Adding GCP Route to TRUST Interface
resource "google_compute_route" "trust" {
  name                   = "trust-route"
  dest_range             = "0.0.0.0/0"
  network                = "${google_compute_network.trust.self_link}"
  next_hop_instance      = "${element(google_compute_instance.firewall.*.name,count.index)}"
  next_hop_instance_zone = "${var.zone}"
  priority               = 100

  depends_on = ["google_compute_instance.firewall",
    "google_compute_network.trust",
    "google_compute_network.untrust",
    "google_compute_network.management",
  ]
}

// Adding GCP Firewall Rules for MANGEMENT
resource "google_compute_firewall" "allow-mgmt" {
  name    = "allow-mgmt"
  network = "${google_compute_network.management.self_link}"

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["443", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for INBOUND
resource "google_compute_firewall" "allow-inbound" {
  name    = "allow-inbound"
  network = "${google_compute_network.untrust.self_link}"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Adding GCP Firewall Rules for OUTBOUND
resource "google_compute_firewall" "allow-outbound" {
  name    = "allow-outbound"
  network = "${google_compute_network.trust.self_link}"

  allow {
    protocol = "all"

    # ports    = ["all"]
  }

  source_ranges = ["0.0.0.0/0"]
}

// Create a new Palo Alto Networks NGFW VM-Series GCE instance
resource "google_compute_instance" "firewall" {
  depends_on = [ "google_storage_bucket_object.bootstrap",
  "google_storage_bucket_object.config",
  "google_storage_bucket_object.license",
  "google_storage_bucket_object.content",
  "google_storage_bucket_object.software"
   ]
  name                      = "${var.firewall_name}-${count.index + 1}"
  machine_type              = "${var.machine_type_fw}"
  zone                      = "${var.zone}"
  min_cpu_platform          = "${var.machine_cpu_fw}"
  can_ip_forward            = true
  allow_stopping_for_update = true
  count                     = 1

  // Adding METADATA Key Value pairs to VM-Series GCE instance
  metadata {
    vmseries-bootstrap-gce-storagebucket = "${var.bootstrap_bucket_fw}"
    serial-port-enable                   = true

    #ssh-keys                              = "${var.public_key}"
  }

  service_account {
    scopes = "${var.scopes_fw}"
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.management-sub.self_link}"
    access_config = {}
  }

  network_interface {
    subnetwork    = "${google_compute_subnetwork.untrust-sub.self_link}"
    access_config = {}
  }

  network_interface {
    subnetwork = "${google_compute_subnetwork.trust-sub.self_link}"
  }

  boot_disk {
    initialize_params {
      image = "${var.image_fw}"
    }
  }
}

// Create folders and add content
resource "google_storage_bucket_object" "bootstrap" {
  depends_on = [ "google_storage_bucket.bootstrap_bucket_fw" ]
  name = "config/bootstrap.xml"
  content = "${file("bootstrap.xml")}"
  bucket = "${var.bootstrap_bucket_fw}"
  content_type = "text/plain"
}

resource "google_storage_bucket_object" "config" {
  depends_on = [ "google_storage_bucket.bootstrap_bucket_fw" ]
  name = "config/init-cfg.txt"
  content = "${file("init-cfg.txt")}"
  bucket = "${var.bootstrap_bucket_fw}"
  content_type = "text/plain"
}

resource "google_storage_bucket_object" "license" {
  depends_on = [ "google_storage_bucket.bootstrap_bucket_fw" ]
  name = "license/gcp-dummyfile.txt"
  content = "${file("gcp-dummyfile.txt")}"
  bucket = "${var.bootstrap_bucket_fw}"
  content_type = "text/plain"
}

resource "google_storage_bucket_object" "content" {
  depends_on = [ "google_storage_bucket.bootstrap_bucket_fw" ]
  name = "content/gcp-dummyfile.txt"
  content = "${file("gcp-dummyfile.txt")}"
  bucket = "${var.bootstrap_bucket_fw}"
  content_type = "text/plain"
}

resource "google_storage_bucket_object" "software" {
  depends_on = [ "google_storage_bucket.bootstrap_bucket_fw" ]
  name = "software/gcp-dummyfile.txt"
  content = "${file("gcp-dummyfile.txt")}"
  bucket = "${var.bootstrap_bucket_fw}"
  content_type = "text/plain"
}

output "pan-tf-trust-ip" {
  value = "${google_compute_instance.firewall.*.network_interface.2.address}"
}

output "pan-tf-name" {
  value = "${google_compute_instance.firewall.*.name}"
}
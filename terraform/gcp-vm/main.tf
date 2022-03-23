provider "google" {
  credentials = file("mygcp-creds.json")
  project = "empyrean-verve-344405"
  region = "us-central1"
  zone = "us-central1-a"
}

resource "google_compute_instance" "default" {
  name         = "master1"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = "default" // Enable Private IP Address

    access_config {
      // Enable Public IP Address
    }
  }
}
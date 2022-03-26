locals {
  project_id       = "empyrean-verve-344405"
  network          = "default"
  image            = "debian-10-buster-v20220317"
  ssh_user         = "ansible"
  private_key_path = "~/.ssh/ansbile_izalul"

  k8s_node = {
    k8s-master-000 = {
      machine_type = "e2-micro"
      zone         = "us-central1-a"
    }
    k8s-master-001 = {
      machine_type = "e2-micro"
      zone         = "us-central1-b"
    }
    k8s-worker-000 = {
      machine_type = "e2-micro"
      zone         = "us-central1-a"
    }
    k8s-worker-001 = {
      machine_type = "e2-micro"
      zone         = "us-central1-b"
    }
  }
}

provider "google" {
  project = local.project_id
  region  = "us-central1"
}

resource "google_service_account" "k8s" {
  account_id = "k8s-demo"
}

resource "google_compute_firewall" "k8s-api" {
  name    = "k8s-api-access"
  network = local.network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges           = ["0.0.0.0/0"]
  target_service_accounts = [google_service_account.k8s.email]
}

resource "google_compute_instance" "k8s" {
  for_each = local.k8s_node

  name         = each.key
  machine_type = each.value.machine_type
  zone         = each.value.zone

  boot_disk {
    initialize_params {
      image = local.image
    }
  }

  network_interface {
    network = local.network
    access_config {}
  }

  service_account {
    email  = google_service_account.k8s.email
    scopes = ["cloud-platform"]
  }

  provisioner "remote-exec" {
    inline = ["echo 'Wait until SSH is ready'"]

    connection {
      type        = "ssh"
      user        = local.ssh_user
      private_key = file(local.private_key_path)
      host        = self.network_interface.0.access_config.0.nat_ip
    }
  }

  provisioner "local-exec" {
    command = "ansible-playbook  -i ${self.network_interface.0.access_config.0.nat_ip}, --private-key ${local.private_key_path} nginx.yaml"
  }
}

output "k8s_node_ips" {
  value = {
    for k, v in google_compute_instance.k8s : k => "http://${v.network_interface.0.access_config.0.nat_ip}"
  }
}
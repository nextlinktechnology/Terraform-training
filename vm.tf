resource "google_compute_instance" "vm_instance" {
  name         = "circle-instance"
  machine_type = "f1-micro"

  allow_stopping_for_update = true

  tags = ["circle-web"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc.name
    subnetwork = google_compute_subnetwork.subnetwork1.name
  }
}
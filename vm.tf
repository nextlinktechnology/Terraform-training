resource "google_compute_instance" "vm_instance" {
  name         = "circle-instance"
  machine_type = "f1-micro"

  allow_stopping_for_update = true

  tags = ["circle-ssh"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.my_vpc.name
    subnetwork = google_compute_subnetwork.my_subnetwork.name
  }
}
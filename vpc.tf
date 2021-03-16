 resource "google_compute_network" "my_vpc" {
  name = "circle-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "my_subnetwork" {
  name          = "asia-east1-my-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = "asia-east1"
  network       = google_compute_network.my_vpc.name
}
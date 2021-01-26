 resource "google_compute_network" "vpc" {
  name = "circle-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "subnetwork1" {
  name          = "asia-east1-subnetwork1"
  ip_cidr_range = "10.2.0.0/16"
  region        = "asia-east1"
  network       = google_compute_network.vpc.id
}
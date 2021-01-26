resource "google_compute_firewall" "firewall" {
  name    = "circle-firewall"
  network = google_compute_network.vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = [ "220.135.202.135/32", "211.75.165.158/32" ]
  source_tags = ["circle-ssh"]
}
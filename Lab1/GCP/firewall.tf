resource "google_compute_firewall" "my_firewall" {
  name    = "circle-firewall" # 這是在GCP上要顯示的名稱，要修改
  network = google_compute_network.my_vpc.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  # 允許的來源範圍
  source_ranges = ["220.135.202.135/32", "211.75.165.158/32", "218.32.44.172/32"]
  # 這個firewall的tag
  source_tags   = ["circle-ssh"]
}

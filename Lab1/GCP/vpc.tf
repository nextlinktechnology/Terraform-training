 resource "google_compute_network" "my_vpc" {
  name = "circle-vpc" # 這個是在GCP上面顯示的名稱，需要改成自己的名字
  auto_create_subnetworks = false # 預設是true
}

resource "google_compute_subnetwork" "my_subnetwork" {
  name          = "asia-east1-my-subnetwork"  # 這邊也需要改
  ip_cidr_range = "10.2.0.0/16"
  region        = "asia-east1"
  network       = google_compute_network.my_vpc.name
}
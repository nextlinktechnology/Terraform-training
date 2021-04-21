resource "google_compute_instance" "vm_instance" {
  name         = "circle-instance" # 這是在GCP上面顯示的名稱，要修改
  machine_type = "f1-micro"

  # 因為有些設定會需要停機在修改，所以這個參數要設成true
  allow_stopping_for_update = true

  # 這個VM要引用的網路tags
  tags = ["circle-ssh"]

  # 硬碟相關，包括磁碟大小以及OS等
  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network    = google_compute_network.my_vpc.name
    subnetwork = google_compute_subnetwork.my_subnetwork.name
  }
}

就不多廢話了，我們直接上架構圖！！

![](images/457932954.png)

環境概述
----

Region：自己挑一個

Network

*   Subnet
    
    *   CIDR：`10.2.0.0/16`
        

VM

*   Machine type : `f1-micro`
    
*   Image : `debian-cloud/debian-9`
    

* * *

我習慣使用Visual Studio Code來開發，所以這邊我們就先安裝Terraform的[插件](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)。

### Provider

接著建立`provider.tf`，來定義我們要使用的雲端平台。

這邊我們使用`credentials`的方式來設定部署到sandbox的環境去。

```tcl
provider "google" {
  credentials = file("account.json")
  project     = "sandbox-206307"
  region      = "asia-east1"
  zone        = "asia-east1-b"
}
```
這邊需要去`APIs & Services` > `Credentials`去建立Service Account

![](images/457801742.png)

創建完後，可以在下面找到件好的Account，然後點擊編輯

![](images/457801748.png)

接著點擊`ADD KEY` > `Create new key`

![](images/457736224.png)

Key type選擇JSON

![](images/457801754.png)

我們再把下載下來的金鑰檔案更名為`account.json`放到我們的Lab目錄底下

![](images/457801760.png)

撰寫完`provider`之後，要執行下面指令來初始化

``` shell
terraform init
```

每次只要有修改`provider`，都一定要記得重做一次初始化

### VPC

接下來就是建立`vpc.tf`來定義我們的VPC，包括了`google_compute_network`、`google_compute_subnetwork`。

```tcl
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
```

### Firewall

當然還不能忘了我們的`firewall`，因為通常`firewall`是最容易變動的設定，所以我習慣把它獨立在一個tf檔案中。我們建立一個，只允許公司五樓與六樓IP可以訪問22 port以及icmp的`firewall`。

```tcl
resource "google_compute_firewall" "my_firewall" {
  name    = "circle-firewall"
  network = google_compute_network.my_vpc.name

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
```

最後的最後，就是我們的GCE啦。

在設定的時候別忘了要把前面的`firewall`tag給加進來。

```tcl
resource "google_compute_instance" "my_vm" {
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
```

最後執行下面的指令，來檢視是否正確

```shell
terraform plan -out=terraform-lab1
```

你會得到下面的輸出結果

```shell
An execution plan has been generated and is shown below.
Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # google_compute_firewall.firewall will be created
  + resource "google_compute_firewall" "firewall" {
      + creation_timestamp = (known after apply)
      + destination_ranges = (known after apply)
      + direction          = (known after apply)
      + enable_logging     = (known after apply)
      + id                 = (known after apply)
      + name               = "circle-firewall"
      + network            = "circle-vpc"
      + priority           = 1000
      + project            = (known after apply)
      + self_link          = (known after apply)
      + source_ranges      = [
          + "211.75.165.158/32",
          + "220.135.202.135/32",
        ]
      + source_tags        = [
          + "circle-ssh",
        ]

      + allow {
          + ports    = [
              + "22",
            ]
          + protocol = "tcp"
        }
      + allow {
          + ports    = []
          + protocol = "icmp"
        }
    }

  # google_compute_instance.vm_instance will be created
  + resource "google_compute_instance" "vm_instance" {
      + allow_stopping_for_update = true
      + can_ip_forward            = false
      + cpu_platform              = (known after apply)
      + current_status            = (known after apply)
      + deletion_protection       = false
      + guest_accelerator         = (known after apply)
      + id                        = (known after apply)
      + instance_id               = (known after apply)
      + label_fingerprint         = (known after apply)
      + machine_type              = "f1-micro"
      + metadata_fingerprint      = (known after apply)
      + min_cpu_platform          = (known after apply)
      + name                      = "circle-instance"
      + project                   = (known after apply)
      + self_link                 = (known after apply)
      + tags                      = [
          + "circle-web",
        ]
      + tags_fingerprint          = (known after apply)
      + zone                      = (known after apply)

      + boot_disk {
          + auto_delete                = true
          + device_name                = (known after apply)
          + disk_encryption_key_sha256 = (known after apply)
          + kms_key_self_link          = (known after apply)
          + mode                       = "READ_WRITE"
          + source                     = (known after apply)

          + initialize_params {
              + image  = "debian-cloud/debian-9"
              + labels = (known after apply)
              + size   = (known after apply)
              + type   = (known after apply)
            }
        }

      + confidential_instance_config {
          + enable_confidential_compute = (known after apply)
        }

      + network_interface {
          + name               = (known after apply)
          + network            = "circle-vpc"
          + network_ip         = (known after apply)
          + subnetwork         = "asia-east1-subnetwork1"
          + subnetwork_project = (known after apply)

          + access_config {
              + nat_ip       = (known after apply)
              + network_tier = (known after apply)
            }
        }

      + scheduling {
          + automatic_restart   = (known after apply)
          + on_host_maintenance = (known after apply)
          + preemptible         = (known after apply)

          + node_affinities {
              + key      = (known after apply)
              + operator = (known after apply)
              + values   = (known after apply)
            }
        }
    }

  # google_compute_network.vpc will be created
  + resource "google_compute_network" "vpc" {
      + auto_create_subnetworks         = false
      + delete_default_routes_on_create = false
      + gateway_ipv4                    = (known after apply)
      + id                              = (known after apply)
      + mtu                             = (known after apply)
      + name                            = "circle-vpc"
      + project                         = (known after apply)
      + routing_mode                    = (known after apply)
      + self_link                       = (known after apply)
    }

  # google_compute_subnetwork.subnetwork1 will be created
  + resource "google_compute_subnetwork" "subnetwork1" {
      + creation_timestamp         = (known after apply)
      + fingerprint                = (known after apply)
      + gateway_address            = (known after apply)
      + id                         = (known after apply)
      + ip_cidr_range              = "10.2.0.0/16"
      + name                       = "asia-east1-subnetwork1"
      + network                    = (known after apply)
      + private_ipv6_google_access = (known after apply)
      + project                    = (known after apply)
      + region                     = "asia-east1"
      + secondary_ip_range         = (known after apply)
      + self_link                  = (known after apply)
    }

Plan: 4 to add, 0 to change, 0 to destroy.

------------------------------------------------------------------------

This plan was saved to: terraform-lab1

To perform exactly these actions, run the following command to apply:
    terraform apply "terraform-lab1"
```

都沒問題的話，我們接著再執行下面的指令來部署我們的環境

```shell
terraform apply terraform-lab1
```

你會得到下面的輸出結果

```shell
google_compute_network.vpc: Creating...
google_compute_network.vpc: Still creating... [10s elapsed]
google_compute_network.vpc: Still creating... [20s elapsed]
google_compute_network.vpc: Still creating... [30s elapsed]
google_compute_network.vpc: Still creating... [40s elapsed]
google_compute_network.vpc: Creation complete after 44s [id=projects/sandbox-206307/global/networks/circle-vpc]
google_compute_subnetwork.subnetwork1: Creating...
google_compute_firewall.firewall: Creating...
google_compute_firewall.firewall: Still creating... [10s elapsed]
google_compute_subnetwork.subnetwork1: Still creating... [10s elapsed]
google_compute_subnetwork.subnetwork1: Creation complete after 13s [id=projects/sandbox-206307/regions/asia-east1/subnetworks/asia-east1-subnetwork1]
google_compute_instance.vm_instance: Creating...
google_compute_firewall.firewall: Creation complete after 14s [id=projects/sandbox-206307/global/firewalls/circle-firewall]
google_compute_instance.vm_instance: Still creating... [10s elapsed]
google_compute_instance.vm_instance: Creation complete after 16s [id=projects/sandbox-206307/zones/asia-east1-b/instances/circle-instance]

Apply complete! Resources: 4 added, 0 changed, 0 destroyed.

The state of your infrastructure has been saved to the path
below. This state is required to modify and destroy your
infrastructure, so keep it safe. To inspect the complete state
use the `terraform show` command.

State path: terraform.tfstate
```

最後在結束這個lab的時候要記得使用下面指令來刪除我們所建置的環境喔

```shell
terraform destroy
```

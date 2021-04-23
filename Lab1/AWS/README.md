就不多廢話了，我們直接上架構圖！！

![](images/451575819.png)

環境概述
----

Region：自己挑一個

Network

*   VPC
    
    *   CIDR：10.128.0.0/16
        
    *   Internet Gateways
        
*   Subnet
    
    *   CIDR：10.128.11.0/24
        
*   Route table
    
    *   Destination：0.0.0.0/0 , Target：igw
        

EC2：assign public ip

* * *

我習慣使用Visual Studio Code來開發，所以這邊我們就先安裝Terraform的[插件](https://marketplace.visualstudio.com/items?itemName=HashiCorp.terraform)。

接著建立`provider.tf`，來定義我們要使用的雲端平台。

這邊我們使用環境變數的方式來設定部署到SA Demo的環境去。

```shell
export AWS_ACCESS_KEY_ID="anaccesskey"
export AWS_SECRET_ACCESS_KEY="asecretkey"
```

```tcl
provider "aws" {
  region = "eu-west-3"
}
```

撰寫完`provider`之後，要執行下面指令來初始化

```shell
terraform init
```

每次只要有修改`provider`，都一定要記得重做一次初始化

接下來就是建立`vpc.tf`來定義我們的VPC，包括了`aws_vpc`、`aws_subnet`、`aws_internet_gateway`、`route_table_association`、`aws_route` 、`aws_route_table`。

```tcl
resource "aws_vpc" "vpc" {
  cidr_block           = "10.128.0.0/16"
  enable_dns_hostnames = "true"
  tags = {
    Name = "Circle vpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.vpc.id
  availability_zone = "eu-west-3a"
  cidr_block = "10.20.1.0/24"
  tags = {
    Name = "Circle subnet1"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Circle gateway"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route" "ipv4-outbound" {
  route_table_id         = aws_route_table.r.id
  gateway_id             = aws_internet_gateway.gw.id
  destination_cidr_block = "0.0.0.0/0"
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "Circle route"
  }
}
```

當然還不能忘了我們的Security Group，因為通常Security Group是最容易變動的設定，所以我習慣把它獨立在一個tf檔案中。我們建立一個，只允許公司五樓與六樓IP可以訪問22 port的Security Group。

```tcl
resource "aws_security_group" "sg" {
  name        = "allow_circle"
  description = "Allow circle inbound traffic"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["220.135.202.135/32", "211.75.165.158/32"]
  }

  tags = {
    Name = "allow_circle"
  }
}
```

最後的最後，就是我們的EC2啦。

我們可以透過`Data`來獲取`ubuntu 20.04`版本的ami id。

當然也不能忘記我們的`aws_network_interface`以及`aws_eip`，在設定`aws_network_interface`的時候別忘了要把前面的Security Group id給加進來。

這邊有一點要注意的地方是，在設定ec2的`key_name`時，只能選擇我們雲端環境上面現有的`key pair`，Terraform並不支援建立`key pair`的服務。

```tcl
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_instance" "ec2" {
  ami               = data.aws_ami.ubuntu.id
  instance_type     = "t2.micro"
  key_name          = "circle-sa-eu-west-3"

  network_interface {
    network_interface_id = aws_network_interface.network.id
    device_index         = 0
  }
  
  root_block_device{
    volume_size = 10
  }

  tags = {
    Name = "Circle ec2"
  }
}

resource "aws_network_interface" "network" {
  subnet_id       = aws_subnet.subnet1.id
  security_groups = [aws_security_group.sg.id]

  tags = {
    Name = "Circle network interface"
  }
}

resource "aws_eip" "ip" {
  instance = aws_instance.ec2.id
  tags = {
    Name = "Circle eip"
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

  # aws_eip.ip will be created
  + resource "aws_eip" "ip" {
      + allocation_id        = (known after apply)
      + association_id       = (known after apply)
      + carrier_ip           = (known after apply)
      + customer_owned_ip    = (known after apply)
      + domain               = (known after apply)
      + id                   = (known after apply)
      + instance             = (known after apply)
      + network_border_group = (known after apply)
      + network_interface    = (known after apply)
      + private_dns          = (known after apply)
      + private_ip           = (known after apply)
      + public_dns           = (known after apply)
      + public_ip            = (known after apply)
      + public_ipv4_pool     = (known after apply)
      + tags                 = {
          + "Name" = "Circle eip"
        }
      + vpc                  = (known after apply)
    }

  # aws_instance.ec2 will be created
  + resource "aws_instance" "ec2" {
      + ami                          = "ami-0b209583a4a1146dd"
      + arn                          = (known after apply)
      + associate_public_ip_address  = (known after apply)
      + availability_zone            = "eu-west-3a"
      + cpu_core_count               = (known after apply)
      + cpu_threads_per_core         = (known after apply)
      + get_password_data            = false
      + host_id                      = (known after apply)
      + id                           = (known after apply)
      + instance_state               = (known after apply)
      + instance_type                = "t2.micro"
      + ipv6_address_count           = (known after apply)
      + ipv6_addresses               = (known after apply)
      + key_name                     = "circle-sa-eu-west-3"
      + outpost_arn                  = (known after apply)
      + password_data                = (known after apply)
      + placement_group              = (known after apply)
      + primary_network_interface_id = (known after apply)
      + private_dns                  = (known after apply)
      + private_ip                   = (known after apply)
      + public_dns                   = (known after apply)
      + public_ip                    = (known after apply)
      + secondary_private_ips        = (known after apply)
      + security_groups              = (known after apply)
      + subnet_id                    = (known after apply)
      + tags                         = {
          + "Name" = "Circle ec2"
        }
      + tenancy                      = (known after apply)
      + volume_tags                  = (known after apply)
      + vpc_security_group_ids       = (known after apply)

      + ebs_block_device {
          + delete_on_termination = (known after apply)
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + snapshot_id           = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = (known after apply)
          + volume_type           = (known after apply)
        }

      + enclave_options {
          + enabled = (known after apply)
        }

      + ephemeral_block_device {
          + device_name  = (known after apply)
          + no_device    = (known after apply)
          + virtual_name = (known after apply)
        }

      + metadata_options {
          + http_endpoint               = (known after apply)
          + http_put_response_hop_limit = (known after apply)
          + http_tokens                 = (known after apply)
        }

      + network_interface {
          + delete_on_termination = false
          + device_index          = 0
          + network_interface_id  = (known after apply)
        }

      + root_block_device {
          + delete_on_termination = true
          + device_name           = (known after apply)
          + encrypted             = (known after apply)
          + iops                  = (known after apply)
          + kms_key_id            = (known after apply)
          + throughput            = (known after apply)
          + volume_id             = (known after apply)
          + volume_size           = 10
          + volume_type           = (known after apply)
        }
    }

  # aws_internet_gateway.gw will be created
  + resource "aws_internet_gateway" "gw" {
      + arn      = (known after apply)
      + id       = (known after apply)
      + owner_id = (known after apply)
      + tags     = {
          + "Name" = "Circle gateway"
        }
      + vpc_id   = (known after apply)
    }

  # aws_network_interface.network will be created
  + resource "aws_network_interface" "network" {
      + id                 = (known after apply)
      + ipv6_address_count = (known after apply)
      + ipv6_addresses     = (known after apply)
      + mac_address        = (known after apply)
      + outpost_arn        = (known after apply)
      + private_dns_name   = (known after apply)
      + private_ip         = (known after apply)
      + private_ips        = (known after apply)
      + private_ips_count  = (known after apply)
      + security_groups    = (known after apply)
      + source_dest_check  = true
      + subnet_id          = (known after apply)
      + tags               = {
          + "Name" = "Circle network interface"
        }

      + attachment {
          + attachment_id = (known after apply)
          + device_index  = (known after apply)
          + instance      = (known after apply)
        }
    }

  # aws_route.ipv4-outbound will be created
  + resource "aws_route" "ipv4-outbound" {
      + destination_cidr_block     = "0.0.0.0/0"
      + destination_prefix_list_id = (known after apply)
      + egress_only_gateway_id     = (known after apply)
      + gateway_id                 = (known after apply)
      + id                         = (known after apply)
      + instance_id                = (known after apply)
      + instance_owner_id          = (known after apply)
      + local_gateway_id           = (known after apply)
      + nat_gateway_id             = (known after apply)
      + network_interface_id       = (known after apply)
      + origin                     = (known after apply)
      + route_table_id             = (known after apply)
      + state                      = (known after apply)
    }

  # aws_route_table.r will be created
  + resource "aws_route_table" "r" {
      + id               = (known after apply)
      + owner_id         = (known after apply)
      + propagating_vgws = (known after apply)
      + route            = (known after apply)
      + tags             = {
          + "Name" = "Circle route"
        }
      + vpc_id           = (known after apply)
    }

  # aws_route_table_association.a will be created
  + resource "aws_route_table_association" "a" {
      + id             = (known after apply)
      + route_table_id = (known after apply)
      + subnet_id      = (known after apply)
    }

  # aws_security_group.sg will be created
  + resource "aws_security_group" "sg" {
      + arn                    = (known after apply)
      + description            = "Allow circle inbound traffic"
      + egress                 = (known after apply)
      + id                     = (known after apply)
      + ingress                = [
          + {
              + cidr_blocks      = [
                  + "220.135.202.135/32",
                  + "211.75.165.158/32",
                ]
              + description      = ""
              + from_port        = 22
              + ipv6_cidr_blocks = []
              + prefix_list_ids  = []
              + protocol         = "tcp"
              + security_groups  = []
              + self             = false
              + to_port          = 22
            },
        ]
      + name                   = "allow_circle"
      + owner_id               = (known after apply)
      + revoke_rules_on_delete = false
      + tags                   = {
          + "Name" = "allow_circle"
        }
      + vpc_id                 = (known after apply)
    }

  # aws_subnet.subnet1 will be created
  + resource "aws_subnet" "subnet1" {
      + arn                             = (known after apply)
      + assign_ipv6_address_on_creation = false
      + availability_zone               = "eu-west-3a"
      + availability_zone_id            = (known after apply)
      + cidr_block                      = "10.128.1.0/24"
      + id                              = (known after apply)
      + ipv6_cidr_block_association_id  = (known after apply)
      + map_public_ip_on_launch         = false
      + owner_id                        = (known after apply)
      + tags                            = {
          + "Name" = "Circle subnet1"
        }
      + vpc_id                          = (known after apply)
    }

  # aws_vpc.vpc will be created
  + resource "aws_vpc" "vpc" {
      + arn                              = (known after apply)
      + assign_generated_ipv6_cidr_block = false
      + cidr_block                       = "10.128.0.0/16"
      + default_network_acl_id           = (known after apply)
      + default_route_table_id           = (known after apply)
      + default_security_group_id        = (known after apply)
      + dhcp_options_id                  = (known after apply)
      + enable_classiclink               = (known after apply)
      + enable_classiclink_dns_support   = (known after apply)
      + enable_dns_hostnames             = true
      + enable_dns_support               = true
      + id                               = (known after apply)
      + instance_tenancy                 = "default"
      + ipv6_association_id              = (known after apply)
      + ipv6_cidr_block                  = (known after apply)
      + main_route_table_id              = (known after apply)
      + owner_id                         = (known after apply)
      + tags                             = {
          + "Name" = "Circle vpc"
        }
    }

Plan: 10 to add, 0 to change, 0 to destroy.

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
aws_vpc.vpc: Creating...
aws_vpc.vpc: Still creating... [10s elapsed]
aws_vpc.vpc: Creation complete after 17s [id=vpc-09ecccef1a8c265ec]
aws_internet_gateway.gw: Creating...
aws_route_table.r: Creating...
aws_subnet.subnet1: Creating...
aws_security_group.sg: Creating...
aws_route_table.r: Creation complete after 4s [id=rtb-0e97927b260c22678]
aws_subnet.subnet1: Creation complete after 4s [id=subnet-01c27a5431a15c968]
aws_route_table_association.a: Creating...
aws_route_table_association.a: Creation complete after 2s [id=rtbassoc-00ea42bdcd43f2f2a]
aws_internet_gateway.gw: Creation complete after 7s [id=igw-0805cd1c92a5143b9]
aws_route.ipv4-outbound: Creating...
aws_security_group.sg: Creation complete after 10s [id=sg-0c63ba0e322ec8e51]
aws_network_interface.network: Creating...
aws_route.ipv4-outbound: Creation complete after 4s [id=r-rtb-0e97927b260c226781080289494]
aws_network_interface.network: Still creating... [10s elapsed]
aws_network_interface.network: Still creating... [20s elapsed]
aws_network_interface.network: Still creating... [30s elapsed]
aws_network_interface.network: Creation complete after 34s [id=eni-0b7cef699193a9a04]
aws_instance.ec2: Creating...
aws_instance.ec2: Still creating... [10s elapsed]
aws_instance.ec2: Still creating... [20s elapsed]
aws_instance.ec2: Still creating... [30s elapsed]
aws_instance.ec2: Creation complete after 38s [id=i-0692c45e69261a444]
aws_eip.ip: Creating...
aws_eip.ip: Creation complete after 6s [id=eipalloc-002df7dd52853dc68]

Apply complete! Resources: 10 added, 0 changed, 0 destroyed.

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

# Configure the Huawei Cloud Provider
# Variables
variable "hw_region" {
  description = "The Huawei Cloud region to deploy the CTF lab"
  type        = string
  default     = "cn-north-4" # Beijing region
}

variable "hw_access_key" {
  description = "Huawei Cloud Access Key"
  type        = string
  sensitive   = true
}

variable "hw_secret_key" {
  description = "Huawei Cloud Secret Key"
  type        = string
  sensitive   = true
}

variable "use_local_setup" {
  description = "Use local ctf_setup.sh instead of fetching from GitHub (for testing)"
  type        = bool
  default     = false
}

# Configure the Huawei Cloud Provider
terraform {
  required_providers {
    huaweicloud = {
      source  = "huaweicloud/huaweicloud"
      version = ">= 1.36.0"
    }
  }
}

provider "huaweicloud" {
  region     = var.hw_region
  access_key = var.hw_access_key
  secret_key = var.hw_secret_key
}

# Fetch availability zones
data "huaweicloud_availability_zones" "available" {}

# Get Ubuntu 22.04 image
data "huaweicloud_images_image" "ubuntu" {
  name        = "Ubuntu 22.04 server 64bit"
  most_recent = true
  visibility  = "public"
}

# Create a VPC
resource "huaweicloud_vpc" "ctf_vpc" {
  name = "ctf-vpc"
  cidr = "10.0.0.0/16"

  tags = {
    Name = "CTF Lab VPC"
  }
}

# Create a Subnet
resource "huaweicloud_vpc_subnet" "ctf_subnet" {
  name       = "ctf-subnet"
  cidr       = "10.0.1.0/24"
  gateway_ip = "10.0.1.1"
  vpc_id     = huaweicloud_vpc.ctf_vpc.id

  tags = {
    Name = "CTF Lab Subnet"
  }
}

# Create a Security Group
resource "huaweicloud_networking_secgroup" "ctf_sg" {
  name        = "ctf-sg"
  description = "Security group for CTF lab"
}

# Security Group Rules
resource "huaweicloud_networking_secgroup_rule" "ssh" {
  security_group_id = huaweicloud_networking_secgroup.ctf_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 22
  port_range_max    = 22
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "http" {
  security_group_id = huaweicloud_networking_secgroup.ctf_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 80
  port_range_max    = 80
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "ctf_service" {
  security_group_id = huaweicloud_networking_secgroup.ctf_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8080
  port_range_max    = 8080
  remote_ip_prefix  = "0.0.0.0/0"
}

resource "huaweicloud_networking_secgroup_rule" "ctf_nginx" {
  security_group_id = huaweicloud_networking_secgroup.ctf_sg.id
  direction         = "ingress"
  ethertype         = "IPv4"
  protocol          = "tcp"
  port_range_min    = 8083
  port_range_max    = 8083
  remote_ip_prefix  = "0.0.0.0/0"
}

# Create an ECS Instance
resource "huaweicloud_compute_instance" "ctf_instance" {
  name               = "ctf-instance"
  image_id           = data.huaweicloud_images_image.ubuntu.id
  flavor_id          = "s6.small.1" # 1 vCPU, 1 GB RAM
  availability_zone  = data.huaweicloud_availability_zones.available.names[0]
  security_group_ids = [huaweicloud_networking_secgroup.ctf_sg.id]
  admin_pass         = "CTFpassword123!"

  system_disk_type = "SAS"
  system_disk_size = 20

  network {
    uuid = huaweicloud_vpc_subnet.ctf_subnet.id
  }

  # Use local file for testing, GitHub for production
  user_data = var.use_local_setup ? base64encode(file("${path.module}/../ctf_setup.sh")) : base64encode(<<-EOF
    #!/bin/bash
    # curl -fsSL https://raw.githubusercontent.com/learntocloud/linux-ctfs/main/ctf_setup.sh | bash
    curl -fsSL https://raw.githubusercontent.com/dethan3/linux-ctfs/huawei/ctf_setup.sh | bash
  EOF
  )

  tags = {
    Name = "CTF Lab Instance"
  }
}

# Create an EIP (Elastic IP)
resource "huaweicloud_vpc_eip" "ctf_eip" {
  publicip {
    type = "5_bgp"
  }

  bandwidth {
    name        = "ctf-bandwidth"
    size        = 5
    share_type  = "PER"
    charge_mode = "traffic"
  }

  tags = {
    Name = "CTF Lab EIP"
  }
}

# Associate EIP with the instance
resource "huaweicloud_compute_eip_associate" "ctf_eip_assoc" {
  public_ip   = huaweicloud_vpc_eip.ctf_eip.address
  instance_id = huaweicloud_compute_instance.ctf_instance.id
}

# Wait for setup completion
resource "null_resource" "wait_for_setup" {
  depends_on = [huaweicloud_compute_eip_associate.ctf_eip_assoc]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = huaweicloud_vpc_eip.ctf_eip.address
      user     = "root"
      password = "CTFpassword123!"
      timeout  = "10m"
    }

    inline = [
      "while [ ! -f /var/log/setup_complete ]; do sleep 10; done"
    ]
  }
}

# Output the public IP address
output "public_ip_address" {
  value      = huaweicloud_vpc_eip.ctf_eip.address
  depends_on = [null_resource.wait_for_setup]
}

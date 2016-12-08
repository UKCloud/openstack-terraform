provider "openstack" {
}

resource "openstack_compute_keypair_v2" "test-keypair" {
  name = "ukcloudos"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDggzO/9DNQzp8aPdvx0W+IqlbmbhpIgv1r2my1xOsVthFgx4HLiTB/2XEuEqVpwh5F+20fDn5Juox9jZAz+z3i5EI63ojpIMCKFDqDfFlIl54QPZVJUJVyQOe7Jzl/pmDJRU7vxTbdtZNYWSwjMjfZmQjGQhDd5mM9spQf3me5HsYY9Tko1vxGXcPE1WUyV60DrqSSBkrkSyf+mILXq43K1GszVj3JuYHCY/BBrupkhA126p6EoPtNKld4EyEJzDDNvK97+oyC38XKEg6lBgAngj4FnmG8cjLRXvbPU4gQNCqmrVUMljr3gYga+ZiPoj81NOuzauYNcbt6j+R1/B9qlze7VgNPYVv3ERzkboBdIx0WxwyTXg+3BHhY+E7zY1jLnO5Bdb40wDwl7AlUsOOriHL6fSBYuz2hRIdp0+upG6CNQnvg8pXNaNXNVPcNFPGLD1PuCJiG6x84+tLC2uAb0GWxAEVtWEMD1sBCp066dHwsivmQrYRxsYRHnlorlvdMSiJxpRo/peyiqEJ9Sa6OPl2A5JeokP1GxXJ6hyOoBn4h5WSuUVL6bS4J2ta7nA0fK6L6YreHV+dMdPZCZzSG0nV5qvSaAkdL7KuM4eeOvwcXAYMwZJPj+dCnGzwdhUIp/FtRy62mSHv5/kr+lVznWv2b2yl8L95SKAdfeOiFiQ== opensource@ukcloud.com"
}

resource "openstack_networking_network_v2" "example_network1" {
  name           = "example_network_1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "example_subnet1" {
  name            = "example_subnet_1"
  network_id      = "${openstack_networking_network_v2.example_network1.id}"
  cidr            = "10.10.0.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_compute_secgroup_v2" "example_secgroup_1" {
  name = "example_secgroup_1"
  description = "an example security group"
  rule {
    from_port   = 22
    to_port     = 22
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
   rule {
    from_port   = 80
    to_port     = 80
    ip_protocol = "tcp"
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_router_v2" "example_router_1" {
  name             = "example_router1"
  external_gateway = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

resource "openstack_networking_router_interface_v2" "example_router_interface_1" {
  router_id = "${openstack_networking_router_v2.example_router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.example_subnet1.id}"
}

resource "openstack_networking_floatingip_v2" "example_floatip_1" {
  pool = "internet"
}

data "template_file" "cloudinit" {
    template = "${file("cloudinit.sh")}"
    vars {
        application_env = "dev"
    }
}

resource "openstack_compute_instance_v2" "example_instance" {
  name            = "example_instance"

  #coreos
  #image_id        = "8e892f81-2197-464a-9b6b-1a5045735f5d"
  
  # centos7
  #image_id        = "0f1785b3-33c3-451e-92ce-13a35d991d60"
  
  # docker nginx
  #image_id        = "e24c8d96-4520-4554-b30a-14fec3605bc2"

  # centos7 lamp packer build
  image_id = "13bc3623-cb50-4709-9fc5-8897995b4590"
  
  flavor_id       = "c46be6d1-979d-4489-8ffe-e421a3c83fdd"
  key_pair        = "${openstack_compute_keypair_v2.test-keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup_1.name}"]

  user_data =  "${data.template_file.cloudinit.rendered}"

  network {
    name        = "${openstack_networking_network_v2.example_network1.name}"
    floating_ip = "${openstack_networking_floatingip_v2.example_floatip_1.address}"
  }
}

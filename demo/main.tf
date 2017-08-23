provider "openstack" {
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = "ukcloudos"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDggzO/9DNQzp8aPdvx0W+IqlbmbhpIgv1r2my1xOsVthFgx4HLiTB/2XEuEqVpwh5F+20fDn5Juox9jZAz+z3i5EI63ojpIMCKFDqDfFlIl54QPZVJUJVyQOe7Jzl/pmDJRU7vxTbdtZNYWSwjMjfZmQjGQhDd5mM9spQf3me5HsYY9Tko1vxGXcPE1WUyV60DrqSSBkrkSyf+mILXq43K1GszVj3JuYHCY/BBrupkhA126p6EoPtNKld4EyEJzDDNvK97+oyC38XKEg6lBgAngj4FnmG8cjLRXvbPU4gQNCqmrVUMljr3gYga+ZiPoj81NOuzauYNcbt6j+R1/B9qlze7VgNPYVv3ERzkboBdIx0WxwyTXg+3BHhY+E7zY1jLnO5Bdb40wDwl7AlUsOOriHL6fSBYuz2hRIdp0+upG6CNQnvg8pXNaNXNVPcNFPGLD1PuCJiG6x84+tLC2uAb0GWxAEVtWEMD1sBCp066dHwsivmQrYRxsYRHnlorlvdMSiJxpRo/peyiqEJ9Sa6OPl2A5JeokP1GxXJ6hyOoBn4h5WSuUVL6bS4J2ta7nA0fK6L6YreHV+dMdPZCZzSG0nV5qvSaAkdL7KuM4eeOvwcXAYMwZJPj+dCnGzwdhUIp/FtRy62mSHv5/kr+lVznWv2b2yl8L95SKAdfeOiFiQ== opensource@ukcloud.com"
}

resource "openstack_networking_network_v2" "example_network2" {
  name           = "example_network_2"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "example_subnet2" {
  name            = "example_subnet_2"
  network_id      = "${openstack_networking_network_v2.example_network2.id}"
  cidr            = "10.10.1.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_compute_secgroup_v2" "example_secgroup" {
  name = "example_secgroup"
  description = "an example security group"
  rule {
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
    cidr        = "0.0.0.0/0"
  }
   
  rule {
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_router_v2" "example_router_2" {
  name             = "example_router2"
  external_gateway = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

resource "openstack_networking_router_interface_v2" "example_router_interface_2" {
  router_id = "${openstack_networking_router_v2.example_router_2.id}"
  subnet_id = "${openstack_networking_subnet_v2.example_subnet2.id}"
}

resource "openstack_networking_floatingip_v2" "example_floatip_manager" {
  pool = "internet"
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.example_floatip_manager.address}"
  instance_id = "${openstack_compute_instance_v2.example_host.id}"
}

resource "openstack_compute_instance_v2" "example_host" {
  name            = "example_host"
  count = 1

  #Centos7
  image_id        = "0f1785b3-33c3-451e-92ce-13a35d991d60"
  region          = "regionOne"
  
  flavor_id       = "7d73f524-f9a1-4e80-bedf-57216aae8038"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup.name}"]

  network {
    name        = "${openstack_networking_network_v2.example_network2.name}"
  }
}

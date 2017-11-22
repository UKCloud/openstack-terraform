provider "openstack" {
}

resource "openstack_compute_keypair_v2" "keypair" {
  name = "openshift_ukcloudos"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDggzO/9DNQzp8aPdvx0W+IqlbmbhpIgv1r2my1xOsVthFgx4HLiTB/2XEuEqVpwh5F+20fDn5Juox9jZAz+z3i5EI63ojpIMCKFDqDfFlIl54QPZVJUJVyQOe7Jzl/pmDJRU7vxTbdtZNYWSwjMjfZmQjGQhDd5mM9spQf3me5HsYY9Tko1vxGXcPE1WUyV60DrqSSBkrkSyf+mILXq43K1GszVj3JuYHCY/BBrupkhA126p6EoPtNKld4EyEJzDDNvK97+oyC38XKEg6lBgAngj4FnmG8cjLRXvbPU4gQNCqmrVUMljr3gYga+ZiPoj81NOuzauYNcbt6j+R1/B9qlze7VgNPYVv3ERzkboBdIx0WxwyTXg+3BHhY+E7zY1jLnO5Bdb40wDwl7AlUsOOriHL6fSBYuz2hRIdp0+upG6CNQnvg8pXNaNXNVPcNFPGLD1PuCJiG6x84+tLC2uAb0GWxAEVtWEMD1sBCp066dHwsivmQrYRxsYRHnlorlvdMSiJxpRo/peyiqEJ9Sa6OPl2A5JeokP1GxXJ6hyOoBn4h5WSuUVL6bS4J2ta7nA0fK6L6YreHV+dMdPZCZzSG0nV5qvSaAkdL7KuM4eeOvwcXAYMwZJPj+dCnGzwdhUIp/FtRy62mSHv5/kr+lVznWv2b2yl8L95SKAdfeOiFiQ== opensource@ukcloud.com"
}

resource "openstack_networking_network_v2" "openshift_network" {
  name           = "openshift_network"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "openshift_subnet" {
  name            = "openshift_subnet"
  network_id      = "${openstack_networking_network_v2.openshift_network.id}"
  cidr            = "20.20.1.0/24"
  ip_version      = 4
  dns_nameservers = ["8.8.8.8", "8.8.4.4"]
}

resource "openstack_compute_secgroup_v2" "openshift_secgroup" {
  name = "openshift_secgroup"
  description = "openshift security group"

  rule {
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = 8443
    to_port     = 8443
    cidr        = "0.0.0.0/0"
  }
   
  rule {
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
    cidr        = "0.0.0.0/0"
  }
}

resource "openstack_networking_router_v2" "openshift_router" {
  name             = "openshift_router"
  external_gateway = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

resource "openstack_networking_router_interface_v2" "openshift_router_interface" {
  router_id = "${openstack_networking_router_v2.openshift_router.id}"
  subnet_id = "${openstack_networking_subnet_v2.openshift_subnet.id}"
}

resource "openstack_networking_floatingip_v2" "openshift_floatip_manager" {
  pool = "internet"
}

resource "openstack_compute_instance_v2" "openshift_host" {
  name            = "openshift_host_${count.index+1}"
  count = 1

  #Centos7
  image_id        = "d95d3c42-e586-43fd-b193-f728f57ffde8"
  #Packer-Built-Lamp
  #image_id        = "52629f96-9542-41b7-91e0-402068cf52c4"
  region          = "regionOne"
  
  flavor_id       = "a6a28b99-993b-4ce3-8caa-57613d73c52b"
  key_pair        = "${openstack_compute_keypair_v2.keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.openshift_secgroup.name}"]

  network {
    name        = "${openstack_networking_network_v2.openshift_network.name}"
  }
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.openshift_floatip_manager.address}"
  instance_id = "${openstack_compute_instance_v2.openshift_host.0.id}"

  
  provisioner "remote-exec" {
      inline = [
        "sudo sh -c 'service docker restart'",
        "sudo sh -c '/usr/local/sbin/oc cluster up --public-hostname=${openstack_networking_floatingip_v2.openshift_floatip_manager.address}'"
      ]
      connection {
        host = "${openstack_networking_floatingip_v2.openshift_floatip_manager.address}"
        user = "centos"
        timeout = "1m"
      }
    }
    
}

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

  rule {
    ip_protocol = "tcp"
    from_port   = 5601
    to_port     = 5601
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = 3000
    to_port     = 3000
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "tcp"
    from_port   = 2376
    to_port     = 2376
    cidr        = "0.0.0.0/0"
  }

  rule {
    ip_protocol = "icmp"
    from_port   = "-1"
    to_port     = "-1"
    self        = true
  }
  rule {
    ip_protocol = "tcp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
  }
  rule {
    ip_protocol = "udp"
    from_port   = "1"
    to_port     = "65535"
    self        = true
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

resource "openstack_networking_floatingip_v2" "example_floatip_manager" {
  pool = "internet"
}

data "template_file" "managerinit" {
    template = "${file("managerinit.sh")}"
    vars {
        swarm_manager = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
    }
}

data "template_file" "slaveinit" {
    template = "${file("slaveinit.sh")}"
    vars {
        swarm_manager = "${openstack_compute_instance_v2.swarm_manager.access_ip_v4}"
        node_count = "${var.swarm_node_count + 3}"
    }
}

resource "openstack_compute_floatingip_associate_v2" "fip_1" {
  floating_ip = "${openstack_networking_floatingip_v2.example_floatip_manager.address}"
  instance_id = "${openstack_compute_instance_v2.swarm_manager.id}"

  provisioner "file" {
    source      = "docker-compose.yml"
    destination = "/home/core/docker-compose.yml"
    connection {
      host = "${openstack_networking_floatingip_v2.example_floatip_manager.address}"
      user = "core"
      timeout = "1m"
    }
  }

  provisioner "remote-exec" {
    inline = [
      "chown core:core /home/core/docker-compose.yml",
      "docker swarm init",
      "docker swarm join-token --quiet worker > /home/core/worker-token",
      "docker swarm join-token --quiet manager > /home/core/manager-token",
      "docker stack deploy --compose-file /home/core/docker-compose.yml mystack > /dev/null"
    ]
    connection {
      host = "${openstack_networking_floatingip_v2.example_floatip_manager.address}"
      user = "core"
      timeout = "1m"
    }
  }

}

resource "openstack_compute_instance_v2" "swarm_manager" {
  name            = "swarm_manager_0"
  count = 1

  #coreos-docker-alpha
  image_id        = "9804b597-4b13-41b5-a77d-2fc6d798d4ac"
  
  flavor_id       = "7d73f524-f9a1-4e80-bedf-57216aae8038"
  key_pair        = "${openstack_compute_keypair_v2.test-keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup_1.name}"]

  network {
    name        = "${openstack_networking_network_v2.example_network1.name}"
  }

  
}

resource "openstack_compute_instance_v2" "swarm_managerx" {
  name            = "swarm_manager_${count.index+1}"
  count           = 2

  #coreos-docker-alpha
  image_id        = "9804b597-4b13-41b5-a77d-2fc6d798d4ac"
  
  flavor_id       = "7d73f524-f9a1-4e80-bedf-57216aae8038"
  key_pair        = "${openstack_compute_keypair_v2.test-keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup_1.name}"]

  user_data       =  "${data.template_file.managerinit.rendered}"

  network {
    name          = "${openstack_networking_network_v2.example_network1.name}"
  }
}


resource "openstack_compute_instance_v2" "swarm_slave" {
  name            = "swarm_slave_${count.index}"
  count           = "${var.swarm_node_count}"

  #coreos-docker-alpha
  image_id        = "9804b597-4b13-41b5-a77d-2fc6d798d4ac"
  
  flavor_id       = "c46be6d1-979d-4489-8ffe-e421a3c83fdd"
  key_pair        = "${openstack_compute_keypair_v2.test-keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup_1.name}"]

  user_data       = "${data.template_file.slaveinit.rendered}"

  network {
    name        = "${openstack_networking_network_v2.example_network1.name}"
  }
}


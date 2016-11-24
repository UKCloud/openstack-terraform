provider "openstack" {
}

resource "openstack_compute_keypair_v2" "test-keypair" {
  name = "bobbyKeypair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDTaCOFI3z2bs5fRF3bHZpT03cmH/6wbZgjO5NKqb8xHRXYx6HiQWiP2GVV+F281MHC/ZJ5RaU1ex+uSm6ZCymMu9sHVhqViqeNHpHQadPRGApJKS5JDbpvQKxx/FH2kC7yV8mUfdsYHbMFQnJVtfef7LuZqJtvyOMzs/pXUfpq3rhgtcWkAtiu1C9QB/S7OoZztjjiVKx4SUZUTQxiw4PKTWvsdZ5Ctdd1IUgtseXoHYCf4NI5BBcA4sFNBJAAmatdlD7id+4kSSkTlIlBUudWidMoQzEczk+tFGHSd3Mp2dc205SlbmJhktWeOUCxdqmwzFljlV3L8ZvGllkVBXyR bdeveaux@ukcloud.com"
}

resource "openstack_networking_network_v2" "example_network1" {
  name = "example_network_1"
  admin_state_up = "true"
}

resource "openstack_networking_subnet_v2" "example_subnet1" {
  name = "example_subnet_1"
  network_id = "${openstack_networking_network_v2.example_network1.id}"
  cidr = "10.10.0.0/24"
  ip_version = 4
}

resource "openstack_compute_secgroup_v2" "example_secgroup_1" {
  name = "example_secgroup_1"
  description = "an example security group"
  rule {
    from_port = 22
    to_port = 22
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
   rule {
    from_port = 80
    to_port = 80
    ip_protocol = "tcp"
    cidr = "0.0.0.0/0"
  }
}

resource "openstack_networking_router_v2" "example_router_1" {
  name = "example_router1"
  external_gateway = "893a5b59-081a-4e3a-ac50-1e54e262c3fa"
}

resource "openstack_networking_router_interface_v2" "example_router_interface_1" {
  router_id = "${openstack_networking_router_v2.example_router_1.id}"
  subnet_id = "${openstack_networking_subnet_v2.example_subnet1.id}"
}

resource "openstack_networking_floatingip_v2" "example_floatip_1" {
  pool = "internet"
}

resource "openstack_compute_instance_v2" "example_instance" {
  name = "example_instance"
  image_id = "8e892f81-2197-464a-9b6b-1a5045735f5d"
  flavor_id = "c46be6d1-979d-4489-8ffe-e421a3c83fdd"
  key_pair = "${openstack_compute_keypair_v2.test-keypair.name}"
  security_groups = ["${openstack_compute_secgroup_v2.example_secgroup_1.name}"]

  metadata {
    this = "that"
  }

  network {
    name = "${openstack_networking_network_v2.example_network1.name}"
    floating_ip = "${openstack_networking_floatingip_v2.example_floatip_1.address}"
  }
}

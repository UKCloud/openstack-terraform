provider "openstack" {
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
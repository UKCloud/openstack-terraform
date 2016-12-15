variable "clone_location" {
    default = "docker-swarm"
}

variable "git_repo" {
	default = "https://github.com/UKCloud/openstack-docker-swarm.git"
}

variable "swarm_node_count" {
	default = 10
}
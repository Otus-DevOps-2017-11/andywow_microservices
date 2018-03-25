module "infra" {
  source             = "./modules/infra"
  project            = "${var.project}"
  zone               = "${var.zone}"
  initial_node_count = "${var.initial_node_count}"
  gke_min_version    = "${var.gke_min_version}"
  node_disk_size     = "${var.node_disk_size}"
}

#module "containers" {
#  source       = "./modules/containers"
#  host_address = "${module.infra.endpoint_ip}"


#  username = "${module.infra.username}"
#  password = "${module.infra.password}"


#  client_certificate     = "${module.infra.client_certificate}"
#  client_key             = "${module.infra.client_key}"
#  cluster_ca_certificate = "${module.infra.cluster_ca_certificate}"
#}


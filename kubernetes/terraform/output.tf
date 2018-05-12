output "endpoint_ip" {
  value = "${module.infra.endpoint_ip}"
}

output "client_certificate" {
  value = "${module.infra.client_certificate}"
}

output "client_key" {
  value = "${module.infra.client_key}"
}

output "cluster_ca_certificate" {
  value = "${module.infra.cluster_ca_certificate}"
}

output "username" {
  value = "${module.infra.username}"
}

output "password" {
  value = "${module.infra.password}"
}

data "kubernetes_service" "ingress_nginx" {
  metadata {
    name = "ingress-nginx"#????
    namespace = "ingress-nginx"
  }
}

resource "google_dns_record_set" "a_records" {
  for_each = var.dns_config.a_record_settings
  name = "${each.value.dns_name}.${var.dns_config.managed_zone_dns_name}"
  type = each.value.type
  ttl  = each.value.ttl

  managed_zone = var.dns_config.managed_zone_google_resource_name

  #rrdatas = each.value.rrdatas
  rrdatas = data.kubernetes_service.ingress_nginx.spec.load_balancer_ip
}
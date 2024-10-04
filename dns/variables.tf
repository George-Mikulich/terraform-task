variable "dns_config" {
  type = object({
    managed_zone_dns_name             = string
    managed_zone_google_resource_name = string
    a_record_settings = map(object({
      dns_name = string
      type     = string
      ttl      = number
      rrdatas  = list(string)
    }))
  })
}

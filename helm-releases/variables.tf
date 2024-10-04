variable "helm_configs" {
  type = map(object({
    dependency_level = number
    create_namespace = bool
    wait             = bool
    release_name     = string
    repo             = string
    chart            = string
    namespace        = string
    version          = string
    values           = map(string)
  }))
}
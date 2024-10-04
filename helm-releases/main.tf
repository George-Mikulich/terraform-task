# Releases are grouped to enable dependencies

resource "helm_release" "independent_releases" {
  for_each = {
    for release in var.helm_configs : release.release_name => release
                                     # filtering releases
    if release.dependency_level == 0 # that are marked as independent,
                                     # i.e. dependency level equals to zero
  }
  create_namespace = each.value.create_namespace
  wait             = each.value.wait

  name       = each.value.release_name
  repository = each.value.repo
  chart      = each.value.chart
  namespace  = each.value.namespace
  version    = each.value.version
  dynamic "set" {
    for_each = each.value.values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "level1_releases" {
  depends_on = [helm_release.independent_releases]
  for_each = {
    for release in var.helm_configs : release.release_name => release
    if release.dependency_level == 1
  }
  create_namespace = each.value.create_namespace
  wait             = each.value.wait

  name       = each.value.release_name
  repository = each.value.repo
  chart      = each.value.chart
  namespace  = each.value.namespace
  version    = each.value.version
  dynamic "set" {
    for_each = each.value.values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "level2_releases" {
  depends_on = [helm_release.level1_releases]
  for_each = {
    for release in var.helm_configs : release.release_name => release
    if release.dependency_level == 2
  }
  create_namespace = each.value.create_namespace
  wait             = each.value.wait

  name       = each.value.release_name
  repository = each.value.repo
  chart      = each.value.chart
  namespace  = each.value.namespace
  version    = each.value.version
  dynamic "set" {
    for_each = each.value.values
    content {
      name  = set.key
      value = set.value
    }
  }
}

resource "helm_release" "level3_releases" {
  depends_on = [helm_release.level2_releases]
  for_each = {
    for release in var.helm_configs : release.release_name => release
    if release.dependency_level == 3
  }
  create_namespace = each.value.create_namespace
  wait             = each.value.wait

  name       = each.value.release_name
  repository = each.value.repo
  chart      = each.value.chart
  namespace  = each.value.namespace
  version    = each.value.version
  dynamic "set" {
    for_each = each.value.values
    content {
      name  = set.key
      value = set.value
    }
  }
}
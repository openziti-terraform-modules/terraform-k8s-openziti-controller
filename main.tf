resource "helm_release" "ziti_controller" {
    count            = var.install == true ? 1 : 0  # install unless false
    namespace        = var.ziti_namespace
    create_namespace = var.create_namespace
    name             = var.ziti_controller_release
    version          = var.chart_version
    repository       = var.chart_repo
    chart            = var.ziti_charts != "" ? "${var.ziti_charts}/ziti-controller" : "ziti-controller"
    wait             = var.helm_release_wait
    wait_for_jobs    = var.helm_release_wait_for_jobs
    timeout          = var.helm_release_timeout
    values           = [yamlencode(merge({
        image = {
            repository = var.image_repo
            tag = var.image_tag
        }
        clientApi = {
            advertisedHost = "${var.client_domain_name}.${var.dns_zone}"
            advertisedPort = 443
            ingress = {
                enabled = true
                ingressClassName = var.ingress_class
                annotations = var.ingress_annotations
            }
            service = {
                enabled = true
                type = "ClusterIP"
            }
        }
        ctrlPlane = {
            advertisedHost = "${var.ctrl_domain_name}.${var.dns_zone}"
            advertisedPort = 443
            ingress = {
                enabled = true
                ingressClassName = var.ingress_class
                annotations = var.ingress_annotations
            }
            service = {
                enabled = true
                type = "ClusterIP"
            }
        }
        edgeSignerPki = {
            enabled = true
        }
        webBindingPki = {
            enabled = true
        }
        managementApi = {
            advertisedHost = "${var.mgmt_domain_name}.${var.dns_zone}"
            advertisedPort = 443
            dnsNames = [var.mgmt_dns_san]
            ingress = {
                enabled = var.mgmt_ingress_enabled
                ingressClassName = var.ingress_class
                annotations = var.ingress_annotations
            }
            service = {
                enabled = true
                type = "ClusterIP"
            }
        }
        prometheus = {
            service = {
                enabled = var.prometheus_enabled
                type = "ClusterIP"
            }
        }
        persistence = {
            storageClass = var.storage_class != "-" ? var.storage_class : ""
        }
        cert-manager = {
            enabled = false
        }
        trust-manager = {
            enabled = false
        }
        ingress-nginx = {
            enabled = false
        }
    },
    var.values
    ))]
}

data "kubernetes_secret" "admin_password_secret" {
    depends_on = [helm_release.ziti_controller]
    metadata {
        name = "${var.ziti_controller_release}-admin-secret"
        namespace = var.ziti_namespace
    }
}

data "kubernetes_secret" "admin_client_cert_secret" {
    depends_on = [helm_release.ziti_controller]
    metadata {
        name = "${var.ziti_controller_release}-admin-client-secret"
        namespace = var.ziti_namespace
    }
}

data "kubernetes_config_map" "ctrl_trust_bundle" {
    depends_on = [helm_release.ziti_controller]
    metadata {
        name = "${var.ziti_controller_release}-ctrl-plane-cas"
        namespace = var.ziti_namespace
    }
}

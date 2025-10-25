# Fetch the most recent ACM certificate for the given domain
data "aws_acm_certificate" "my_certificate" {
  domain      = "abc1234567.dpdns.org"  # The domain associated with the certificate
  most_recent = true
  statuses    = ["ISSUED"]
}
# Ingress Resource for the application
resource "kubernetes_ingress_v1" "prod_ingress" {
  metadata {
    name      = "my-app"
    namespace = "default"
    annotations = {
      "alb.ingress.kubernetes.io/scheme"           = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"      = "ip"
      "alb.ingress.kubernetes.io/certificate-arn"  = data.aws_acm_certificate.my_certificate.arn
      "alb.ingress.kubernetes.io/listen-ports"     = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/backend-protocol" = "HTTP"
      "alb.ingress.kubernetes.io/healthcheck-path" = "/login"
    }
  }

  spec {
    ingress_class_name = "alb"  # Use ALB Ingress controller

    rule {
      host = "abc1234567.dpdns.org"  # Set the host for the ingress

      http {
        path {
          path      = "/"  # Path to root
          path_type = "Prefix"
          backend {
            service {
              name = "my-grafana"  # Grafana service name
              port {
                number = 80  # Service port
              }
            }
          }
        }
      }
    }
  }
}
resource "null_resource" "wait_for_ingress" {
  depends_on = [kubernetes_ingress_v1.prod_ingress]

  provisioner "local-exec" {
    command = "sleep 40"  # Delay to allow Ingress to populate its status
  }
}

# Fetch the Route 53 hosted zone
data "aws_route53_zone" "selected" {
  name = "abc1234567.dpdns.org"
}
locals {
  # Extract the ALB base name (before the first hyphen after the 6th part)
  alb_name = join("-", slice(split("-", kubernetes_ingress_v1.prod_ingress.status[0].load_balancer[0].ingress[0].hostname), 0, 4)) # Grab first 4 parts
}

#data "aws_lb" "my_alb" {
#  name = local.alb_name  # Use the local value for ALB name
#}
# Create a Route 53 DNS A record pointing to the ALB
resource "aws_route53_record" "app_dns" {
  zone_id = data.aws_route53_zone.selected.zone_id
  name    = "abc1234567.dpdns.org"
  type    = "A"

  alias {
    name                   = kubernetes_ingress_v1.prod_ingress.status[0].load_balancer[0].ingress[0].hostname  # Dynamically fetch ALB hostname
    zone_id                = data.aws_lb.my_alb.zone_id # Hosted zone ID for ALB (typically the same for all AWS regions)
    evaluate_target_health = true
  }
}

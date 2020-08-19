data "aws_route53_zone" "example" {
  name = "0x0-dev.co.uk"
}

resource "aws_route53_zone" "example_sub" {
  name = "test.0x0-dev.co.uk"
  tags = {
    Name = "terraform_example"
  }
}

resource "aws_route53_record" "example" {
  depends_on      = [aws_route53_zone.example_sub]
  allow_overwrite = true
  name            = "test.0x0-dev.co.uk"
  ttl             = 30
  type            = "NS"
  zone_id         = data.aws_route53_zone.example.zone_id

  records = [
    aws_route53_zone.example_sub.name_servers.0,
    aws_route53_zone.example_sub.name_servers.1,
    aws_route53_zone.example_sub.name_servers.2,
    aws_route53_zone.example_sub.name_servers.3,
  ]
}

resource "aws_route53_record" "example_sub" {
  //zone_id = data.aws_route53_zone.example.zone_id
  //name = data.aws_route53_zone.example.name
  zone_id = aws_route53_zone.example_sub.zone_id
  name    = aws_route53_zone.example_sub.name
  type    = "A"

  alias {
    name                   = aws_lb.example.dns_name
    zone_id                = aws_lb.example.zone_id
    evaluate_target_health = true
  }
}

output "domain_name" {
  value = aws_route53_record.example_sub.name
}

/*ACM*/

resource "aws_acm_certificate" "example" {
  provider                  = aws.us-east-1
  domain_name               = data.aws_route53_zone.example.name
  // *に変える
  //subject_alternative_names = [aws_route53_record.example_sub.name]
  subject_alternative_names = ["*.${data.aws_route53_zone.example.name}"]
  validation_method         = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_route53_record" "example_certificate" {
  for_each = {
    for dvo in aws_acm_certificate.example.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
      //zone_id = dvo.domain_name == "example.org" ? data.aws_route53_zone.example_org.zone_id : data.aws_route53_zone.example_com.zone_id
      zone_id = data.aws_route53_zone.example.zone_id
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = each.value.zone_id
}

resource "aws_acm_certificate_validation" "example" {
  provider                = aws.us-east-1
  certificate_arn         = aws_acm_certificate.example.arn
  validation_record_fqdns = [for record in aws_route53_record.example_certificate : record.fqdn]
  //validation_record_fqdns = [aws_route53_record.example_certificate.fqdn, aws_route53_record.example_certificate_alt.fqdn]
}

/*
resource "aws_route53_record" "example_certificate" {
  name    = aws_acm_certificate.example.domain_validation_options.0.resource_record_name
  type    = aws_acm_certificate.example.domain_validation_options.0.resource_record_type
  records = [aws_acm_certificate.example.domain_validation_options.0.resource_record_value]
  zone_id = data.aws_route53_zone.example.id
  ttl     = 60
}

resource "aws_route53_record" "example_certificate_alt" {
  name = aws_acm_certificate.example.domain_validation_options.1.resource_record_name
  type = aws_acm_certificate.example.domain_validation_options.1.resource_record_type
  records =[aws_acm_certificate.example.domain_validation_options.1.resource_record_value]
  zone_id = data.aws_route53_zone.example.id
  ttl = 60
}"

*/
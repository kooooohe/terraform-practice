data "aws_route53_zone" "example" {
    name = "0x0-dev.co.uk"
}

resource "aws_route53_zone" "example_test" {
  name = "test.0x0-dev.co.uk"
  tags = {
      Name = "terraform_example"
  }
}

resource "aws_route53_record" "example_additional" {
  depends_on = [aws_route53_zone.example_test]
  allow_overwrite = true
  name            = "test.0x0-dev.co.uk"
  ttl             = 30
  type            = "NS"
  zone_id         = data.aws_route53_zone.example.zone_id

  records = [
    aws_route53_zone.example_test.name_servers.0,
    aws_route53_zone.example_test.name_servers.1,
    aws_route53_zone.example_test.name_servers.2,
    aws_route53_zone.example_test.name_servers.3,
  ]
}

resource "aws_route53_record" "example" {
  //zone_id = data.aws_route53_zone.example.zone_id
  //name = data.aws_route53_zone.example.name
  zone_id = aws_route53_zone.example_test.zone_id
  name = aws_route53_zone.example_test.name
  type = "A"

  alias {
      name = aws_lb.example.dns_name
      zone_id = aws_lb.example.zone_id
      evaluate_target_health = true
  }
}

output "domain_name" {
    value = aws_route53_record.example.name
}
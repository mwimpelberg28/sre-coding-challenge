resource "aws_route53_record" "jenkinsarecord" {
  zone_id = "Z02412603KAY5FNIOZJCK"
  name    = "jenkins.mwdevops.com"
  type    = "A"
  ttl = 30
  records = [module.jenkins-0.public_ip]
}
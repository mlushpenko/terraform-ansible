output "elb-link" {
	value = "${aws_elb.web.dns_name}"
}
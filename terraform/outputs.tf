# Display ELB IP address

output "elb_dns_name" {
  value = "${aws_elb.web-elb.dns_name}"
}


output "mysql_ip_address" {
value = "${aws_db_instance.web-rds-01.address}"
}


output "web01_ip_address" {
value = "${aws_instance.web01.public_ip}"
}

output "web02_ip_address" {
value = "${aws_instance.web02.public_ip}"
}


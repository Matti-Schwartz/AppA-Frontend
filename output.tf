output "publicIPv4" {
  value = aws_instance.vm.public_ip
}

output "publicDNS" {
  value = aws_instance.vm.public_dns
}
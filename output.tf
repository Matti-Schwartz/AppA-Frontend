output "publicIPv4" {
  value = aws_instance.vm.public_ip
}

output "publicIPv4_DB" {
  value = aws_db_instance.vm.public_ip
}
output "DB_Secret_Id" {
  value = var.db_secret_id
}

output "ADWC_Service_Console_URL" {
  value = module.adb.adwc_console
}

output "VM_Private_IP" {
  value = module.compute.private_ip
}

output "VM_Public_IP" {
  value = module.compute.public_ip != null ? module.compute.public_ip : null
}

output "VM_OS_Image" {
  value = module.compute.usage_image
}


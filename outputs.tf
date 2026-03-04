output "vm_internal_ip" {
  value = google_compute_instance.test_vm.network_interface[0].network_ip
}

output "vm_external_ip" {
  value = google_compute_instance.test_vm.network_interface[0].access_config[0].nat_ip
}
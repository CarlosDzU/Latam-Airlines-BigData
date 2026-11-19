output "master_instance_id" {
  description = "ID del master; lo usa scripts/tunel.sh para abrir el túnel."
  value       = aws_instance.master.id
}

output "worker_instance_ids" {
  description = "IDs de los workers."
  value       = aws_instance.worker[*].id
}

output "master_private_ip" {
  description = "IP privada del master dentro de la VPC."
  value       = aws_instance.master.private_ip
}

output "bucket_name" {
  description = "Bucket con el que trabaja el clúster."
  value       = local.bucket
}

output "bucket_name" {
  description = "Nombre del bucket del data lake."
  value       = aws_s3_bucket.lake.bucket
}

output "bucket_arn" {
  description = "ARN del bucket (lo usa infra/procesamiento para los permisos de la EC2)."
  value       = aws_s3_bucket.lake.arn
}

output "glue_database" {
  description = "Base de datos del catálogo de Glue."
  value       = aws_glue_catalog_database.lake.name
}

output "crawler_name" {
  description = "Crawler que registra las tablas de silver y gold."
  value       = aws_glue_crawler.lake.name
}

output "athena_workgroup" {
  description = "Workgroup de Athena para consultar el lake."
  value       = aws_athena_workgroup.lake.name
}

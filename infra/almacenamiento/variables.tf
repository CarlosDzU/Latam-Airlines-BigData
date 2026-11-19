variable "region" {
  description = "Región de AWS donde vive todo el proyecto."
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo de los nombres y valor de la etiqueta Project."
  type        = string
  default     = "latam-bigdata"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.proyecto))
    error_message = "Solo minúsculas, números y guiones (3 a 20 caracteres)."
  }
}

variable "owner" {
  description = "Responsable de los recursos (etiqueta Owner)."
  type        = string
}

variable "alert_emails" {
  description = "Correos que reciben las alertas de presupuesto."
  type        = list(string)

  validation {
    condition     = length(var.alert_emails) > 0
    error_message = "Debe haber al menos un correo."
  }
}

variable "budget_usd" {
  description = "Presupuesto mensual en dólares."
  type        = number
  default     = 100
}

variable "force_destroy" {
  description = "Si es true, terraform destroy borra el bucket aunque tenga datos. Dejar en false salvo al cerrar el proyecto."
  type        = bool
  default     = false
}

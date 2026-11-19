variable "region" {
  description = "Región de AWS (la misma de infra/almacenamiento)."
  type        = string
  default     = "us-east-1"
}

variable "proyecto" {
  description = "Prefijo de los nombres y valor de la etiqueta Project."
  type        = string
  default     = "latam-bigdata"
}

variable "owner" {
  description = "Responsable de los recursos (etiqueta Owner)."
  type        = string
}

variable "instance_type" {
  description = "Tipo de instancia de cada nodo. Solo tipos permitidos en el plan gratuito de la cuenta."
  type        = string
  default     = "m7i-flex.large"

  validation {
    condition     = contains(["t3.micro", "t3.small", "c7i-flex.large", "m7i-flex.large"], var.instance_type)
    error_message = "Tipos permitidos: t3.micro, t3.small, c7i-flex.large, m7i-flex.large."
  }
}

variable "worker_count" {
  description = "Workers además del master (0 a 2). El master también ejecuta un worker."
  type        = number
  default     = 0

  validation {
    condition     = var.worker_count >= 0 && var.worker_count <= 2
    error_message = "worker_count debe estar entre 0 y 2."
  }
}

variable "ebs_gb" {
  description = "Tamaño del disco de cada nodo en GB."
  type        = number
  default     = 30
}

variable "idle_stop_minutes" {
  description = "Minutos con CPU por debajo del 5 % antes de que la instancia se apague sola (múltiplo de 15)."
  type        = number
  default     = 45

  validation {
    condition     = var.idle_stop_minutes >= 15 && var.idle_stop_minutes % 15 == 0
    error_message = "Debe ser múltiplo de 15 y al menos 15."
  }
}

variable "repo_url" {
  description = "Repositorio que se clona en los nodos al arrancar."
  type        = string
  default     = "https://github.com/CarlosDzU/Latam-Airlines-BigData.git"
}

variable "repo_rama" {
  description = "Rama que se clona en los nodos."
  type        = string
  default     = "prod"
}

variable "spark_version" {
  description = "Versión de Spark 3.5.x (binario hadoop3 de archive.apache.org)."
  type        = string
  default     = "3.5.9"

  validation {
    condition     = can(regex("^3\\.5\\.[0-9]+$", var.spark_version))
    error_message = "Solo Spark 3.5.x."
  }
}

variable "spark_sha512" {
  description = "SHA-512 publicado de spark-<version>-bin-hadoop3.tgz; si se cambia la versión hay que cambiarlo también."
  type        = string
  default     = "66097faf48b12f8673dc13256a44d731c27c86a5831cd8ca930c6fd9dd9bdf31d40593095e959461351d55da1a8e3ad5ed95e0b4b51bea87ca3989ab002ea8ce"
}

variable "memoria" {
  description = "Memoria de Spark para nodos de 8 GiB. El master aloja además el driver, por eso su worker recibe menos."
  type = object({
    worker_en_master = string
    worker           = string
    driver           = string
    executor         = string
    executor_cores   = number
  })
  default = {
    worker_en_master = "4g"
    worker           = "6g"
    driver           = "2g"
    executor         = "3g"
    executor_cores   = 2
  }
}

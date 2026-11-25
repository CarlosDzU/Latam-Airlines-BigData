# Latam Airlines Big Data

Proyecto integrador del curso **Big Data y Analítica de Datos** (UPAO, 2026-20).

Alerta temprana del riesgo de demora en la salida de los vuelos de LATAM Airlines, dos horas antes de la hora programada, a partir de datos públicos de vuelos (Brasil y EE. UU.) y de clima aeronáutico (METAR). El procesamiento corre con Apache Spark en AWS sobre un data lake en S3 organizado en capas bronze, silver y gold.

## Equipo

| Integrante | Rol (Unidad 1) |
| :---- | :---- |
| Carlos Alonso Díaz Uceda | Ingeniería de datos |
| Jherson Manuel Vásquez Castillo | Coordinación |
| Jhon Denis Maximiliano Villanueva | Análisis y modelado |
| Alejandro Del Piero Oliden Agreda | Calidad y documentación |

## Arquitectura

| Capa | Servicio | Dónde se define |
| :---- | :---- | :---- |
| Almacenamiento | Bucket S3 con zonas `bronze/`, `silver/` y `gold/`, cifrado y sin acceso público | `infra/almacenamiento` |
| Catálogo y consulta SQL | AWS Glue Data Catalog y Amazon Athena | `infra/almacenamiento` |
| Control de gasto | AWS Budgets con alertas por correo | `infra/almacenamiento` |
| Procesamiento | Clúster Spark 3.5 en EC2 (un master y de 0 a 2 workers) con JupyterLab | `infra/procesamiento` |
| Acceso | AWS Systems Manager (Session Manager): sin SSH ni puertos abiertos a internet | `scripts/tunel.sh` |

El almacenamiento se crea una vez y se conserva durante todo el proyecto. El procesamiento se crea al empezar cada sesión de trabajo y se destruye al terminarla.

## Fuentes de datos

| Fuente | Entidad | Contenido |
| :---- | :---- | :---- |
| Voo Regular Ativo (VRA) | ANAC, Agência Nacional de Aviação Civil (Brasil) | Cada vuelo regular operado en Brasil, con horarios previstos y reales |
| Reporting Carrier On-Time Performance | Bureau of Transportation Statistics (EE. UU.) | Cada vuelo doméstico de las aerolíneas de EE. UU., con horarios programados y reales |
| Archivo ASOS/METAR | Iowa Environmental Mesonet, Iowa State University | Reportes meteorológicos de cada aeropuerto en texto METAR |

Los datos completos no se versionan: los notebooks de ingesta los descargan de las fuentes oficiales. `data/muestra/` está reservada para una muestra pequeña de datos reales y por ahora está vacía.

## Estructura del repositorio

| Carpeta | Contenido |
| :---- | :---- |
| `config/` | `pipeline.yaml`: rutas, periodo, fuentes, umbrales y aerolíneas; ningún notebook tiene estos valores escritos en el código |
| `infra/almacenamiento/` | Terraform del bucket, Glue, Athena y presupuesto |
| `infra/procesamiento/` | Terraform de la red, el clúster Spark y su arranque |
| `notebooks/` | El pipeline completo, en el orden en que se ejecuta |
| `scripts/` | `tunel.sh`: túneles hacia Jupyter y la interfaz de Spark |
| `tests/` | Reservada para las pruebas (aún no hay ninguna) |
| `data/muestra/` | Reservada para una muestra pequeña de los datos reales (aún vacía) |
| `docs/` | Evidencias que generan los notebooks, en `docs/evidencias/` |

## Notebooks

| Notebook | Qué hace |
| :---- | :---- |
| `01_Ingesta-Vuelos-Brasil` | Descarga ANAC VRA a bronze |
| `02_Ingesta-Vuelos-EEUU` | Descarga BTS a bronze |
| `03_Ingesta-Clima-METAR` | Descarga el METAR de los aeropuertos y la ficha de cada uno a bronze |
| `04_Exploracion-Datos-Crudos` | Describe los datos de bronze y genera el diccionario de columnas |
| `05_Silver-Vuelos` | Limpia y unifica los vuelos de Brasil y EE. UU.: horarios en UTC y hora local del aeropuerto de origen |
| `06_Silver-Clima` | Convierte el texto METAR en columnas y arma el clima por hora |
| `07_Calidad-Datos` | Reglas de calidad sobre silver y su reporte |
| `08_Gold-Features` | Variables de cada vuelo con información disponible dos horas antes de la salida |
| `09_Analisis-Exploratorio` | Preguntas de negocio respondidas con gráficos |
| `10_Modelo-Base` | Modelo base frente a una referencia trivial |
| `11_Rendimiento-Escalabilidad` | Optimizaciones medidas y prueba de escalabilidad |

---

## Puesta en marcha

### 1. Requisitos en tu equipo

| Herramienta | Versión | Para qué |
| :---- | :---- | :---- |
| [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html) | 2.x | Autenticarse en AWS y usar S3 |
| [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) | 1.2 o superior | Abrir los túneles hacia el clúster |
| [Terraform](https://developer.hashicorp.com/terraform/install) | 1.10 o superior | Crear y destruir la infraestructura |
| Git | — | Clonar el repositorio |

Comprobación:

```sh
aws --version
session-manager-plugin --version
terraform version
```

### 2. Credenciales de AWS

Se necesita un usuario IAM con permisos para S3, EC2, VPC, IAM, Glue, Athena, CloudWatch, Systems Manager y Budgets, y una clave de acceso para la línea de comandos. Las credenciales se guardan con la AWS CLI, **nunca dentro del repositorio**:

```sh
aws configure --profile <nombre-del-perfil>
# AWS Access Key ID:     <tu clave de acceso>
# AWS Secret Access Key: <tu clave secreta>
# Default region name:   us-east-1
# Default output format: json
```

### 3. Clonar y configurar

```sh
git clone https://github.com/CarlosDzU/Latam-Airlines-BigData.git
cd Latam-Airlines-BigData
git checkout prod
```

Crea tus archivos locales a partir de las plantillas. Ninguno se sube a git:

```sh
cp .env.example .env
cp infra/almacenamiento/terraform.tfvars.example infra/almacenamiento/terraform.tfvars
cp infra/procesamiento/terraform.tfvars.example infra/procesamiento/terraform.tfvars
```

| Archivo | Qué completar |
| :---- | :---- |
| `.env` | `AWS_PROFILE`: el nombre del perfil creado en el paso 2. `AWS_REGION`: `us-east-1` |
| `infra/almacenamiento/terraform.tfvars` | `owner`: responsable de los recursos. `alert_emails`: correos que reciben las alertas de gasto |
| `infra/procesamiento/terraform.tfvars` | `owner`. `worker_count`: workers además del master (0 a 2). Opcional: `idle_stop_minutes` (múltiplo de 15, mínimo 15) |

Carga el perfil en la terminal (en cada terminal nueva) y comprueba la identidad:

```sh
set -a; . ./.env; set +a
aws sts get-caller-identity
```

### 4. Desplegar el almacenamiento (una sola vez)

Primero comprueba si ya está desplegado:

```sh
terraform -chdir=infra/almacenamiento output bucket_name
```

Si muestra un nombre como `latam-bigdata-lake-xxxxxxxx`, **el almacenamiento ya existe: pasa al paso 5.** Si muestra un aviso de que no hay outputs, despliégalo:

```sh
cd infra/almacenamiento
terraform init
terraform plan
terraform apply
cd ../..
```

Al terminar llega un correo de AWS Budgets para confirmar la suscripción a las alertas.

> El estado de Terraform se guarda localmente en `infra/*/terraform.tfstate` y no se versiona. La infraestructura la administra una sola persona desde su equipo; sin ese archivo, Terraform no reconoce los recursos ya creados.

> `infra/procesamiento` lee el nombre del bucket de `infra/almacenamiento/terraform.tfstate`. Para desplegar el procesamiento desde otro equipo, pide ese archivo a quien administra la infraestructura y colócalo en esa ruta. No vuelvas a desplegar el almacenamiento: crearía un segundo bucket vacío.

### 5. Desplegar el procesamiento (al empezar cada sesión)

```sh
cd infra/procesamiento
terraform init
terraform plan
terraform apply
cd ../..
```

Terraform termina en unos 2 minutos, pero cada nodo necesita unos 3 a 5 minutos más para instalar Spark y JupyterLab y clonar este repositorio (rama `prod`).

Para las ingestas largas (por ejemplo el METAR, que casi no usa CPU) sube `idle_stop_minutes` en `terraform.tfvars` antes del `apply`: si no, la alarma de inactividad apaga el nodo a los 45 minutos.

### 6. Abrir los túneles

```sh
./scripts/tunel.sh
```

Deja esa terminal abierta. Ctrl+C cierra los túneles.

`tunel.sh` es un script de bash (Linux, macOS o WSL) y obtiene el ID del nodo del estado de Terraform del procesamiento, así que se ejecuta en el mismo equipo donde hiciste el `terraform apply`.

| Dirección | Qué es |
| :---- | :---- |
| [http://localhost:8888](http://localhost:8888) | JupyterLab, con este repositorio |
| [http://localhost:8080](http://localhost:8080) | Spark master: nodos conectados y aplicaciones |
| [http://localhost:4040](http://localhost:4040) | La aplicación de Spark en curso |
| [http://localhost:18080](http://localhost:18080) | Spark History Server: aplicaciones terminadas |

En Linux y WSL, si un puerto ya está ocupado en tu equipo, el script lo avisa y no abre ese túnel (la comprobación usa `ss`, que macOS no trae).

### 7. Ejecutar el pipeline

En JupyterLab abre **File → New → Terminal** y trae la última versión del repositorio:

```sh
cd ~/Latam-Airlines-BigData
git pull
```

Luego abre los notebooks de `notebooks/` **en orden** (01 → 11) y ejecuta sus celdas de arriba abajo. Los de ingesta (01 a 03) no repiten las descargas de vuelos y METAR que ya están en bronze, así que pueden volver a ejecutarse sin duplicar datos; la ficha de aeropuertos del 03 sí se consulta completa en cada ejecución.

Para guardar en GitHub un notebook ejecutado desde el clúster (el nodo es nuevo en cada sesión, así que hay que configurar la identidad de git y autenticarse de nuevo):

```sh
git config user.name "<tu nombre>"
git config user.email "<tu correo de GitHub>"
gh auth login                     # una vez por sesión
git checkout -b <rol>/<tema>
git add notebooks/<notebook>.ipynb docs/evidencias
git commit -m "<tipo>(<alcance>): <descripción>"
git push -u origin <rol>/<tema>
gh pr create --base prod --fill
```

Lo que no esté en GitHub ni en el bucket se pierde al destruir el procesamiento.

### 8. Destruir el procesamiento (al terminar cada sesión)

Cierra los túneles (Ctrl+C) y ejecuta:

```sh
cd infra/procesamiento
terraform destroy
cd ../..
```

Los datos permanecen en el bucket. Si alguna vez la alarma de inactividad apagó el nodo, este paso también lo elimina.

### 9. Destruir el almacenamiento (solo al cerrar el proyecto)

> ⚠️ **Esto borra el bucket y todos los datos de bronze, silver y gold, además del catálogo, Athena y las alertas de gasto. No se puede deshacer.** Destruye primero el procesamiento (paso 8). Si quieres conservar los datos, descárgalos antes con `aws s3 sync s3://<bucket> <carpeta-local>`.

```sh
cd infra/almacenamiento
terraform apply -var force_destroy=true      # permite borrar el bucket aunque tenga datos
terraform destroy -var force_destroy=true
cd ../..
```

Sin `force_destroy=true`, Terraform se niega a borrar un bucket con datos.

---

## Costo aproximado

| Recurso | Costo |
| :---- | :---- |
| Nodo `m7i-flex.large` encendido | ~US$ 0,10 por hora por nodo |
| Bucket S3 | ~US$ 0,023 por GB al mes |
| Athena | US$ 5 por TB escaneado (tope de 10 GB por consulta) |
| Glue (crawler) | Solo cuando se ejecuta |

El procesamiento se apaga solo tras 45 minutos sin uso de CPU, pero siempre debe destruirse al terminar.

## Cómo contribuir

- Se trabaja sobre la rama `prod`; la rama `main` no se modifica.
- Cada cambio va en una rama propia, con prefijo según el rol (`ingenieria/`, `coordinacion/`, `analisis/`, `calidad/`), y llega a `prod` por pull request revisado por otro integrante.
- Los mensajes de commit siguen [Conventional Commits](https://www.conventionalcommits.org/es/v1.0.0/): `feat`, `fix`, `docs`, `test`, `refactor`, `chore`.
- Antes de crear una rama: `git checkout prod && git pull`.

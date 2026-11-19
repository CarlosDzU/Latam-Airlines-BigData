"""Creación de la sesión de Spark con la configuración del proyecto."""

from __future__ import annotations

import os
import shutil
import tempfile

from pyspark.sql import SparkSession

from comun.config import RAIZ_REPO, bucket, cargar_config


def crear_sesion(nombre: str) -> SparkSession:
    """Sesión conectada al clúster en la EC2 (toma spark-defaults.conf) o local[*] en una laptop."""
    cfg = cargar_config()["spark"]
    constructor = SparkSession.builder.appName(f"{cfg['nombre_app']}-{nombre}")

    if not bucket():
        constructor = (
            constructor.master("local[*]")
            .config("spark.sql.shuffle.partitions", str(cfg["particiones_shuffle_local"]))
            .config("spark.ui.showConsoleProgress", "false")
        )

    sesion = (
        constructor.config("spark.sql.session.timeZone", "UTC")
        .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
        .config("spark.sql.adaptive.enabled", "true")
        .config("spark.sql.parquet.compression.codec", "snappy")
        .getOrCreate()
    )
    sesion.sparkContext.setLogLevel(os.environ.get("SPARK_LOG", "WARN"))

    # En el clúster, los workers necesitan el mismo código de src/ que el driver.
    if not sesion.sparkContext.master.startswith("local"):
        zip_src = shutil.make_archive(os.path.join(tempfile.mkdtemp(), "src"), "zip", RAIZ_REPO / "src")
        sesion.sparkContext.addPyFile(zip_src)

    return sesion

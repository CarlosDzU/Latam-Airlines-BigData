"""Lectura de config/pipeline.yaml y resolución de rutas del lake."""

from __future__ import annotations

import os
from functools import cache
from pathlib import Path
from typing import Any

import yaml

RAIZ_REPO = Path(__file__).resolve().parents[2]


@cache
def cargar_config() -> dict[str, Any]:
    """Devuelve el contenido de config/pipeline.yaml."""
    with open(RAIZ_REPO / "config" / "pipeline.yaml", encoding="utf-8") as f:
        return yaml.safe_load(f)


def base_lake() -> str:
    """Raíz del lake: s3a://<bucket> en la EC2 (variable LAKE_BUCKET) o data/lake en local."""
    bucket = os.environ.get("LAKE_BUCKET", "").strip()
    if bucket:
        return f"s3a://{bucket}"
    local = (RAIZ_REPO / cargar_config()["lake"]["raiz_local"]).resolve()
    local.mkdir(parents=True, exist_ok=True)
    return local.as_uri()


def ruta(tabla: str) -> str:
    """Ruta completa de una tabla declarada en lake.tablas, por ejemplo ruta('silver_vuelos')."""
    return f"{base_lake()}/{cargar_config()['lake']['tablas'][tabla]}"


def bucket() -> str | None:
    """Nombre del bucket, o None si se trabaja en local."""
    return os.environ.get("LAKE_BUCKET", "").strip() or None


def empresas_latam_pasajeros() -> list[str]:
    """Códigos ICAO de las empresas de pasajeros del grupo LATAM."""
    return sorted(cargar_config()["latam"]["pasajeros"])


def meses(desde: str, hasta: str) -> list[tuple[int, int]]:
    """Lista de (año, mes) entre dos fechas 'AAAA-MM', ambas incluidas."""
    anio, mes = map(int, desde.split("-"))
    anio_fin, mes_fin = map(int, hasta.split("-"))
    salida = []
    while (anio, mes) <= (anio_fin, mes_fin):
        salida.append((anio, mes))
        anio, mes = (anio + 1, 1) if mes == 12 else (anio, mes + 1)
    return salida

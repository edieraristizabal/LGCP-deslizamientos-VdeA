# LGCP — Movimientos en Masa, Valle de Aburrá (Colombia)

Análisis espacial de movimientos en masa (deslizamientos) en el Valle de Aburrá mediante un **Log-Gaussian Cox Process (LGCP)** con aproximación SPDE e inferencia bayesiana INLA/inlabru.

---

## Estructura del repositorio

```
LGCP/
├── CODE/                          # Scripts de análisis
│   ├── MenM_VdeA_procesamiento.ipynb   # Notebook Python: limpieza, DEM, covariables
│   ├── LGCP_deslizamientos_VdeA.R      # Modelo LGCP principal (inlabru + INLA)
│   ├── install_inla.R                  # Instalación de INLA y paquetes R
│   ├── check_pkgs.R                    # Verificación de paquetes R
│   ├── check_rasters.R                 # Verificación de rasters de covariables
│   ├── check_nodes_covs.R              # Diagnóstico nodos de malla vs covariables
│   ├── mesh_stats.R                    # Estadísticas de la malla SPDE
│   ├── diag_covs.R                     # Diagnóstico de covariables
│   └── diag_confounding.R              # Diagnóstico de confusión espacial
├── DATA/                          # Datos de entrada (ver nota abajo)
│   ├── MenM_VdeA_clean.gpkg           # Puntos limpios (5,686 registros)
│   └── MenM_VdeA_dem.gpkg            # Puntos con atributos topográficos (2,504 registros)
└── FIG/                           # Figuras de salida
    ├── MenM_VdeA_revision.png
    ├── MenM_VdeA_spatial_distribution.png
    ├── MenM_VdeA_hexbin_densidad.png
    ├── MenM_VdeA_mapa_elevacion.png
    ├── 01_mesh_spde.png            ─┐
    ├── 02_efectos_fijos.png         │
    ├── 03_hiperparametros_spde.png  │
    ├── 04_mapa_intensidad_predicha.png│  Figuras del modelo LGCP
    ├── 05_mapa_incertidumbre.png    │
    ├── 06_mapa_campo_latente.png    │
    ├── 07_panel_mapas.png           │
    ├── 08_obs_vs_predicho.png       │
    ├── 09_mapa_residuos.png         │
    ├── 10_obs_vs_predicho_mapas.png │
    ├── 11_diagnostico_cpo.png       │
    └── 12_curva_roc.png            ─┘
```

---

## Datos requeridos (no incluidos en el repositorio)

Los siguientes archivos superan los límites de GitHub y deben obtenerse/generarse por separado:

| Archivo | Tamaño | Descripción | Cómo obtener |
|---|---|---|---|
| `DATA/MDT_05001_20241102-002.tif` | ~3.4 GB | DEM 1 m — municipio de Medellín | Fuente institucional |
| `DATA/MenM_VdeA.gpkg` | ~15 MB | Inventario bruto original | Fuente institucional |
| `DATA/MenM_VdeA_Polygon.gpkg` | ~20 MB | Polígono del Valle de Aburrá | Fuente institucional |
| `DATA/cov_elevacion.tif` | ~17 MB | Raster de elevación (10 m) | Generado con el notebook |
| `DATA/cov_pendiente.tif` | ~19 MB | Raster de pendiente (10 m) | Generado con el notebook |
| `DATA/cov_aspecto.tif` | ~19 MB | Raster de aspecto (10 m) | Generado con el notebook |
| `DATA/cov_log_area_acum.tif` | ~11 MB | log₁₀(área acumulada, 10 m) | Generado con el notebook |

> Los rasters de covariables se regeneran ejecutando `CODE/MenM_VdeA_procesamiento.ipynb` con el DEM original.

---

## Requisitos

### Python (notebook de preprocesamiento)
```
geopandas >= 0.14
rasterio >= 1.3
numpy >= 1.24
scipy >= 1.11
matplotlib >= 3.7
contextily >= 1.4
pysheds >= 0.3
fiona >= 1.9
pyproj >= 3.6
```

Instalar con:
```bash
pip install geopandas rasterio numpy scipy matplotlib contextily pysheds fiona pyproj
```

### R (modelo LGCP)
```r
# Ejecutar primero:
source("CODE/install_inla.R")
```

Paquetes: `INLA`, `inlabru`, `sf`, `terra`, `ggplot2`, `patchwork`, `viridis`, `scales`, `pROC`

---

## Flujo de trabajo

```
1. Preprocesamiento (Python)
   └── CODE/MenM_VdeA_procesamiento.ipynb
       ├── Limpieza del inventario → DATA/MenM_VdeA_clean.gpkg
       ├── Extracción de atributos DEM (elevación, pendiente, aspecto)
       ├── Área acumulada (D8, pysheds)
       ├── Generación de rasters de covariables → DATA/cov_*.tif
       └── Figuras exploratorias → FIG/

2. Modelado LGCP (R)
   └── CODE/LGCP_deslizamientos_VdeA.R
       ├── Dominio: casco convexo + buffer 500 m ∩ máscara DEM
       ├── Malla SPDE triangular (max.edge = 1,000/3,000 m)
       ├── Covariables estandarizadas (z-score)
       ├── Ajuste con inlabru::lgcp() + INLA
       └── 12 figuras de resultados → FIG/
```

---

## Modelo estadístico

El modelo asume que los deslizamientos son una realización de un **proceso puntual de Poisson no homogéneo** con intensidad log-gaussiana:

```
log λ(s) = β₀ + β₁·elev(s) + β₂·pend(s) + β₃·asp(s) + β₄·log_acc(s) + ξ(s)
```

donde `ξ(s)` es un **Campo Aleatorio Gaussiano (GRF)** con covarianza de Matérn (α=2), aproximado mediante la ecuación diferencial parcial estocástica de Lindgren et al. (2011). La inferencia se realiza con **INLA** (Rue et al. 2009).

---

## Referencias

- Lindgren, F., Rue, H., & Lindström, J. (2011). An explicit link between Gaussian fields and Gaussian Markov random fields: the stochastic partial differential equation approach. *JRSS-B*, 73(4), 423–498.
- Rue, H., Martino, S., & Chopin, N. (2009). Approximate Bayesian inference for latent Gaussian models. *JRSS-B*, 71(2), 319–392.
- Simpson, D., et al. (2017). Penalising model component complexity: A principled, practical approach to constructing priors. *Statistical Science*, 32(1), 1–28.
- Bachl, F.E., et al. (2019). inlabru: an R package for Bayesian spatial modelling from ecological survey data. *Methods in Ecology and Evolution*, 10(6), 760–766.

---

## Autor

Edier Aristizabal — [edieraristizabal@gmail.com](mailto:edieraristizabal@gmail.com)

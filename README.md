# NHPP — Análisis espacial de movimientos en masa en Medellín

Análisis espacial de la susceptibilidad a los movimientos en masa mediante un **Proceso de Poisson No Homogéneo (NHPP)** con aproximación INLA e inferencia bayesiana. Aplicación en Medellín, Colombia, utilizando un Modelo Digital de Elevación de 2 m.

---

## Estructura del repositorio

```
.
├── CODE/                          # Scripts de análisis en R
│   ├── 01_preprocesar_covariables.R    # Limpieza, estandarización y preparación de datos
│   └── 02_IPP_dem2m.R                  # Modelo NHPP-INLA principal
├── DATA/                          # Datos de entrada (ver nota abajo)
│   ├── MenM_VdeA_clean.gpkg            # Inventario de movimientos en masa
│   ├── MenM_VdeA_dem.gpkg              # Atributos topográficos extraídos
│   ├── cobertura_2024.tif               # Capa de cobertura urbana
│   └── (otros rasters de covariables)
├── FIG/                           # Figuras de salida del modelo
│   ├── 2m_01_mesh.png                  # Malla de integración
│   ├── 2m_02_efectos_fijos.png          # Coeficientes posteriores
│   ├── 2m_04_intensidad.png             # Mapa de intensidad media
│   ├── 2m_05_incertidumbre.png          # Mapa de desviación estándar
│   ├── 2m_09_residuos.png               # Mapa de residuos de Pearson
│   └── 2m_12_roc.png                    # Curva ROC (AUC = 0.762)
├── manuscrito.tex                  # Manuscrito del artículo científico
└── referencias.bib                 # Bibliografía del estudio
```

---

## Datos requeridos

Los rasters de alta resolución (MDE 1m/2m) superan los límites de GitHub y se manejan localmente. El repositorio incluye las versiones procesadas y remuestreadas necesarias para la ejecución del modelo, siempre que su tamaño sea inferior a 100 MB.

---

## Modelo estadístico

El modelo asume que los movimientos en masa son una realización de un **proceso puntual de Poisson no homogéneo** con intensidad log-lineal:

```
log λ(s) = β₀ + β₁·pendiente(s) + β₂·aspecto(s) + β₃·urb(s) + β₄·suelos_finos(s)
```

La inferencia se realiza mediante la **Aproximación de Laplace Anidada Integrada (INLA)** utilizando el dispositivo de integración de Berman-Turner sobre una malla triangular de alta resolución.

---

## Resultados principales

- **Pendiente**: β₁ = 0.901 (Efecto dominante positivo).
- **Aspecto**: β₂ = -0.243 (Mayor susceptibilidad en laderas orientadas al norte).
- **AUC**: 0.762 (Buena capacidad discriminativa).

---

## Autor
**Edier Aristizábal** — Universidad Nacional de Colombia, Sede Medellín.
[edieraristizabal@gmail.com](mailto:edieraristizabal@gmail.com)

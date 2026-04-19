# =============================================================================
# PREPROCESAMIENTO DE COVARIABLES A 1m
# Deriva slope, aspect y TWI directamente del DEM de 1m
# =============================================================================
# Salidas:
#   DATA/cov1m_pendiente.tif    — pendiente en grados
#   DATA/cov1m_aspecto.tif      — aspecto en grados
#   DATA/cov1m_twi.tif          — TWI = log(A_esp / tan(slope_rad))
# =============================================================================

library(terra)

BASE <- "/home/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP-deslizamientos-VdeA"
DATA <- file.path(BASE, "DATA")

t0_total <- proc.time()

# ─── 1. Cargar DEM ────────────────────────────────────────────────────────────
cat("=== Cargando DEM 1m ===\n")
dem <- rast(file.path(DATA, "dem_medellin_1m.tif"))
cat("  Resolución:", res(dem), "m\n")
cat("  Dimensiones:", nrow(dem), "x", ncol(dem),
    "=", format(ncell(dem), big.mark = ","), "píxeles\n")
cat("  CRS:", crs(dem, describe = TRUE)$code, "\n\n")

# ─── 2. Pendiente ─────────────────────────────────────────────────────────────
cat("=== Calculando pendiente (grados) ===\n")
t0 <- proc.time()
slope_1m <- terrain(dem, v = "slope", unit = "degrees", neighbors = 8)
names(slope_1m) <- "slope"
writeRaster(slope_1m, file.path(DATA, "cov1m_pendiente.tif"),
            overwrite = TRUE, datatype = "FLT4S",
            gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=6"))
cat("  Tiempo:", round((proc.time() - t0)["elapsed"], 1), "s\n")
cat("  Rango:", round(minmax(slope_1m), 2), "°\n\n")
rm(slope_1m); gc()

# ─── 3. Aspecto ───────────────────────────────────────────────────────────────
cat("=== Calculando aspecto (grados) ===\n")
t0 <- proc.time()
aspect_1m <- terrain(dem, v = "aspect", unit = "degrees", neighbors = 8)
names(aspect_1m) <- "aspect"
writeRaster(aspect_1m, file.path(DATA, "cov1m_aspecto.tif"),
            overwrite = TRUE, datatype = "FLT4S",
            gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=6"))
cat("  Tiempo:", round((proc.time() - t0)["elapsed"], 1), "s\n\n")
rm(aspect_1m); gc()

# ─── 4. Dirección de flujo ────────────────────────────────────────────────────
cat("=== Calculando dirección de flujo (D8) ===\n")
t0 <- proc.time()
flowdir_1m <- terrain(dem, v = "flowdir", neighbors = 8)
cat("  Tiempo:", round((proc.time() - t0)["elapsed"], 1), "s\n\n")

# ─── 5. Acumulación de flujo ──────────────────────────────────────────────────
cat("=== Calculando acumulación de flujo ===\n")
t0 <- proc.time()
flowacc_1m <- flowAccumulation(flowdir_1m, filename = "", progress = TRUE)
cat("  Tiempo:", round((proc.time() - t0)["elapsed"], 1), "s\n\n")
rm(flowdir_1m); gc()

# ─── 6. TWI = log( A_esp / tan(slope_rad) ) ──────────────────────────────────
# A_esp = acumulación × área_celda / longitud_celda = acumulación × res_x
# Equivale a: A_esp = flowacc × res_x  (área de drenaje específica en m²/m = m)
cat("=== Calculando TWI ===\n")
t0 <- proc.time()

res_m    <- res(dem)[1]            # 1 m
slope_r  <- rast(file.path(DATA, "cov1m_pendiente.tif"))

# Área de drenaje específica (m)
A_esp <- flowacc_1m * res_m
rm(flowacc_1m); gc()

# tan(slope) — usar mínimo para evitar división por cero en zonas planas
slope_rad <- slope_r * (pi / 180)
tan_slope  <- tan(slope_rad)
tan_slope  <- ifel(tan_slope < 0.001, 0.001, tan_slope)   # piso = 0.057°
rm(slope_r, slope_rad); gc()

twi_1m <- log(A_esp / tan_slope)
names(twi_1m) <- "twi"
rm(A_esp, tan_slope); gc()

writeRaster(twi_1m, file.path(DATA, "cov1m_twi.tif"),
            overwrite = TRUE, datatype = "FLT4S",
            gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "ZLEVEL=6"))
cat("  Tiempo:", round((proc.time() - t0)["elapsed"], 1), "s\n")
cat("  Rango TWI:", round(minmax(twi_1m), 3), "\n\n")
rm(twi_1m); gc()

# ─── 7. Verificación final ────────────────────────────────────────────────────
cat("=== Verificación ===\n")
archivos <- c("cov1m_pendiente.tif", "cov1m_aspecto.tif", "cov1m_twi.tif")
for (f in archivos) {
  r <- rast(file.path(DATA, f))
  cat(sprintf("  %-25s  res=%gm  min=%.3f  max=%.3f  NA=%s%%\n",
              f, res(r)[1], minmax(r)[1], minmax(r)[2],
              round(100 * global(is.na(r), "mean")[[1]], 1)))
}

cat(sprintf("\nTiempo total: %.1f min\n",
            (proc.time() - t0_total)["elapsed"] / 60))

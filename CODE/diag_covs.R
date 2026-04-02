library(sf); library(terra); library(inlabru); library(fmesher)

BASE <- "C:/Users/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP"
DATA <- file.path(BASE, "DATA")

pts_wgs <- st_read(file.path(DATA, "MenM_VdeA_dem.gpkg"), quiet=TRUE)
pts     <- st_transform(pts_wgs, crs=9377)
if (attr(pts,"sf_column")!="geometry")
  pts <- st_sf(st_drop_geometry(pts), geometry=st_geometry(pts), crs=9377)

cov_elev  <- rast(file.path(DATA,"cov_elevacion.tif"))
cov_slope <- rast(file.path(DATA,"cov_pendiente.tif"))

elev_mean <- global(cov_elev,"mean",na.rm=TRUE)[[1]]
elev_sd   <- global(cov_elev,"sd",  na.rm=TRUE)[[1]]
cov_sc    <- c((cov_elev - elev_mean)/elev_sd)
names(cov_sc) <- "elev_sc"

# 1. ¿Qué tipo de objeto ve inlabru?
cat("Clase cov_sc$elev_sc:", class(cov_sc$elev_sc), "\n")
cat("Clase cov_sc['elev_sc']:", class(cov_sc["elev_sc"]), "\n")

# 2. ¿inlabru 2.12 soporta SpatRaster?
cat("inlabru versión:", as.character(packageVersion("inlabru")), "\n")
cat("terra en namespace inlabru:", "terra" %in% loadedNamespaces(), "\n")

# 3. Extraer valores manualmente en los puntos — ¿coincide con columnas del gpkg?
vals_terra <- terra::extract(cov_sc, st_coordinates(pts))[,1]
cat("\nCovariable elev_sc extraída manualmente (primeros 6):\n")
print(head(vals_terra))
cat("¿Hay NA?", any(is.na(vals_terra)), "| NAs:", sum(is.na(vals_terra)), "\n")

# 4. Columnas del gpkg original
cat("\nColumnas en pts:", paste(names(pts), collapse=", "), "\n")
if ("elevacion" %in% names(pts)) {
  elev_col_scaled <- (pts$elevacion - elev_mean) / elev_sd
  cat("Correlación extracción vs columna gpkg:",
      round(cor(vals_terra, elev_col_scaled, use="complete.obs"), 4), "\n")
}

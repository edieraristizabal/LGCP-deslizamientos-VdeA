library(sf)
library(terra)
library(fmesher)

BASE <- "C:/Users/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP"
DATA <- file.path(BASE, "DATA")

# Cargar puntos y raster igual que en el script principal
pts_wgs  <- st_read(file.path(DATA, "MenM_VdeA_dem.gpkg"), quiet = TRUE)
pts      <- st_transform(pts_wgs, crs = 9377)
if (attr(pts, "sf_column") != "geometry")
  pts <- st_sf(st_drop_geometry(pts), geometry = st_geometry(pts), crs = 9377)

cov_elev <- rast(file.path(DATA, "cov_elevacion.tif"))

domain <- st_convex_hull(st_union(pts)) |> st_buffer(500) |> st_as_sf()
st_crs(domain) <- 9377
dem_mask <- as.polygons(ifel(!is.na(cov_elev), 1, NA)) |> st_as_sf() |> st_union() |> st_as_sf()
st_crs(dem_mask) <- 9377
domain_final <- st_intersection(domain, dem_mask)
domain_final <- st_sf(geometry = st_union(st_geometry(domain_final)), crs = 9377)

bnd  <- fmesher::fm_as_segm(domain_final)
mesh <- fmesher::fm_mesh_2d(
  boundary = bnd,
  max.edge = c(1000, 3000),
  offset   = c(1000, 5000),
  cutoff   = 300,
  crs      = sf::st_crs(9377)
)

# Calcular áreas de los triángulos (fórmula del determinante)
loc  <- mesh$loc[, 1:2]
tv   <- mesh$graph$tv
areas <- apply(tv, 1, function(idx) {
  p <- loc[idx, ]
  0.5 * abs((p[2,1]-p[1,1])*(p[3,2]-p[1,2]) - (p[3,1]-p[1,1])*(p[2,2]-p[1,2]))
})
areas_km2 <- areas / 1e6

cat("=== Estadísticas del área de triángulos de la malla SPDE ===\n")
cat(sprintf("Nº de triángulos : %d\n",    length(areas_km2)))
cat(sprintf("Área mínima      : %.5f km²  (%.1f m²)\n",  min(areas_km2),    min(areas)))
cat(sprintf("Área máxima      : %.4f km²  (%.1f m²)\n",  max(areas_km2),    max(areas)))
cat(sprintf("Área promedio    : %.5f km²  (%.1f m²)\n",  mean(areas_km2),   mean(areas)))
cat(sprintf("Área mediana     : %.5f km²  (%.1f m²)\n",  median(areas_km2), median(areas)))
cat(sprintf("Área total malla : %.2f km²\n", sum(areas_km2)))

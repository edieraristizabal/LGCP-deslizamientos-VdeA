library(sf); library(terra); library(fmesher)

BASE  <- "C:/Users/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP"
DATA  <- file.path(BASE, "DATA")

pts_wgs <- st_read(file.path(DATA,"MenM_VdeA_dem.gpkg"), quiet=TRUE)
pts     <- st_transform(pts_wgs, crs=9377)
if (attr(pts,"sf_column")!="geometry")
  pts <- st_sf(st_drop_geometry(pts), geometry=st_geometry(pts), crs=9377)

cov_elev  <- rast(file.path(DATA,"cov_elevacion.tif"))
cov_slope <- rast(file.path(DATA,"cov_pendiente.tif"))

# Recrear malla (igual que en el script principal)
dem_mask <- as.polygons(ifel(!is.na(cov_elev),1,NA)) |> st_as_sf() |> st_union() |> st_as_sf()
st_crs(dem_mask) <- 9377
domain <- st_convex_hull(st_union(pts)) |> st_buffer(500) |> st_as_sf()
st_crs(domain) <- 9377
domain_final <- st_sf(geometry=st_union(st_geometry(st_intersection(domain,dem_mask))), crs=9377)
bnd  <- fmesher::fm_as_segm(domain_final)
mesh <- fmesher::fm_mesh_2d(boundary=bnd, max.edge=c(1000,3000),
                             offset=c(1000,5000), cutoff=300, crs=sf::st_crs(9377))

# Coordenadas de los nodos
nodos <- as.data.frame(mesh$loc[, 1:2])
names(nodos) <- c("x", "y")
cat("Total nodos en la malla:", nrow(nodos), "\n")

# Extraer covariables en los nodos (igual que inlabru lo hace internamente)
elev_nodos  <- terra::extract(cov_elev,  as.matrix(nodos))[,1]
slope_nodos <- terra::extract(cov_slope, as.matrix(nodos))[,1]

cat("\n--- Elevación en los nodos ---\n")
print(summary(elev_nodos))
cat("NAs:", sum(is.na(elev_nodos)), "de", length(elev_nodos), "nodos\n")

cat("\n--- Pendiente en los nodos ---\n")
print(summary(slope_nodos))
cat("NAs:", sum(is.na(slope_nodos)), "de", length(slope_nodos), "nodos\n")

cat("\n--- Elevación en los puntos de deslizamiento ---\n")
elev_pts <- terra::extract(cov_elev, st_coordinates(pts))[,1]
print(summary(elev_pts))

cat("\n→ Ambos usan exactamente el mismo raster y el mismo método de extracción\n")
cat("→ Los nodos en el buffer exterior (fuera del DEM) tendrán NA →",
    sum(is.na(elev_nodos)), "nodos con NA\n")

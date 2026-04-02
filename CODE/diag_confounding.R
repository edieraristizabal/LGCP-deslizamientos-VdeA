library(sf); library(terra); library(INLA); library(inlabru); library(fmesher)

BASE <- "C:/Users/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP"
DATA <- file.path(BASE, "DATA")

pts_wgs <- st_read(file.path(DATA,"MenM_VdeA_dem.gpkg"), quiet=TRUE)
pts     <- st_transform(pts_wgs, crs=9377)
if (attr(pts,"sf_column")!="geometry")
  pts <- st_sf(st_drop_geometry(pts), geometry=st_geometry(pts), crs=9377)

cov_elev  <- rast(file.path(DATA,"cov_elevacion.tif"))
cov_slope <- rast(file.path(DATA,"cov_pendiente.tif"))
cov_logacc <- rast(file.path(DATA,"cov_log_area_acum.tif"))

# Escalar
sc <- function(r) { m <- global(r,"mean",na.rm=TRUE)[[1]]; s <- global(r,"sd",na.rm=TRUE)[[1]]; (r-m)/s }
cov_sc <- c(sc(cov_elev), sc(cov_slope), sc(cov_logacc))
names(cov_sc) <- c("elev_sc","slope_sc","logacc_sc")

# Extraer covariables en los puntos
coords <- st_coordinates(pts)
pts$elev_sc   <- terra::extract(cov_sc["elev_sc"],   coords)[,1]
pts$slope_sc  <- terra::extract(cov_sc["slope_sc"],  coords)[,1]
pts$logacc_sc <- terra::extract(cov_sc["logacc_sc"], coords)[,1]

# Dominio
cov_elev_r <- rast(file.path(DATA,"cov_elevacion.tif"))
dem_mask <- as.polygons(ifel(!is.na(cov_elev_r),1,NA)) |> st_as_sf() |> st_union() |> st_as_sf()
st_crs(dem_mask) <- 9377
domain <- st_convex_hull(st_union(pts)) |> st_buffer(500) |> st_as_sf()
st_crs(domain) <- 9377
domain_final <- st_sf(geometry=st_union(st_geometry(st_intersection(domain, dem_mask))), crs=9377)

# Malla
bnd  <- fmesher::fm_as_segm(domain_final)
mesh <- fmesher::fm_mesh_2d(boundary=bnd, max.edge=c(1000,3000),
                             offset=c(1000,5000), cutoff=300, crs=sf::st_crs(9377))
spde <- inla.spde2.pcmatern(mesh, alpha=2, prior.range=c(5000,0.01), prior.sigma=c(1.5,0.01))

# ── MODELO 1: solo covariables, sin campo espacial ──
cat("\n=== MODELO 1: covariables sin GRF ===\n")
comp1 <- ~ Intercept(1) +
  elev_sc(elev_sc,   model="linear") +
  slope_sc(slope_sc, model="linear") +
  logacc_sc(logacc_sc, model="linear")

fit1 <- lgcp(components=comp1, data=pts,
             formula=geometry ~ .,
             samplers=domain_final, domain=list(geometry=mesh),
             options=list(control.inla=list(int.strategy="eb", strategy="laplace"), verbose=FALSE))

cat("Efectos fijos (modelo sin GRF):\n")
print(round(fit1$summary.fixed[,c("mean","sd","0.025quant","0.975quant")], 4))

# ── MODELO 2: con GRF + covariables pero rango forzado más corto ──
cat("\n=== MODELO 2: GRF (prior rango más pequeño) + covariables ===\n")
spde2 <- inla.spde2.pcmatern(mesh, alpha=2,
  prior.range = c(2000, 0.5),   # P(rango < 2km) = 0.5 → rango más corto
  prior.sigma = c(2.0,  0.1))   # P(σ > 2) = 0.1 → varianza más controlada

comp2 <- ~ Intercept(1) +
  elev_sc(elev_sc,     model="linear") +
  slope_sc(slope_sc,   model="linear") +
  logacc_sc(logacc_sc, model="linear") +
  field(geometry, model=spde2)

fit2 <- lgcp(components=comp2, data=pts,
             formula=geometry ~ .,
             samplers=domain_final, domain=list(geometry=mesh),
             options=list(control.inla=list(int.strategy="eb", strategy="laplace"), verbose=FALSE))

cat("Efectos fijos (modelo con GRF, prior ajustado):\n")
print(round(fit2$summary.fixed[,c("mean","sd","0.025quant","0.975quant")], 4))
spde_r2 <- inla.spde2.result(fit2, "field", spde2)
r2  <- inla.zmarginal(spde_r2$marginals.range.nominal[[1]])
s2  <- inla.zmarginal(spde_r2$marginals.variance.nominal[[1]])
cat(sprintf("GRF: rango=%.1f km  σ²=%.3f\n", r2$mean/1000, s2$mean))

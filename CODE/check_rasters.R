library(terra)
BASE <- "C:/Users/edier/Documents/INVESTIGACION/PAPERS/ELABORACION/LGCP"
DATA <- file.path(BASE, "DATA")

files <- c(
  elevacion     = "cov_elevacion.tif",
  pendiente     = "cov_pendiente.tif",
  aspecto       = "cov_aspecto.tif",
  log_area_acum = "cov_log_area_acum.tif"
)

for (nm in names(files)) {
  r <- rast(file.path(DATA, files[nm]))
  cat(sprintf("%-15s  res: %.1f x %.1f m   ext: [%.0f, %.0f, %.0f, %.0f]   CRS: %s\n",
    nm, res(r)[1], res(r)[2],
    ext(r)[1], ext(r)[2], ext(r)[3], ext(r)[4],
    crs(r, describe=TRUE)$code))
}

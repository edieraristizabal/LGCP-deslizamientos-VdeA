options(repos = c(
  INLA = "https://inla.r-inla-download.org/R/stable",
  CRAN = "https://cloud.r-project.org"
))

# Instalar versiones binarias compatibles entre si
# fmesher 0.3.0 + INLA 23.09.09 + inlabru 2.12.0 son del mismo ciclo de release

cat("Instalando fmesher (binario)...\n")
install.packages("fmesher", type = "binary")
cat("fmesher version:", as.character(packageVersion("fmesher")), "\n")

cat("Instalando inlabru (binario)...\n")
install.packages("inlabru", type = "binary")
cat("inlabru version:", as.character(packageVersion("inlabru")), "\n")

cat("Instalando INLA (binario)...\n")
install.packages("INLA", type = "binary", dep = FALSE)
cat("INLA version:", as.character(packageVersion("INLA")), "\n")

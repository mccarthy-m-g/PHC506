# Project helpers for PHC506
if (interactive()) {

  # Preview the interactive (webR) book with live reload. Quarto validates that
  # chapters/ exists before running the pre-render, so generate it once up front,
  # then let `quarto preview`'s pre-render keep it refreshed.
  serve_webr <- function() {
    system2("Rscript", "scripts/build-webr.R")
    quarto::quarto_preview()
  }

}

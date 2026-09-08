#!/usr/bin/env Rscript
# Pre-render generator for the PHC 506 interactive book.
#
# The book is a single Quarto project rooted here. The RStudio-native lecture
# sources live in lectures/*.qmd (ordinary {r} chunks; breakout answer chunks
# labelled `brk-*`, see scripts/tag-breakouts.R). Quarto cannot transform
# {r} -> {webr} at render time (knitr runs before filters), so this script runs
# as the project's `pre-render` step and regenerates the rendered chapters in
# chapters/*.qmd from lectures/*.qmd:
#   * rewrites labelled `{r brk-*}` chunks into interactive `{webr}` cells
#     (worked examples stay static, pre-rendered knitr chunks);
#   * for chapters with interactive cells, includes the quarto-live knitr
#     passthrough and injects a hidden auto-running `{webr}` setup cell that
#     recreates -- inside webR -- exactly the packages and objects those
#     breakouts depend on (and nothing else). Data read from data/ is downloaded
#     into webR's filesystem, fetched same-origin via docBase.
#
# All other assets (data/, images/, _extensions/, setup/_common.R, example_project/) are
# referenced in place from the project root; nothing is copied. Chapters render
# from chapters/ (one level deep), so docBase points one level up to the site
# root where data/ is served.
#
# It also (re)builds phc506-materials.zip, the downloadable plain-source bundle.
#
# Quarto validates that chapter files exist *before* running pre-render, so
# chapters/ must exist for the first render -- run this once after cloning
# (serve_webr() in .Rprofile does this for you), after which `quarto render`
# and `quarto preview` keep it refreshed automatically.

out_dir <- "chapters"

# ---- small parsing helpers ------------------------------------------------
bracket_delta <- function(s) {
  ch <- strsplit(paste(s, collapse = "\n"), "")[[1]]
  sum(ch %in% c("(", "[", "{")) - sum(ch %in% c(")", "]", "}"))
}
identifiers <- function(code) {
  unique(unlist(regmatches(code, gregexpr("[A-Za-z.][A-Za-z0-9._]*", code))))
}
continues <- function(line) grepl("(\\|>|%>%|\\+|,)\\s*$", line)

# Split a .qmd into fenced chunks: list(lang, is_brk, code).
parse_chunks <- function(lines) {
  chunks <- list(); i <- 1; N <- length(lines)
  while (i <= N) {
    if (grepl("^```\\{", lines[i])) {
      j <- i + 1; code <- character(0)
      while (j <= N && !grepl("^```\\s*$", lines[j])) { code <- c(code, lines[j]); j <- j + 1 }
      chunks[[length(chunks) + 1]] <- list(
        lang = sub("^```\\{([A-Za-z]+).*", "\\1", lines[i]),
        is_brk = grepl("brk-", lines[i]),
        code = code)
      i <- j + 1
    } else i <- i + 1
  }
  chunks
}

# Top-level assignments in a block of R code, as list(var, stmt-lines),
# accumulating continuation lines (unbalanced brackets or trailing operators).
assignments <- function(code) {
  res <- list(); i <- 1; N <- length(code)
  while (i <= N) {
    m <- regmatches(code[i],
                    regexec("^\\s*([A-Za-z.][A-Za-z0-9._]*)\\s*(<-|=)([^=]|$)", code[i]))[[1]]
    if (length(m) >= 3 && m[3] %in% c("<-", "=", " ", "")) {
      var <- m[2]; stmt <- code[i]; j <- i
      while ((bracket_delta(paste(stmt, collapse = "\n")) > 0 ||
              continues(stmt[length(stmt)])) && j < N) {
        j <- j + 1; stmt <- c(stmt, code[j])
      }
      res[[length(res) + 1]] <- list(var = var, stmt = stmt); i <- j + 1
    } else i <- i + 1
  }
  res
}

# Local data/ filenames referenced in a statement (URLs excluded).
local_data_files <- function(stmt) {
  s <- paste(stmt, collapse = "\n")
  toks <- gsub('["\']', "",
               unlist(regmatches(s, gregexpr('["\'][^"\']*\\.(csv|tsv|xlsx)["\']', s))))
  basename(toks[!grepl("^https?://", toks)])
}

# ---- build a dependency-scoped webR setup cell for a chapter --------------
make_setup <- function(lines) {
  # Assign each line to a `## ` section (0 = preamble, before the first heading)
  # and mark fenced-code lines. Interactive sections are those that contain a brk
  # chunk -- for lectures that's the ## Breakout sections; for the practice
  # worksheet it's the ## dplyr / ## ggplot / ## Programming sections.
  in_fence <- FALSE; cur <- 0L
  sec_id <- integer(length(lines)); code <- logical(length(lines))
  for (i in seq_along(lines)) {
    is_fence <- grepl("^```", lines[i])
    if (!in_fence && !is_fence && grepl("^## ", lines[i])) cur <- cur + 1L
    sec_id[i] <- cur; code[i] <- in_fence || is_fence
    if (is_fence) in_fence <- !in_fence
  }
  brk_secs <- setdiff(unique(sec_id[grepl("^```\\{r .*brk-", lines)]), 0L)
  if (!length(brk_secs)) return(character(0))
  sec <- sec_id %in% brk_secs
  first_sec <- min(which(sec))

  breakout_code <- lines[sec & code]
  prose <- lines[sec & !code]
  # `foo` mentions in the interactive prose name objects the exercise expects.
  backticks <- gsub("`", "",
                    unlist(regmatches(prose, gregexpr("`[A-Za-z.][A-Za-z0-9._]*`", prose))))

  # Preamble = everything before the first interactive section.
  preamble_r <- unlist(lapply(parse_chunks(lines[seq_len(first_sec - 1)]),
                              function(c) if (c$lang == "r") c$code))

  # `library(help = "pkg")` just prints a package's help index; it isn't a real
  # load, so keep it out of the webR setup cell.
  libs <- unique(trimws(preamble_r[
    grepl("^\\s*library\\(", preamble_r) & !grepl("^\\s*library\\(\\s*help\\s*=", preamble_r)]))
  assigns <- assignments(preamble_r)

  # Packages referenced via `pkg::` in the interactive cells must be loaded so
  # webR installs them into the session (namespace access alone won't trigger an
  # install), e.g. Breakout 1 in Lecture 1e runs `praise::praise()`. Base
  # packages are always present, so skip those.
  base_pkgs <- c("base", "stats", "utils", "datasets", "graphics", "grDevices",
                 "methods", "tools", "grid", "splines", "parallel", "compiler")
  ns_pkgs <- setdiff(unique(unlist(regmatches(breakout_code,
    gregexpr("[A-Za-z][A-Za-z0-9.]*(?=::)", breakout_code, perl = TRUE)))), base_pkgs)
  libs <- unique(c(libs, if (length(ns_pkgs)) sprintf("library(%s)", ns_pkgs)))

  # Lecture breakouts (## Breakout ...) mostly use built-in data, so replay only
  # the preamble objects they actually reference. A fill-in worksheet has empty
  # cells that WILL use the loaded data, so replay the whole preamble.
  if (any(grepl("^## Breakout", lines[sec & !code]))) {
    need <- union(identifiers(breakout_code), backticks)
    repeat {
      before <- length(need)
      for (a in assigns) if (a$var %in% need) need <- union(need, identifiers(a$stmt))
      if (length(need) == before) break
    }
    included <- Filter(function(a) a$var %in% need, assigns)
  } else {
    included <- assigns
  }

  if (length(libs) == 0 && length(included) == 0) return(character(0))

  data_files <- unique(unlist(lapply(included, function(a) local_data_files(a$stmt))))
  stmts <- unlist(lapply(included, function(a) a$stmt))

  downloads <- if (length(data_files)) c(
    'dir.create("data", showWarnings = FALSE)',
    # webR runs in a Web Worker (base URL = the CDN), so fetch from the page's
    # absolute origin (docBase, supplied by the ojs cell below).
    sprintf('download.file(paste0(docBase, "data/%s"), "data/%s")',
            data_files, data_files)
  ) else character(0)

  input <- if (length(data_files)) "#| input: [\"docBase\"]" else character(0)
  # Chapters render one level deep (chapters/), so the site root -- where data/
  # is served -- is one level up from the page.
  ojs <- if (length(data_files)) c(
    "```{ojs}", "//| echo: false",
    'docBase = new URL("..", window.location.href).href', "```", ""
  ) else character(0)

  c(ojs,
    "```{webr}", "#| autorun: true", "#| include: false", input,
    libs, downloads, stmts, "```", "")
}

# ---- transform each lecture into a rendered chapter -----------------------
convert <- function(path) {
  original <- readLines(path)
  is_brk <- grepl("^```\\{r .*brk-", original)
  lines <- original
  lines[is_brk] <- "```{webr}"

  if (any(is_brk)) {
    yaml_ends <- grep("^---\\s*$", lines)[2]
    # Include is relative to the chapter file, one level deep in chapters/.
    include <- "{{< include ../_extensions/r-wasm/live/_knitr.qmd >}}"
    inject <- c("", include, "", make_setup(original))
    lines <- append(lines, inject, after = yaml_ends)
  }

  # Write only when the content actually changed. This pre-render runs on every
  # `quarto preview` refresh, and chapters/ are watched inputs -- rewriting them
  # (even identically) would bump their mtime and trigger an endless reload loop.
  target <- file.path(out_dir, basename(path))
  if (!file.exists(target) || !identical(readLines(target, warn = FALSE), lines)) {
    writeLines(lines, target)
    message("wrote ", target, " (", sum(is_brk), " interactive cells)")
  }
}

# Sources transformed into interactive chapters: the lectures, plus the
# practice-problems worksheet (its empty chunks become `{webr}` editors too).
transform_sources <- c(list.files("lectures", "\\.qmd$", full.names = TRUE),
                       "practice_problems/Practice_problems.qmd")
dir.create(out_dir, showWarnings = FALSE)
# Drop any generated chapters whose source no longer exists.
wanted <- basename(transform_sources)
for (f in setdiff(list.files(out_dir, "\\.qmd$"), wanted)) unlink(file.path(out_dir, f))
invisible(lapply(transform_sources, convert))

# ---- downloadable "work locally" bundle of plain source -------------------
# A zip of the plain {r} lecture and solution sources (the RStudio-native
# versions) plus the project file and data, for students who prefer to work
# locally. The book-only `source("setup/_common.R")` line is swapped for a knitr
# root.dir fix (see the staging loop) so the files stand alone. Edit `bundle`
# (verbatim-copied) or `qmd_dirs` to change what's included.
bundle <- c("PHC506.Rproj", "README.md", "data", "images", "example_project")
qmd_dirs <- c("lectures", "solutions", "practice_problems")
zipfile <- file.path(getwd(), "phc506-materials.zip")

# Rebuild only when a bundled source is newer than the zip -- otherwise this
# pre-render would rewrite the (watched) resource on every preview refresh.
srcs <- c(bundle[!dir.exists(bundle) & file.exists(bundle)],
          list.files(bundle[dir.exists(bundle)], recursive = TRUE, full.names = TRUE),
          list.files(qmd_dirs, "\\.qmd$", full.names = TRUE))
if (!file.exists(zipfile) || max(file.mtime(srcs)) > file.mtime(zipfile)) {
  stage <- file.path(tempdir(), "phc506-materials")
  unlink(stage, recursive = TRUE); dir.create(stage)
  invisible(file.copy(bundle, stage, recursive = TRUE))
  for (sub in qmd_dirs) {
    dir.create(file.path(stage, sub))
    for (f in list.files(sub, "\\.qmd$", full.names = TRUE)) {
      ls <- readLines(f)
      # The book renders with `execute-dir: project`, but a lecture opened on its
      # own in RStudio evaluates from the document's folder, so paths like
      # `file.path("data", ...)` fail. Swap the book-only _common.R source (which
      # this standalone bundle doesn't ship) for a knitr root.dir pointing at the
      # project root, so file paths resolve the same as they do in the book.
      ls[grepl('^\\s*source\\("setup/_common\\.R"\\)\\s*$', ls)] <-
        "knitr::opts_knit$set(root.dir = rprojroot::find_rstudio_root_file())"
      writeLines(ls, file.path(stage, sub, basename(f)))
    }
  }
  unlink(zipfile)
  root <- setwd(stage)
  utils::zip(zipfile, list.files(".", recursive = FALSE), flags = "-rq")
  setwd(root)
  unlink(stage, recursive = TRUE)
  message("rebuilt phc506-materials.zip")
}

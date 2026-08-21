#!/usr/bin/env Rscript
# Tag the answer chunks inside "# Breakout" sections so the webR build can turn
# them into interactive cells. A chunk is tagged only if it is a bare `{r}` /
# `{r }` chunk that sits under a top-level `# Breakout...` heading, up to the
# next top-level `# ` heading.
#
# The script first strips any existing `{r brk-N}` labels and then re-applies
# them, so it is idempotent and self-correcting. Heading detection ignores
# lines inside fenced code blocks, so R comments like `# Hint:` are not mistaken
# for section headings.
#
# Usage: Rscript scripts/tag-breakouts.R

files <- list.files("lectures", pattern = "\\.qmd$", full.names = TRUE)

for (f in files) {
  lines <- readLines(f)

  # 1. Reset: turn any previously tagged breakout chunk back into a bare {r}.
  lines <- sub("^```\\{r brk-[0-9]+\\}\\s*$", "```{r}", lines)

  # 2. Re-tag, tracking fenced-code state so comments aren't read as headings.
  in_fence <- FALSE
  in_breakout <- FALSE
  n <- 0L
  changed <- FALSE
  for (i in seq_along(lines)) {
    line <- lines[i]
    is_fence <- grepl("^```", line)

    if (!in_fence && !is_fence && grepl("^## ", line)) {
      in_breakout <- grepl("^## Breakout", line)
    }

    if (!in_fence && in_breakout && grepl("^```\\{r\\s*\\}$", line)) {
      n <- n + 1L
      lines[i] <- sprintf("```{r brk-%d}", n)
      changed <- TRUE
    }

    if (is_fence) in_fence <- !in_fence
  }

  if (changed) {
    writeLines(lines, f)
    message(basename(f), ": tagged ", n, " breakout cell(s)")
  }
}

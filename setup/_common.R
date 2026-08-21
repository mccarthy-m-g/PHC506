# Shared knitr / display settings for all lecture chapters.

knitr::opts_chunk$set(
  comment = "#>",      # prefix printed output with #>
  collapse = TRUE,     # merge code and its output into a single block
  fig.retina = 2,
  fig.width = 6,
  fig.asp = 2 / 3,
  fig.show = "hold"
)

options(
  # Render `?help` as text in the output instead of launching a browser at R's
  # help server (which otherwise pops up "Safari can't connect" during render).
  help_type = "text",
  # Belt and braces: during rendering, never launch a web browser at all --
  # e.g. vignette() and browseURL() otherwise pop open (a failing) browser tab.
  browser = function(url, ...) invisible(NULL),
  # Cap printed data frames (base data.frame via df-print: tibble, and tibbles)
  # at 10 rows, then "# i N more rows".
  dplyr.print_min = 10,
  dplyr.print_max = 10,
  pillar.max_footer_lines = 2,
  pillar.min_chars = 15,
  stringr.view_n = 6,
  # Deactivate cli's ANSI colors / hyperlinks so console output renders cleanly.
  cli.num_colors = 0,
  cli.hyperlink = FALSE,
  pillar.bold = TRUE,
  width = 77
)

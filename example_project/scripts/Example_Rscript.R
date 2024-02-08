# This is an example R script

# Here I load the libraries/packages I need:
library(ggplot2)
library(dplyr)
library(cols4all)

# Here I read my data set:
Theoph <- read.csv(file.path("example_project", "data", "theophylline.csv"))

# Now I am going to make a graph about some Iris petal data
p_Theoph <- Theoph %>%
  ggplot() +
  aes(x = Time, y = conc, color = factor(Subject)) +
  geom_line() +
  theme_minimal() +
  xlab("Time (hr)") +
  ylab("Conc (mg/L)") +
  scale_color_manual(values = cols4all::c4a("kelly")[-1]) +
  facet_wrap(~paste0("Subject ", Subject)) +
  theme(legend.position = "none")

# Here I will save my graph
ggsave(
  plot = p_Theoph,
  file.path("example_project", "figures", "theophylline_R.pdf"),
  width = 4,
  height = 3
)

# Here I will summarize my data and then save it as a CSV
summarized_data <- Theoph %>%
  group_by(Subject) %>%
  filter(conc > 0) %>%
  summarize(
    peak = max(conc),
    trough = min(conc)
  )
write.csv(
  summarized_data,
  file.path("example_project", "data", "summarized_ct_metrics.csv"),
  row.names = FALSE
)



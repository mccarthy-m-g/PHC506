# -- Operations, data types, working environment -------------------------------

# Math
7 * 7        # multiply
7/7          # divide
7 + 1        # add
7 - 1        # subtract
7 ** 2       # powers
7 ^ 2        # powers
log(2)       # logarithm
exp(2)       # e^x

# Logical expressions
7 > 6        # greater than
7 >= 6       # greater than or equal to
7 < 8        # less than
7 <= 8       # less than or equal to
7 == 8       # equal to (not the same as `=`)
7 != 8       # not equal to
TRUE | FALSE # or
TRUE & FALSE # and

# vectors, lists and dataframes
c(6, 8)       # create a vector (numeric, integer, character, logical)
list(a = 1)   # create a list
data.frame()  # create a data frame
seq(0, 12, 0) # create a vector sequence from, to, increment by

# understanding data types, converting between data types
class(x)            # returns object type/class
as.numeric(x)       # coerce to numeric
as.character(x)     # coerce to character
is.numeric(x)       # is it numeric? (TRUE/FALSE)
is.character(x)     # is it character? (TRUE/FALSE)
length(x)           # length of vector or list

# Indexing into a vector
letters[1]       # first element
letters[-1]      # everything but the first element
letters[c(1,5)]  # first and fifth element

# pipe from one function to another
|>                             # e.g.: x |> mean()

# working with missing data
is.na()                        # is value NA
is.null()                      # is value NULL

# working with factors
factor(x, levels = y)          # convert vector x to a factor with levels y
levels(x)                      # get the levels of a factor x

# working with dates
as.Date(char, format = "%m-%d-%Y")    # convert a character vector to a date
as.POSIXct(char, format = "%m-%d-%Y") # convert a character vector to a datetime
difftime(t1, t2, units = "mins")      # calculate time between two variables

# statistical summary functions (input: vector, output: vector of length 1)
# (control handling of missing values using na.rm = TRUE/FALSE)
median(1:10)    # median
mean(1:10)      # mean
sd(1:10)        # standard deviation
min(1:10)       # minimum
max(1:10)       # maximum
sum(1:10)       # sum total

# Managing your environment
install.packages("praise")          # install a package
library(praise)                     # load a package
hello::world()                # refer to an object `hello` from package `world`
getwd()                             # get working directory
setwd()                             # change working directory

# Data input and output
file.path("path", "to", "file.csv")     # create a file path
read.csv(file.path(...))                # read a CSV file
write.csv(data.frame(), file.path(...)) # write a CSV file

# -- Data frames and dplyr  ----------------------------------------------------

# information about a data frame
nrow(df)         # number of rows
ncol(df)         # number of columns
dim(df)          # dimensions (number of rows and columns)
summary(df)      # summary statistics across each column
View(df)         # look at a whole data frame

# core dplyr functions (load package with `library(dplyr)`)
%>%                            # dplyr version of `|>`
select(df, cols)               # select certain columns
filter(df, logical_expr)       # filter for rows where logical_expr is TRUE
arrange(df, cols)              # sort a data frame on cols (ascending)
arrange(df, desc(cols))        # sort a data frame on cols (descending)
group_by(df, cols)             # create a grouped data frame, by cols
ungroup(df)                    # remove groupings from a data frame
summarize(df, x = f(..))       # calculate a summary statistic (1 row per group)
mutate(df, x = f(...))         # calculate a statistic across group or add a
                               # column, (returns same number of rows)

# -- Data visualization  -------------------------------------------------------

# -- Plotting in Base R
plot()                # create a plot, type dependent on object/arguments
boxplot()             # create a boxplot
hist()                # create a histogram
barplot()             # create a barplot
pdf()                 # change graphics device to a pdf file
png()                 # change graphics device to a pdf
dev.off()             # finish adding to the graphics device

# -- Plotting in ggplot2
ggplot()              # main call to ggplot, control mapping with `aes`
aes(x = ..., y = ..., fill = ..., linetype = ..., color = ..., shape = ...)
facet_wrap(~colname)  # plot multiple panels depending on colname categories
ggsave()              # save graph

# Types of plots
geom_point()                      # x-y scatter plot, trends in continuous data
geom_line()                       # line plot, trends over time, etc
geom_boxplot()                    # great for statistical distributions
geom_histogram()                  # data distributions (no y variable needed)
geom_bar(stat = "identity")       # bar plot (categorical x, numeric y)
geom_smooth(method = "lm")        # plot a linear model through data points

# Customizing your plot
labs(x = ..., y = ..., title = ...)  # add axis label, graph title, etc
scale_y_log10()                      # log10 scaling, y axis
scale_x_log10()                      # log10 scaling, x axis
scale_fill_manual()                  # customize colors of rectangles/bars
scale_color_manual()                 # customize colors of points and lines
scale_shape_manual()                 # customize point shapes
scale_line_manual()                  # customize line types

# -- Programming in R ----------------------------------------------------------
print()                              # print a message to user

# Function syntax
function_name <- function(mandatory_arg, optional_arg = NULL) {
  # code
  return()
}

# if/else
if (condition1) {
  # code
} else if (condition2) {
  # code
} else {
  # code
}

# vectorized if/else:
ifelse(condition1, if_true, if_false)

# for-loop syntax
for (i in 1:10) {
  # code
}

#' Add missing values to a vector given a MCAR, MAR, or MNAR scheme
#'
#' Given an input vector replace elements of this vector with missing values according to some scheme.
#' Default method replaces input values with a MCAR scheme at a rate of 10%. MAR and MNAR are supported by
#' replacing the default \code{FUN} argument.
#'
#' \describe{
#'   Given an input vector y that initially contains no missing values, and other relavent variables
#'   inside (X) and outside (Z) the dataset, the three types of missingness are:
#'
#'   \item{MCAR}{Missing completely at random (MCAR) is realized by randomly sampling the values of the
#'     input vector (y). Therefore missing values are randomly sampled and do not depend on any data
#'     characteristics}
#'   \item{MAR}{Missing at random (MAR) is realized when values in the dataset (X) predict the missing data
#'     mechanism in y; conceptually this is equivalent to P(y = NA | X). This requires
#'     the user to define a missing data function}
#'   \item{MNAR}{Missing not at random (MNAR) is similar to MAR, except that the missing mechanism comes
#'     from the value of y itself or from variables outside the working dataset;
#'     conceptually this is equivalent to P(y = NA | X, Z, y). This requires
#'     the user to define a missing data function}
#' }
#'
#' @param y an input vector that should contain missing data (NA's)
#'
#' @param fun a user defined function indicating the missing data mechanism for each element in y. Function
#'   must return a vector of probability values with the length equal to the length of y.
#'   Each value in the returned vector indicates the probability that
#'   the respective element in y will be replaced with NA.
#'   Function must contain the argument \code{y} representing the
#'   input vector, however any number of additional arguments can be included
#'
#' @param ... additional arguments to be passed to FUN
#'
#' @return the input vector y with sampled NA (according to the \code{FUN} scheme)
#'
#' @aliases add_missing
#'
#' @export add_missing
#'
#' @examples
#'
#' set.seed(1)
#' y <- rnorm(1000)
#'
#' ## 10% missing rate with default FUN
#' head(ymiss <- add_missing(y), 10)
#'
#' ## 50% missing with default FUN
#' head(ymiss <- add_missing(y, rate = .5), 10)
#'
#' ## missing values only when female and low
#' X <- data.frame(group = sample(c('male', 'female'), 1000, replace=TRUE),
#'                 level = sample(c('high', 'low'), 1000, replace=TRUE))
#' head(X)
#'
#' fun <- function(y, X, ...){
#'     p <- rep(0, length(y))
#'     p[X$group == 'female' & X$level == 'low'] <- .2
#'     p
#' }
#'
#' ymiss <- add_missing(y, X, fun=fun)
#' tail(cbind(ymiss, X), 10)
#'
#' ## missingness as a function of elements in X (i.e., a type of MAR)
#' fun <- function(y, X){
#'    # missingness with a logistic regression approach
#'    df <- data.frame(y, X)
#'    mm <- model.matrix(y ~ group + level, df)
#'    cfs <- c(-5, 2, 3) #intercept, group, and level coefs
#'    z <- cfs %*% t(mm)
#'    plogis(z)
#' }
#'
#' ymiss <- add_missing(y, X, fun=fun)
#' tail(cbind(ymiss, X), 10)
#'
#' ## missing values when y elements are large (i.e., a type of MNAR)
#' fun <- function(y) ifelse(abs(y) > 1, .4, 0)
#' ymiss <- add_missing(y, fun=fun)
#' tail(cbind(y, ymiss), 10)
#'
add_missing <- function(y, fun = function(y, rate = .1, ...) rep(rate, length(y)), ...){
    if(!('y' %in% names(formals(fun))))
        stop('fun must include a y argument')
    probs <- fun(y=y, ...)
    stopifnot(length(probs) == length(y))
    stopifnot(all(probs >= 0 & probs <= 1))
    is_na <- sapply(probs, function(p) sample(c(FALSE, TRUE), 1L, prob = c(1-p, p)))
    y[is_na] <- NA
    y
}
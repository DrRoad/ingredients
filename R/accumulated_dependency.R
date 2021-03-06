#' Accumulated Local Effects Profiles aka ALEPlots
#'
#' Accumulated Local Effects Profiles accumulate local changes in Ceteris Paribus Profiles.
#' Function 'accumulated_dependency' calls 'ceteris_paribus' and then 'aggregate_profiles'.
#'
#' Find more detailes in the \href{https://pbiecek.github.io/PM_VEE/accumulatedLocalProfiles.html}{Accumulated Local Dependency Chapter}.
#'
#' @param x a model to be explained, or an explainer created with function `DALEX::explain()` or  object of the class `ceteris_paribus_explainer`.
#' @param data validation dataset Will be extracted from `x` if it's an explainer
#' @param predict_function predict function Will be extracted from `x` if it's an explainer
#' @param variables names of variables for which profiles shall be calculated. Will be passed to `calculate_variable_splits()`. If NULL then all variables from the validation data will be used.
#' @param N number of observations used for calculation of partial dependency profiles. By default, 500 observations will be chosen randomly.
#' @param ... other parameters
#' @param variable_splits named list of splits for variables, in most cases created with `calculate_variable_splits()`. If NULL then it will be calculated based on validation data avaliable in the `explainer`.
#' @param grid_points number of points for profile. Will be passed to `calculate_variable_splits()`.
#' @param label name of the model. By default it's extracted from the 'class' attribute of the model
#'
#' @references ALEPlot: Accumulated Local Effects (ALE) Plots and Partial Dependence (PD) Plots \url{https://cran.r-project.org/package=ALEPlot},
#' Predictive Models: Visual Exploration, Explanation and Debugging \url{https://pbiecek.github.io/PM_VEE}
#'
#' @return an 'aggregated_profiles_explainer' geom
#' @examples
#' library("DALEX")
#' # Toy examples, because CRAN angels ask for them
#' titanic <- na.omit(titanic)
#' model_titanic_glm <- glm(survived == "yes" ~ gender + age + fare,
#'                        data = titanic, family = "binomial")
#'
#' explain_titanic_glm <- explain(model_titanic_glm,
#'                            data = titanic[,-9],
#'                            y = titanic$survived == "yes")
#' pdp_glm <- accumulated_dependency(explain_titanic_glm, N = 50, variables = c("age", "fare"))
#' head(pdp_glm)
#' plot(pdp_glm)
#'
#'  \donttest{
#' library("randomForest")
#'  model_titanic_rf <- randomForest(survived ~ gender + age + class + embarked +
#'                                     fare + sibsp + parch,  data = titanic)
#'  model_titanic_rf
#'
#'  explain_titanic_rf <- explain(model_titanic_rf,
#'                            data = titanic[,-9],
#'                            y = titanic$survived)
#'
#' pdp_rf <- accumulated_dependency(explain_titanic_rf)
#' plot(pdp_rf)
#' }
#' @export
#' @rdname accumulated_dependency
accumulated_dependency <- function(x, ...)
  UseMethod("accumulated_dependency")

#' @export
#' @rdname accumulated_dependency
accumulated_dependency.explainer <- function(x, variables = NULL, N = 500,
                                         variable_splits = NULL, grid_points = 101,
                                         ...) {
  # extracts model, data and predict function from the explainer
  model <- x$model
  data <- x$data
  predict_function <- x$predict_function
  label <- x$label

  accumulated_dependency.default(model, data, predict_function,
                             label = label,
                             variables = variables,
                             grid_points = grid_points,
                             variable_splits = variable_splits,
                             N = N,
                             ...)
}


#' @export
#' @rdname accumulated_dependency
accumulated_dependency.default <- function(x, data, predict_function = predict,
                                       label = class(x)[1],
                                       variables = NULL,
                                       grid_points = grid_points,
                                       variable_splits = variable_splits,
                                       N = 500,
                                       ...) {
  if (N < nrow(data)) {
    # sample N points
    ndata <- data[sample(1:nrow(data), N),]
  } else {
    ndata <- data
  }

  cp <- ceteris_paribus.default(x, data, predict_function = predict_function,
                                ndata, variables = variables,
                                grid_points = grid_points,
                                variable_splits = variable_splits,
                                label = label, ...)

  accumulated_dependency.ceteris_paribus_explainer(cp, variables = variables)
}



#' @export
#' @rdname accumulated_dependency
accumulated_dependency.ceteris_paribus_explainer <- function(x, ...,
                                                         variables = NULL) {

  aggregate_profiles(x, ..., type = "accumulated", variables = variables)
}


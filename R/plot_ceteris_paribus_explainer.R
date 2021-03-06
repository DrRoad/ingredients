#' Plots Ceteris Paribus Profiles
#'
#' Function 'plot.ceteris_paribus_explainer' plots Individual Variable Profiles for selected observations.
#' Various parameters help to decide what should be plotted, profiles, aggregated profiles, points or rugs.
#'
#' Find more detailes in \href{https://pbiecek.github.io/PM_VEE/ceterisParibus.html}{Ceteris Paribus Chapter}.
#'
#' @param x a ceteris paribus explainer produced with function `ceteris_paribus()`
#' @param ... other explainers that shall be plotted together
#' @param color a character. Either name of a color or name of a variable that should be used for coloring
#' @param size a numeric. Size of lines to be plotted
#' @param alpha a numeric between 0 and 1. Opacity of lines
#' @param facet_ncol number of columns for the `facet_wrap()`
#' @param variables if not NULL then only `variables` will be presented
#' @param only_numerical a logical. If TRUE then only numerical variables will be plotted. If FALSE then only selected variables will be plotted as bars.
#'
#' @return a ggplot2 object
#' @export
#' @import ggplot2
#' @importFrom stats aggregate
#' @importFrom scales trans_new
#'
#' @references Predictive Models: Visual Exploration, Explanation and Debugging \url{https://pbiecek.github.io/PM_VEE}
#'
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
#' cp_rf <- ceteris_paribus(explain_titanic_glm, titanic[1,])
#' cp_rf
#' plot(cp_rf, variables = "age")
#'
#'  \donttest{
#'  library("randomForest")
#'  model_titanic_rf <- randomForest(survived == "yes" ~ gender + age + class + embarked +
#'                                     fare + sibsp + parch,  data = titanic)
#'  model_titanic_rf
#'
#'  explain_titanic_rf <- explain(model_titanic_rf,
#'                            data = titanic[,-9],
#'                            y = titanic$survived == "yes",
#'                            label = "Random Forest v7")
#'
#' selected_passangers <- select_sample(titanic, n = 100)
#' cp_rf <- ceteris_paribus(explain_titanic_rf, selected_passangers)
#' cp_rf
#'
#' plot(cp_rf, variables = "age") +
#'   show_observations(cp_rf, variables = "age") +
#'   show_rugs(cp_rf, variables = "age", color = "red")
#'
#' selected_passangers <- select_sample(titanic, n = 1)
#' selected_passangers
#' cp_rf <- ceteris_paribus(explain_titanic_rf, selected_passangers)
#'
#' plot(cp_rf) +
#'   show_observations(cp_rf)
#'
#' plot(cp_rf, variables = "age") +
#'   show_observations(cp_rf, variables = "age")
#'
#' plot(cp_rf, variables = "class")
#' plot(cp_rf, variables = c("class", "embarked"), facet_ncol = 1)
#' plot(cp_rf, variables = c("class", "embarked", "gender", "sibsp"), only_numerical = FALSE)
#'
#' }
#' @export
plot.ceteris_paribus_explainer <- function(x, ...,
   size = 1,
   alpha = 1,
   color = "#46bac2",
   only_numerical = TRUE,
   facet_ncol = NULL, variables = NULL) {

  # if there is more explainers, they should be merged into a single data frame
  dfl <- c(list(x), list(...))
  all_profiles <- do.call(rbind, dfl)
  class(all_profiles) <- "data.frame"

  all_profiles$`_ids_` <- factor(all_profiles$`_ids_`)

  # variables to use
  all_variables <- na.omit(as.character(unique(all_profiles$`_vname_`)))
  if (!is.null(variables)) {
    all_variables <- intersect(all_variables, variables)
    if (length(all_variables) == 0) stop(paste0("variables do not overlap with ", paste(all_variables, collapse = ", ")))
  }
  # is color a variable or literal?
  is_color_a_variable <- color %in% c(all_variables, "_label_", "_vname_", "_ids_")
  # only numerical or only factors?
  is_numeric <- sapply(all_profiles[, all_variables, drop = FALSE], is.numeric)
  if (only_numerical) {
    vnames <- names(which(is_numeric))
    all_profiles$`_x_` <- 0

    if (length(vnames) == 0) {
      # but `variables`` are selected, then change to factor
      if (length(variables) > 0) {
        only_numerical <- FALSE
        vnames <- variables
        all_profiles$`_x_` <- ""
      } else {
        stop("There are no numerical variables")
      }
    }

  } else {
    vnames <- names(which(!is_numeric))
    # there are no numerical features
    if (length(vnames) == 0) stop("There are no non-numerical variables")

    all_profiles$`_x_` <- ""
  }

  # how to plot profiles
  if (only_numerical) {
    # select only suitable variables  either in vnames or in variables
    all_profiles <- all_profiles[all_profiles$`_vname_` %in% vnames, ]
    pl <- plot_numerical_ceteris_paribus(all_profiles, is_color_a_variable, color, size, alpha, facet_ncol = facet_ncol)
  } else {
    # select only suitable variables  either in vnames or in variables
    all_profiles <- all_profiles[all_profiles$`_vname_` %in% c(vnames, variables), ]
    if (is.null(variables)) {
      variables <- vnames
    }
    pl <- plot_categorical_ceteris_paribus(all_profiles, head(attr(x, "observation"), 1), variables, facet_ncol = facet_ncol)
  }
  pl
}


plot_numerical_ceteris_paribus <- function(all_profiles, is_color_a_variable, color, size, alpha, facet_ncol) {
  # create _x_
  tmp <- as.character(all_profiles$`_vname_`)
  for (i in seq_along(tmp)) {
    all_profiles$`_x_`[i] <- all_profiles[i, tmp[i]]
  }

  # prepare plot
  `_x_` <- `_yhat_` <- `_ids_` <- `_label_` <- NULL
  pl <- ggplot(all_profiles, aes(`_x_`, `_yhat_`, group = paste(`_ids_`, `_label_`))) +
    facet_wrap(~ `_vname_`, scales = "free_x", ncol = facet_ncol)

  # show profiles without aggregation
  if (is_color_a_variable) {
    pl <- pl + geom_line(data = all_profiles, aes_string(color = paste0("`",color,"`")), size = size, alpha = alpha)
  } else {
    pl <- pl + geom_line(data = all_profiles, size = size, alpha = alpha, color = color)
  }

  pl <- pl  + xlab("") + ylab("prediction") +
    theme_drwhy()

  pl
}


plot_categorical_ceteris_paribus <- function(all_profiles, selected_observation, variables, facet_ncol) {

  lapply(variables, function(sv) {
    tmp <- all_profiles[all_profiles$`_vname_` == sv, c(sv, "_vname_", "_yhat_", "_label_")]
    tmp$`_vname_` <- paste(tmp$`_vname_`, "=", selected_observation[1, sv])
    colnames(tmp)[1] = "variable"
    tmp$variable <- as.character(tmp$variable)
    tmp
  }) -> lsc
  # transformed data frame
  selected_cp_flat <- do.call(rbind, lsc)

  selected_y <- selected_observation$`_yhat_`
  t_shift <- trans_new("shift",
                               transform = function(x) {x - selected_y},
                               inverse = function(x) {x + selected_y})

  # prepare plot
  `_vname_` <- NULL
  pl <- ggplot(selected_cp_flat, aes_string("variable", "`_yhat_`")) +
    geom_col(fill = "#46bac2") + facet_wrap(~`_vname_`, scales = "free_y", ncol = facet_ncol)+
    scale_y_continuous(trans = t_shift)

  pl +
    coord_flip() +
    theme_drwhy_vertical() +
    geom_hline(yintercept=selected_y, size = 0.5, linetype = 2, color = "#371ea3") +
    xlab("") + ylab("prediction")
}

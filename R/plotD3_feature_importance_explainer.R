#' Plot Feature Importance Objects in D3 with r2d3 Package.
#'
#' Function \code{plotD3.feature_importance_explainer} plots dropouts for variables used in the model.
#' It uses output from \code{feature_importance} function that corresponds to permutation based measure of feature importance.
#' Variables are sorted in the same order in all panels. The order depends on the average drop out loss. In different panels variable contributions may not look like sorted if variable importance is different in different models.
#'
#' @param x a feature importance explainer produced with the 'feature_importance' function
#' @param ... other explainers that shall be plotted together
#' @param max_vars maximum number of variables that shall be presented for for each model. By default NULL what means all variables
#' @param bar_width width of bars in px. By default 12px
#' @param split either \code{"model"} or \code{"feature"} determines the plot layout
#' @param scale_height should the height of plot scale with window size? By default it's FALSE
#' @param margin extend x axis domain range to adjust the plot. Usually value between 0.1 and 0.3, by default it's 0.15
#'
#' @return an `r2d3` object.
#'
#' @examples
#' \dontrun{
#' library("DALEX")
#' library("ingredients")
#' library("caret")
#'
#' rf_model <- train(m2.price~., data = apartments, method="rf", ntree = 100)
#' explainer_rf <- explain(rf_model, data = apartments_test[,2:6],
#'                         y = apartments_test$m2.price, label="rf")
#' fi_rf <- feature_importance(explainer_rf, loss_function = loss_root_mean_square)
#'
#' head(fi_rf)
#' plotD3(fi_rf)
#'
#' svm_model <- train(m2.price~., data = apartments, method="svmLinear")
#' explainer_svm <- explain(svm_model, data = apartments_test[,2:6],
#'                         y = apartments_test$m2.price, label="svm")
#' fi_svm <- feature_importance(explainer_svm, loss_function = loss_root_mean_square)
#'
#' head(fi_svm)
#' plotD3(fi_rf, fi_svm)
#'
#' plotD3(fi_rf, fi_svm, split = "feature")
#'
#' plotD3(fi_rf, fi_svm, max_vars = 3, bar_width = 16, scale_height = TRUE)
#' plotD3(fi_rf, fi_svm, max_vars = 3, bar_width = 16, split = "feature", scale_height = TRUE)
#' plotD3(fi_rf, margin = 0.2)
#' }
#' @export
#' @rdname plotD3_feature_importance
plotD3.feature_importance_explainer <-  function(x, ...,  max_vars = NULL, bar_width = 12, split = "model", scale_height = FALSE, margin = 0.15){
    if (!(split %in% c("model", "feature"))){
      stop("The plotD3.feature_importance_explainer() function requires split to be model or feature.")
    }

    n <- length(list(...)) + 1
    m <- dim(x)[1] - 2

    dfl <- c(list(x), list(...))
    df <- do.call(rbind, dfl)

    xmax <- max(df[df$variable!="_baseline_",]$dropout_loss)
    xmin <- min(df$dropout_loss)

    ticksMargin <- abs(xmin-xmax)*margin;

    bestFits <- df[df$variable == "_full_model_", ]
    df <- merge(df, bestFits[,c("label", "dropout_loss")], by = "label")

    # remove rows that starts with _
    df <- df[!(substr(df$variable,1,1) == "_"),]

    perm <- aggregate(df$dropout_loss.x, by = list(Category=df$variable), FUN = mean)

    options <- list(barWidth = bar_width, xmin = xmin-ticksMargin, xmax = xmax+ticksMargin, scaleHeight = scale_height)

    if (split == "model"){
      # one plot for each model

      # for each model leave only max_vars
      if (!is.null(max_vars) && max_vars < m) {
        m <- max_vars

        trimmed_parts <- lapply(unique(df$label), function(label) {
          tmp <- df[df$label == label, ]
          tmp[tail(order(tmp$dropout_loss.x), max_vars), ]
        })
        df <- do.call(rbind, trimmed_parts)
      }

      # sorting bars in groups
      perm <- as.character(perm$Category[order(perm$x)])
      df$variable <- factor(as.character(df$variable), levels = perm)
      df <- df[order(df$label, df$variable),]

      colnames(df) <- c("label","variable","dropout_loss", "full_model")
      temp <- split(df[,2:4], f = df$label)
      temp <- jsonlite::toJSON(temp)

      # n - number of models, m - number of features
      options["n"] <- n
      options["m"] <- m

      r2d3::r2d3(data = temp, script = system.file("d3js/featureImportance.js", package = "ingredients"),
                 dependencies = system.file("d3js/colorsDrWhy.js", package = "ingredients"),
                 css = system.file("d3js/themeDrWhy.css", package = "ingredients"),
           d3_version = 4,
           options = options)

    } else if (split == "feature"){
      # one plot for each feature

      colnames(df) <- c("label","variable","dropout_loss", "full_model")
      temp <- split(df[,c(1,3,4)], f = as.character(df$variable))

      # sorting plots, leave only max_vars of features
      temp <- temp[as.character(perm$Category)[order(-perm$x)]]
      if (!is.null(max_vars) && max_vars < m) {
        m <- max_vars

        temp <- temp[1:max_vars]
      }
      temp <- jsonlite::toJSON(temp)

      # n - number of features, m - number of models
      options["n"] <- m
      options["m"] <- n

      r2d3::r2d3(data = temp, script = system.file("d3js/featureImportanceSplit.js", package = "ingredients"),
                 dependencies = system.file("d3js/colorsDrWhy.js", package = "ingredients"),
                 css = system.file("d3js/themeDrWhy.css", package = "ingredients"),
           d3_version = 4,
           options = options)
    }
}


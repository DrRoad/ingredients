% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/ceteris_paribus_2d.R
\name{ceteris_paribus_2d}
\alias{ceteris_paribus_2d}
\title{Ceteris Paribus 2D Plot}
\usage{
ceteris_paribus_2d(explainer, observation, grid_points = 101,
  variables = NULL)
}
\arguments{
\item{explainer}{a model to be explained, preprocessed by the 'DALEX::explain' function}

\item{observation}{a new observation for which predictions need to be explained}

\item{grid_points}{number of points used for response path. Will be used for both variables}

\item{variables}{if specified, then only these variables will be explained}
}
\value{
An object of the class 'ceteris_paribus_2d_explainer'.
It's a data frame with calculated average responses.
}
\description{
This function calculates ceteris paribus profiles for grid of values spanned by two variables.
It may be useful to identify or present interactions between two variables.
}
\details{
Find more details in \href{https://pbiecek.github.io/PM_VEE/ceterisParibus2d}{Ceteris Paribus 2D}.
}
\examples{
library("DALEX")
# Toy examples, because CRAN angels ask for them
titanic <- na.omit(titanic)
model_titanic_glm <- glm(survived == "yes" ~ gender + age + fare,
                       data = titanic, family = "binomial")

explain_titanic_glm <- explain(model_titanic_glm,
                           data = titanic[,-9],
                           y = titanic$survived == "yes")
cp_rf <- ceteris_paribus_2d(explain_titanic_glm, titanic[1,])
head(cp_rf)
plot(cp_rf)
 \donttest{
library("randomForest")
set.seed(59)

apartments_rf_model <- randomForest(m2.price ~ construction.year + surface + floor +
      no.rooms + district, data = apartments)

explainer_rf <- explain(apartments_rf_model,
      data = apartmentsTest[,2:6], y = apartmentsTest$m2.price)

new_apartment <- apartmentsTest[1, ]
new_apartment

wi_rf_2d <- ceteris_paribus_2d(explainer_rf, observation = new_apartment,
         variables = c("surface", "floor", "no.rooms"))
head(wi_rf_2d)
plot(wi_rf_2d)
}
}

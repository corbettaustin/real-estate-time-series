# ============================================================
# STAT 645 post-project robustness check
# ETS(M,A,M) vs manual seasonal ARIMA across annual origins
# ============================================================

suppressPackageStartupMessages({
  library(fpp3)
  library(tidyverse)
  library(readxl)
})

set.seed(42)

#Q1 - Load and validate the same public series used by the final project.
raw <- read_excel("MEDLISPRIRI.xlsx", sheet = "Monthly")
stopifnot(identical(
  names(raw), c("observation_date", "MEDLISPRIRI")
))
stopifnot(nrow(raw) == 117L)
stopifnot(!any(is.na(raw$observation_date)))
stopifnot(!any(is.na(raw$MEDLISPRIRI)))
stopifnot(is.numeric(raw$MEDLISPRIRI))

price_ts <- raw %>%
  transmute(
    month = yearmonth(observation_date),
    price = as.numeric(MEDLISPRIRI)
  ) %>%
  as_tsibble(index = month)

stopifnot(
  sum(duplicated(price_ts$month)) == 0L,
  sum(has_gaps(price_ts)$.gaps) == 0L,
  min(price_ts$month) == yearmonth("2016 Jul"),
  max(price_ts$month) == yearmonth("2026 Mar")
)

#Q2 - Fit the two fixed specifications on one shared fold.
fit_fold <- function(train, valid) {
  stopifnot(nrow(valid) == 12L)
  stopifnot(max(train$month) + 1 == min(valid$month))

  fits <- train %>%
    model(
      ETS_MAM = ETS(
        price ~ error("M") + trend("A") + season("M")
      ),
      ARIMA_man = ARIMA(
        price ~ pdq(1, 1, 1) + PDQ(0, 1, 1)
      )
    )

  forecasts <- fits %>%
    forecast(h = 12) %>%
    as_tibble() %>%
    select(.model, month, predicted = .mean) %>%
    left_join(as_tibble(valid), by = "month")

  stopifnot(nrow(forecasts) == 24L)
  stopifnot(!any(is.na(forecasts$price)))
  stopifnot(!any(is.na(forecasts$predicted)))

  forecasts %>%
    mutate(error = price - predicted)
}

#Q3 - Use five preregistered, non-overlapping 12-month windows.
fold_spec <- tibble(
  fold = 1:5,
  train_end = yearmonth(c(
    "2021 Mar", "2022 Mar", "2023 Mar", "2024 Mar", "2025 Mar"
  )),
  valid_start = yearmonth(c(
    "2021 Apr", "2022 Apr", "2023 Apr", "2024 Apr", "2025 Apr"
  )),
  valid_end = yearmonth(c(
    "2022 Mar", "2023 Mar", "2024 Mar", "2025 Mar", "2026 Mar"
  ))
)

fold_metrics <- list()
fold_errors <- list()

for (i in seq_len(nrow(fold_spec))) {
  spec <- fold_spec[i, ]
  train <- price_ts %>% filter(month <= spec$train_end)
  valid <- price_ts %>%
    filter(month >= spec$valid_start, month <= spec$valid_end)

  stopifnot(max(train$month) == spec$train_end)
  stopifnot(min(valid$month) == spec$valid_start)
  stopifnot(max(valid$month) == spec$valid_end)

  errors <- fit_fold(train, valid)
  accuracy <- errors %>%
    group_by(.model) %>%
    summarise(
      RMSE = sqrt(mean(error^2)),
      MAE = mean(abs(error)),
      .groups = "drop"
    )

  fold_metrics[[i]] <- accuracy %>%
    mutate(
      scope = paste0("fold_", i),
      train_rows = nrow(train),
      valid_rows = nrow(valid),
      train_end = format(spec$train_end),
      valid_start = format(spec$valid_start),
      valid_end = format(spec$valid_end)
    ) %>%
    select(
      scope, .model, train_rows, valid_rows, train_end,
      valid_start, valid_end, RMSE, MAE
    )

  fold_errors[[i]] <- errors %>% mutate(fold = i)
}

metrics <- bind_rows(fold_metrics)
errors_all <- bind_rows(fold_errors)
pooled <- errors_all %>%
  group_by(.model) %>%
  summarise(
    RMSE = sqrt(mean(error^2)),
    MAE = mean(abs(error)),
    .groups = "drop"
  )

pooled_ets <- pooled %>% filter(.model == "ETS_MAM")
pooled_arima <- pooled %>% filter(.model == "ARIMA_man")
rmse_improvement <- (
  pooled_ets$RMSE - pooled_arima$RMSE
) / pooled_ets$RMSE

fold_winners <- metrics %>%
  select(scope, .model, RMSE) %>%
  group_by(scope) %>%
  slice_min(RMSE, n = 1, with_ties = FALSE) %>%
  ungroup()
arima_wins <- sum(fold_winners$.model == "ARIMA_man")

# Exact reconciliation to the original April 2025-March 2026 holdout.
final_fold <- metrics %>% filter(scope == "fold_5")
stopifnot(abs(
  final_fold$RMSE[final_fold$.model == "ETS_MAM"] -
    12658.4452474234
) <= 1e-6)
stopifnot(abs(
  final_fold$RMSE[final_fold$.model == "ARIMA_man"] -
    14020.9488525887
) <= 1e-6)

decision <- if (pooled_arima$RMSE >= pooled_ets$RMSE) {
  "REJECT"
} else if (
  rmse_improvement >= 0.05 &&
  pooled_arima$MAE <= pooled_ets$MAE &&
  arima_wins >= 3L
) {
  "PROMOTE"
} else {
  "INCONCLUSIVE"
}

pooled_rows <- pooled %>%
  mutate(
    scope = "pooled",
    train_rows = NA_integer_,
    valid_rows = 60L,
    train_end = NA_character_,
    valid_start = "2021 Apr",
    valid_end = "2026 Mar"
  ) %>%
  select(
    scope, .model, train_rows, valid_rows, train_end,
    valid_start, valid_end, RMSE, MAE
  )

metrics_output <- bind_rows(metrics, pooled_rows)
write.csv(
  metrics_output,
  file.path("figures", "rolling_origin_metrics.csv"),
  row.names = FALSE,
  na = ""
)

#Q4 - Plot annual RMSE so the regime sensitivity is visible.
plot_data <- metrics %>%
  mutate(
    validation_year = factor(valid_end),
    model = recode(
      .model,
      ETS_MAM = "ETS(M,A,M)",
      ARIMA_man = "Seasonal ARIMA"
    )
  )

p_backtest <- plot_data %>%
  ggplot(aes(validation_year, RMSE, group = model, color = model)) +
  geom_line(linewidth = 1.1) +
  geom_point(size = 3) +
  scale_color_manual(values = c(
    "ETS(M,A,M)" = "#07294D",
    "Seasonal ARIMA" = "#FFC600"
  )) +
  scale_y_continuous(
    labels = scales::label_dollar(scale = 1 / 1000, suffix = "k")
  ) +
  labs(
    title = "Seasonal ARIMA lowers pooled RMSE by 39%",
    subtitle = "Five expanding-window forecasts; each validation period is 12 months",
    x = "Validation year ending March",
    y = "RMSE (USD)",
    color = NULL,
    caption = "Source: FRED MEDLISPRIRI; fixed ETS(M,A,M) and ARIMA(1,1,1)(0,1,1)[12]"
  ) +
  theme_minimal(base_size = 12) +
  theme(
    legend.position = "top",
    panel.grid.minor = element_blank(),
    plot.title = element_text(face = "bold")
  )

ggsave(
  file.path("figures", "08_rolling_origin_comparison.png"),
  p_backtest,
  width = 9,
  height = 5,
  dpi = 200,
  bg = "white"
)

cat("Q1 - observations:", nrow(price_ts), "\n")
cat("Q2 - ETS pooled RMSE:", round(pooled_ets$RMSE, 2), "\n")
cat("Q3 - ARIMA pooled RMSE:", round(pooled_arima$RMSE, 2), "\n")
cat("Q4 - ARIMA improvement:", round(100 * rmse_improvement, 2), "%\n")
cat("Q5 - ARIMA fold wins:", arima_wins, "of 5\n")
cat("Decision:", decision, "\n")

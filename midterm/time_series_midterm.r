#STAT645-901 Midterm 
#Q6 - Q21

library(fpp3)

#convert JohnsonJohnson to tsibble
data(JohnsonJohnson)

#Q6: frequency
cat("Q6 - Frequency:", frequency(JohnsonJohnson), "\n")

jj <- as_tsibble(JohnsonJohnson) |>
  rename(earnings = value)

#Q7
#plot to confirm trend, seasonality, non-constant variance
autoplot(jj, earnings)

#Q8 additive vs multiplicative 
#variance grows with level - multiplicative preferred. additive is false

#Q9 box-cox lambda
lambda_df <- jj |> features(earnings, features = guerrero)
lambda_val <- lambda_df$lambda_guerrero
cat("Q9 - Box-Cox lambda:", round(lambda_val, 4), "\n")

#Q10 / Q11: STL feature measures 
stl_feat <- jj |> features(earnings, feat_stl)
cat("Q10 - FT (trend strength):     ", round(stl_feat$trend_strength, 3), "\n")
cat("Q11 - FS (seasonality strength):", round(stl_feat$seasonal_strength_year, 3), "\n")

#Q12 train/test split 
n <- nrow(jj)
jj_train <- jj |> slice(1:(n - 10))
jj_test  <- jj |> slice((n - 9):n)
cat("Training obs:", nrow(jj_train), " | Test obs:", nrow(jj_test), "\n")
cat("Test period:", as.character(min(jj_test$index)), "to", as.character(max(jj_test$index)), "\n")

#fit 6 models using box-cox transformation
fit <- jj_train |> model(
  Mean    = MEAN(box_cox(earnings, lambda_val)),
  Naive   = NAIVE(box_cox(earnings, lambda_val)),
  SNaive  = SNAIVE(box_cox(earnings, lambda_val)),
  RWdrift = RW(box_cox(earnings, lambda_val) ~ drift()),
  STL     = decomposition_model(
              STL(box_cox(earnings, lambda_val)),
              NAIVE(season_adjust)
            ),
  TSLM    = TSLM(box_cox(earnings, lambda_val) ~ trend() + season())
)

#forecasts 
fc <- fit |> forecast(h = 10)

#Q3 1979 = 5th test observation
target_quarter <- yearquarter("1979 Q3")

#answer - mean model forecast for 1979 Q3
q12 <- fc |> filter(.model == "Mean", index == target_quarter) |> pull(.mean)
cat("Q12 - Mean forecast Q3 1979:   ", round(q12, 2), "\n")

#Q13 naive model forecast for 1979 Q3
q13 <- fc |> filter(.model == "Naive", index == target_quarter) |> pull(.mean)
cat("Q13 - Naive forecast Q3 1979:  ", round(q13, 1), "\n")

#Q14 seasonal naive forecast for 1979 Q3
q14 <- fc |> filter(.model == "SNaive", index == target_quarter) |> pull(.mean)
cat("Q14 - SNaive forecast Q3 1979: ", round(q14, 2), "\n")

#Q15 TSLM forecast for 1979 Q3
q15 <- fc |> filter(.model == "TSLM", index == target_quarter) |> pull(.mean)
cat("Q15 - TSLM forecast Q3 1979:   ", round(q15, 1), "\n")

#Q16 RMSE for TSLM on test data
acc <- accuracy(fc, jj_test)
q16 <- acc |> filter(.model == "TSLM") |> pull(RMSE)
cat("Q16 - TSLM RMSE on test:       ", round(q16, 2), "\n")

#Q17 best model on test data, lowest RMSE
cat("Q17 - All model RMSE (test):\n")
print(acc |> select(.model, RMSE) |> arrange(RMSE))

#Q18 forecast error for RWdrift at Q3 1979 (actual - forecast)
actual_q3 <- jj_test |> filter(index == target_quarter) |> pull(earnings)
fc_rw_q3  <- fc |> filter(.model == "RWdrift", index == target_quarter) |> pull(.mean)
q18 <- actual_q3 - fc_rw_q3
cat("Q18 - RWdrift forecast error Q3 1979:", round(q18, 3), "\n")
cat("      (actual:", actual_q3, "| forecast:", round(fc_rw_q3, 3), ")\n")

#Q19 response residuals 
tslm_resid <- fit |>
  select(TSLM) |>
  residuals(type = "response")

#biggest autocorrelation (largest absolute ACF value, excl. lag 0)
acf_tslm <- ACF(tslm_resid, .resid, lag_max = 24)
acf_vals <- acf_tslm |> pull(acf)
biggest_acf_idx <- which.max(abs(acf_vals))
biggest_acf <- acf_vals[biggest_acf_idx]
cat("Q19 - Biggest ACF (response resid TSLM):", round(biggest_acf, 3), "\n")
cat("      at lag:", acf_tslm$lag[biggest_acf_idx], "\n")
print(acf_tslm)

#Q20 Ljung-Box test statistic for TSLM response residuals, 10 lags
lb_test <- tslm_resid |> features(.resid, ljung_box, lag = 10)
cat("Q20 - Ljung-Box statistic (10 lags):", round(lb_test$lb_stat, 1), "\n")
cat("      p-value:", lb_test$lb_pvalue, "\n")

#Q21 do residuals resemble white noise?
cat("Q21 - Residuals white noise? (p > 0.05 = TRUE):",
    ifelse(lb_test$lb_pvalue > 0.05, "TRUE", "FALSE"), "\n")

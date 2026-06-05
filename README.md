# Real Estate Time Series Forecasting
**Drexel STAT 645 — Time Series Forecasting**

Time series forecasting methods applied to economic and demographic datasets — building toward modeling real estate price trends with Zillow ZHVI data.

---

## Course

| | |
|---|---|
| **Course** | STAT 645 — Time Series Forecasting |
| **School** | LeBow College of Business, Drexel University |
| **Stack** | R — fpp3, fable, feasts, tsibble, tidyverse |
| **Term** | Spring 2026 |

---

## Methods Covered

| Method | Description |
|--------|-------------|
| **ETS** | Exponential smoothing — additive and multiplicative error/trend/seasonality |
| **TSLM** | Time series linear model — trend and seasonal dummy regressors |
| **ARIMA** | Autoregressive integrated moving average |
| **STL** | Seasonal and trend decomposition via LOESS |
| **Box-Cox** | Variance-stabilizing transformations (Guerrero method) |
| **Ljung-Box** | Residual autocorrelation diagnostic test |

---

## Progression

### Apr 16 — Foundations
- Naive forecasting, seasonal naive, drift method
- Mean forecasting and benchmark comparison
- Point forecast vs. prediction intervals

### May 3 — ETS Models and Decomposition
- STL decomposition with fable
- ETS model selection (AIC-based)
- Ljung-Box residual diagnostic testing
- Cross-validated accuracy metrics (RMSE, MAE, MASE)

### May 11 — Midterm: JohnsonJohnson Earnings Forecasting
- Box-Cox transformation via Guerrero method to stabilize variance
- STL feature extraction (trend strength, seasonality strength)
- ETS model fit on quarterly J&J earnings series
- Forecast with 80% and 95% prediction intervals

### May 22 — TSLM + ETS Applied Forecasting
- **TSLM with trend:** Applied to Women's 5000M Olympic running times (1996–2024) — extended dataset with 2020/2024 actual results to evaluate model accuracy
- **ETS diagnostics:** diag.R, diag2.R, diag3.R — systematic residual checking across model variants
- **Gas price forecasting:** STL + ETS on US weekly gasoline prices, holdout evaluation on 2006 actuals

---

## Applied Dataset: Zillow ZHVI

The methods above are directly applicable to modeling the **Zillow Home Value Index (ZHVI)** — zip-code level monthly median home values for single-family homes and condos. The ZHVI series exhibits the classic time series patterns (trend, seasonality, structural breaks) that ETS and ARIMA are designed to handle.

Dataset: `Zip_zhvi_uc_sfrcondo_tier_0.33_0.67_sm_sa_month.csv`

---

## File Map

| File | Content | Date |
|------|---------|------|
| `hw_1/quiz_1.R` | Naive methods, benchmarks, prediction intervals | Apr 16 |
| `hw_2/Time_Series_HW2.R` | Full hw2 — ETS, decomposition, Ljung-Box | May 3 |
| `hw_2/hw_questions_ch1_4.R` | Chapter 1–4 conceptual and applied problems | May 3 |
| `hw_2/quiz_2.R` | Quiz 2 — ETS model selection and accuracy | May 3 |
| `midterm/time_series_midterm.r` | Midterm — Box-Cox, STL, J&J earnings ETS | May 11 |
| `hw_3/hw_3.R` | Olympic running TSLM with 2020/2024 extension | May 22 |
| `hw_3/homework_ets_tslm.R` | Full TSLM + ETS homework with diagnostics | May 22 |
| `hw_3/diag.R` · `diag2.R` · `diag3.R` | Residual diagnostic scripts | May 22 |
| `quiz3/quiz_3.R` | Quiz 3 — gas price forecasting, naive vs ETS | May 22 |

# --- Package installation (to run only once) ---
# install.packages("tidyquant")
# install.packages("copula")
# install.packages("ggplot2")
# install.packages("dplyr")
# install.packages("tidyr")

# --- Load libraries ---
library(tidyquant)
library(dplyr)
library(ggplot2)
library(copula)
library(tidyr)

# --- 1. Select stocks (3 financial + 7 non-financial) ---
tickers <- c("JPM", "BAC", "GS", "AAPL", "MSFT", "XOM", "CVX", "WMT", "PG", "BA")

# --- 2. Download historical prices (2019–2022) ---
stock_data <- tq_get(tickers,
                     from = "2019-01-01",
                     to   = "2022-12-31",
                     get  = "stock.prices")

# --- 3. Compute daily log-returns ---
stock_returns <- stock_data %>% 
  group_by(symbol) %>% 
  arrange(date) %>% 
  mutate(log_return = log(adjusted / lag(adjusted))) %>% 
  filter(!is.na(log_return))

# --- 4. Plot adjusted prices ---
ggplot(stock_data, aes(x = date, y = adjusted, color = symbol)) +
  geom_line() +
  labs(title = "Adjusted Prices (2019–2022)", x = "Date", y = "Price")+
  theme_minimal()

# --- 5. Plot daily log-returns ---
ggplot(stock_returns, aes(x = date, y = log_return, color = symbol)) +
  geom_line() +
  labs(title = "Daily Log-Returns (2019–2022)", x = "Date", y = "Log-return") +
  theme_minimal()

head(financial_wide)  # (Note: This line will return an error unless `financial_wide` is defined earlier)

# --- 6. Scatter plot between stocks in the same sector (JPM vs BAC) ---
jpm_bac <- stock_returns %>%
  filter(symbol %in% c("JPM", "BAC")) %>%
  select(date, symbol, log_return) %>%
  pivot_wider(names_from = symbol, values_from = log_return) %>%
  filter(!is.na(JPM) & !is.na(BAC))

ggplot(jpm_bac, aes(x = JPM, y = BAC)) +
  geom_point(alpha = 0.5) +
  labs(title = "Scatter Plot: JPM vs BAC (Financial Sector)",
       x = "Log-return JPM", y = "Log-return BAC")+
  theme_minimal()

# --- 7. Scatter plot between different sectors (JPM vs MSFT) ---
jpm_msft <- stock_returns %>%
  filter(symbol %in% c("JPM", "MSFT")) %>%
  select(date, symbol, log_return) %>%
  pivot_wider(names_from = symbol, values_from = log_return) %>%
  filter(!is.na(JPM) & !is.na(MSFT))


  ggplot(jpm_msft, aes(x = JPM, y = MSFT)) +
  geom_point(alpha = 0.5) +
  labs(title = "Scatter Plot: JPM (Finance) vs MSFT (Technology)",
       x = "Log-return JPM", y = "Log-return MSFT") +
  theme_minimal()

# --- 8. Build an equally-weighted portfolio ---
portfolio_return <- stock_returns %>% 
  group_by(date) %>% 
  summarise(portfolio_return = mean(log_return, na.rm = TRUE)) %>% 
  ungroup()

# --- 9. Compute Value-at-Risk (empirical and normal) ---
empirical_VaR <- quantile(portfolio_return$portfolio_return, probs = 0.05)
mu <- mean(portfolio_return$portfolio_return)
sigma <- sd(portfolio_return$portfolio_return)
normal_VaR <- mu - 1.645 * sigma

empirical_VaR
normal_VaR

# --- 10. Plot portfolio returns ---
ggplot(portfolio_return, aes(x = date, y = portfolio_return)) +
  geom_line(color = "blue") +
  labs(title = "Daily Portfolio Log-Return", x = "Date", y = "Return")+
  theme_minimal() 

# --- 11. VaR backtesting using 2023 data ---
future_data <- tq_get(tickers,
                      from = "2023-01-01",
                      to   = "2023-12-31",
                      get  = "stock.prices")

future_returns <- future_data %>%
  group_by(symbol) %>%
  arrange(date) %>%
  mutate(log_return = log(adjusted / lag(adjusted))) %>%
  filter(!is.na(log_return))

future_portfolio <- future_returns %>%
  group_by(date) %>%
  summarise(portfolio_return = mean(log_return, na.rm = TRUE)) %>%
  ungroup()

# --- 12. VaR 95% coverage check ---
violations <- mean(future_portfolio$portfolio_return < empirical_VaR)
violations  # Expected value: about 5% if the model is accurate

# --- PART 2: COPULAS ON FINANCIAL STOCKS ---

# --- 13. Prepare data in wide format ---
copula_data <- stock_returns %>%
  filter(symbol %in% c("JPM", "BAC", "GS")) %>%
  select(date, symbol, log_return) %>%
  pivot_wider(names_from = symbol, values_from = log_return) %>%
  drop_na()

# --- 14. Pseudo-observations (required for copulas) ---
pseudo_obs <- apply(copula_data[, -1], 2, rank) / (nrow(copula_data) + 1)

# --- 15. Fit copulas ---
gaussian_cop <- normalCopula(dim = 3, dispstr = "un")
fit_gauss <- fitCopula(gaussian_cop, pseudo_obs, method = "ml")

t_cop <- tCopula(dim = 3, dispstr = "un")
fit_t <- fitCopula(t_cop, pseudo_obs, method = "ml")

clayton_cop <- claytonCopula(dim = 3)
fit_clayton <- fitCopula(clayton_cop, pseudo_obs, method = "ml")

gumbel_cop <- gumbelCopula(dim = 3)
fit_gumbel <- fitCopula(gumbel_cop, pseudo_obs, method = "ml")

# --- 16. Compare copulas using AIC ---
aics <- c(
  AIC(fit_gauss),
  AIC(fit_t),
  AIC(fit_clayton),
  AIC(fit_gumbel)
)
names(aics) <- c("Gaussian", "t-Copula", "Clayton", "Gumbel")
aics

# --- Copula Analysis (QRM/tseries version) ---

# Load required packages
library(QRM)
library(tseries)

# 1. Select return data for JPM and BAC (two financial stocks)
copula_data <- stock_returns %>%
  filter(symbol %in% c("JPM", "BAC")) %>%
  select(date, symbol, log_return) %>%
  pivot_wider(names_from = symbol, values_from = log_return) %>%
  drop_na()

# 2. Convert to matrix and remove rows with zero returns in both assets
X <- as.matrix(copula_data[, -1])
X <- X[X[,1] != 0 & X[,2] != 0, ]

# 3. Create pseudo-observations using empirical distribution function (edf)
copulaX <- apply(X, 2, edf, adjust = 1)

# 4. Fit copulas
copulaXGauss <- fit.gausscopula(copulaX)           # Gaussian copula
copulaXt     <- fit.tcopula(copulaX)               # Student-t copula
copulaXGumb  <- fit.AC(copulaX, "gumbel")          # Gumbel copula (Archimedean)
copulaXClay  <- fit.AC(copulaX, "clayton")         # Clayton copula (Archimedean)

# 5. Compare log-likelihoods to select the best-fitting copula
loglik_table <- data.frame(
  copula = c("Gaussian", "Student-t", "Gumbel", "Clayton"),
  logLik = c(
    copulaXGauss$ll.max,
    copulaXt$ll.max,
    copulaXGumb$ll.max,
    copulaXClay$ll.max
  )
)

print(loglik_table)

# 6. (Optional) Compute Spearman's and Kendall's tau
print(Spearman(copulaX))
print(sin(pi * Kendall(copulaX) / 2))

# Pseudo-osservazioni (copulaX) 
plot(copulaX, main = "Pseudo-observations (JPM vs BAC)",
     xlab = "JPM (U)", ylab = "BAC (U)", pch = 16, col = rgb(0, 0, 1, 0.5))

# --- VaR Backtesting (Kupiec POF Test) ---

# Parameters
alpha <- 0.95
VaR_level <- 1 - alpha
T <- nrow(future_portfolio)
violations_vector <- future_portfolio$portfolio_return < empirical_VaR
x <- sum(violations_vector)         # Number of observed violations
p_hat <- x / T                      # Empirical failure rate

# Kupiec test statistic (Likelihood Ratio for Proportion of Failures)
LR_POF <- -2 * log(((1 - p_hat)^(T - x) * (p_hat^x)) / ((1 - VaR_level)^(T - x) * (VaR_level^x)))
p_value <- 1 - pchisq(LR_POF, df = 1)

# Output
cat("Kupiec POF Test:\n")
cat("Observed violations:", x, "out of", T, "days\n")
cat("LR_POF =", round(LR_POF, 3), "\n")
cat("p-value =", round(p_value, 4), "\n")

if (p_value < 0.05) {
  cat("The VaR model is statistically rejected at the 5% level\n")
} else {
  cat("The VaR model is accepted: no evidence of misspecification in violation rate\n")
}


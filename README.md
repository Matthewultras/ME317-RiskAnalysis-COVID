# LSE ME317 Project Report  
### What Happened During the COVID-19 Pandemic?

**Author**: Matteo Piccirilli  
**Date**: July 27, 2025  

---

## 1. Introduction

The COVID-19 outbreak in early 2020 triggered a period of extreme volatility in global stock markets.  
This report analyzes the performance of 10 diversified US stocks from 2019 to 2023 using techniques from the ME317 course:

- Market dynamics  
- Risk modeling with Value-at-Risk (VaR)  
- Dependence structures with copulas  

---

## 2. Data and Stock Selection

We selected 10 major stocks from various sectors:

- Financials: JPM, BAC, GS  
- Tech & Industrial: AAPL, MSFT, BA  
- Consumer & Energy: WMT, PG, XOM, CVX  

Historical data was collected from January 1, 2019, to December 31, 2022, using the `tidyquant` R package.

---

## 3. Market Dynamics During the Pandemic

### Adjusted Prices  
Sharp declines occurred between February and March 2020 due to lockdowns and uncertainty.

**Figure 1 – Adjusted Prices (2019–2022)**  
![Adjusted Prices](images/adjusted_prices.png)

### Daily Log-Returns  
Spikes in volatility are clearly visible during the early pandemic period.

**Figure 2 – Daily Log-Returns (2019–2022)**  
![Daily Log Returns](images/daily_log_returns.png)

---

## 4. Sector Relationships and Diversification

### JPM vs BAC (Same Sector - Financials)  
Strong linear correlation between the two banks.

**Figure 3 – JPM vs BAC**  
![JPM vs BAC](images/jpm_vs_bac.png)

### JPM vs MSFT (Different Sectors)  
Weaker correlation due to cross-sector diversification.

**Figure 4 – JPM vs MSFT**  
![JPM vs MSFT](images/jpm_vs_msft.png)

**Observation**: Correlation increases during crises, reducing the effectiveness of diversification.

---

## 5. Portfolio Construction and VaR Estimation

We created an equally weighted portfolio ($1000 in each stock) and calculated the daily portfolio return.

**Figure 5 – Portfolio Daily Log-Returns**  
![Portfolio Return](images/portfolio_return.png)

**1-Day VaR at 95% Confidence Level:**

- Empirical VaR: −2.24%  
- Normal VaR: −2.66%

---

## 6. Backtesting with 2023 Data

Out of 251 trading days in 2023:

- Observed VaR violations: 1  
- Expected at 5%: ~12  
- Conclusion: Model is conservative in the post-COVID market

**Kupiec Test Result:**

- Likelihood Ratio: 11.83  
- p-value: 0.0006  
- Verdict: Reject the null — the model overestimates risk

---

## 7. Copula Analysis (JPM, BAC, GS)

To model dependency between financial institutions, we applied copulas to pseudo-observations.

### AIC Comparison (Multivariate)

| Copula Model | AIC     |
|--------------|---------|
| Gaussian     | -3219   |
| Student-t    | **-3423** |
| Clayton      | -2499   |
| Gumbel       | -2993   |

**Best fit**: Student-t copula, capturing joint tail risk.

---

## 8. Bivariate Copula: JPM vs BAC

Using the `QRM` and `tseries` R packages, we performed bivariate copula fitting.

### Log-Likelihood Comparison

| Copula Model | Log-Likelihood |
|--------------|----------------|
| Gaussian     | 928            |
| Student-t    | **990**        |
| Gumbel       | 952            |
| Clayton      | 752            |

- Spearman’s rho: 0.91  
- Kendall’s tau: ~0.925  
- Strong co-movement in crisis periods

### Figure 6 – Pseudo-observations (EDF) for JPM vs BAC  
![Figure 6 – Pseudo-observations](images/pseudo_observations.png)

---

## 9. Conclusion

- COVID-19 led to systemic risk and high volatility  
- Diversification was effective during normal periods, but failed during stress  
- Empirical VaR was conservative post-crisis  
- The Student-t copula best captured joint risk dependence

---

## 10. Appendix

- Full R code available in [`R_script.R`](R_script.R)  
- Data source: Yahoo Finance via `tidyquant`  

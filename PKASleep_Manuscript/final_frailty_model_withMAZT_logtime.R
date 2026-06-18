# final_frailty_model_withMAZT_logtime.R
# Cox frailty models for sleep-wake analysis — PKA-SP x log(time) interaction
# Called from Python via subprocess — reads data from CSV, writes results to CSV
#
# Identical structure to final_frailty_model_withMAZT.R except all models
# containing PKA-SP include a PKA-SP x log(time) interaction term to satisfy
# the proportional hazards assumption. log(stop) is centered at its mean so
# the main PKA-SP coefficient is interpretable at the average time point
# within bouts (Grambsch & Therneau, 1994).
#
# Models:
#   Base model  : categorical ZT only
#   Main model  : PKA-SP + PKA-SP:log(time) + categorical ZT
#   MA model    : microarousals + categorical ZT
#   Final model : PKA-SP + PKA-SP:log(time) + microarousals + categorical ZT
#
# All models include per-animal Gaussian frailty.
# ZT is binned into 12 categories of 2h each; reference = ZT0-2.
#
# Outputs:
#   output_path          — scalar results (HR, CI, p, LR tests)
#   output_path_zt_cat   — per-bin ZT HRs for all 4 models
#   output_path_ph_test  — PH test results

library(survival)
library(coxme)

# =============================================================================
# HELPER FUNCTIONS
# =============================================================================

covariate_stats <- function(model, varname) {
    b  <- fixef(model)[varname]
    se <- sqrt(diag(vcov(model)))[varname]
    list(coef    = as.numeric(b),
         hr      = exp(b),
         hr_low  = exp(b - 1.96 * se),
         hr_high = exp(b + 1.96 * se),
         pval    = 2 * pnorm(-abs(b / se)))
}

zt_cat_stats <- function(model, model_name, n_bins = 6) {
    coefs <- fixef(model)
    V     <- vcov(model)
    out   <- data.frame(bin=1, log_hr=0, se=0, hr=1, hr_low=1, hr_high=1)
    for (j in 2:n_bins) {
        nm  <- paste0("factor(zt_bin)", j)
        b   <- as.numeric(coefs[nm])
        se  <- as.numeric(sqrt(diag(V)[nm]))
        out <- rbind(out, data.frame(
            bin=j, log_hr=b, se=se,
            hr=exp(b), hr_low=exp(b - 1.96*se), hr_high=exp(b + 1.96*se)
        ))
    }
    out$zt_center <- (out$bin - 1) * 2 + 1
    out$model     <- model_name
    out
}

lr_test <- function(ll_full, ll_reduced, df) {
    lr <- 2 * (ll_full - ll_reduced)
    list(lr = lr, p = pchisq(lr, df = df, lower.tail = FALSE))
}

bootstrap_attenuation <- function(df, n_boot = 200, seed = 42) {
    set.seed(seed)
    bout_ids <- unique(df$bout_id)
    n_bouts  <- length(bout_ids)
    atten_boot  <- rep(NA_real_, n_boot)
    b_main_boot  <- rep(NA_real_, n_boot)
    b_final_boot <- rep(NA_real_, n_boot)

    for (b in 1:n_boot) {
        if (b %% 50 == 0 || b == 1)
            cat(sprintf("  Bootstrap iteration %d / %d\n", b, n_boot))

        sampled_bouts <- sample(bout_ids, n_bouts, replace = TRUE)
        boot_list <- lapply(seq_along(sampled_bouts), function(i) {
            d <- df[df$bout_id == sampled_bouts[i], ]
            d$bout_id <- i
            d
        })
        boot_df <- do.call(rbind, boot_list)
        boot_df$log_stop_c <- log(boot_df$stop) - mean(log(boot_df$stop))

        tryCatch({
            m_main_b  <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + factor(zt_bin) + (1 | animal_id),
                               data = boot_df)
            m_final_b <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + factor(zt_bin) + (1 | animal_id),
                               data = boot_df)
            b_main  <- as.numeric(fixef(m_main_b)["pka_sp"])
            b_final <- as.numeric(fixef(m_final_b)["pka_sp"])
            b_main_boot[b]  <- b_main
            b_final_boot[b] <- b_final
            # Guard against near-zero b_main causing division instability
            if (abs(b_main) > 0.01)
                atten_boot[b] <- (b_main - b_final) / b_main * 100
        }, error = function(e) {})
    }

    valid <- atten_boot[!is.na(atten_boot)]
    list(mean       = mean(valid),
         ci_low     = as.numeric(quantile(valid, 0.025)),
         ci_high    = as.numeric(quantile(valid, 0.975)),
         n_valid    = length(valid),
         n_boot     = n_boot,
         dist       = atten_boot,
         b_main     = b_main_boot,
         b_final    = b_final_boot)
}


# =============================================================================
# 0. LOAD DATA
# =============================================================================
args          <- commandArgs(trailingOnly = TRUE)
data_path     <- args[1]
output_path   <- args[2]
run_bootstrap    <- if (length(args) >= 3) as.logical(args[3]) else FALSE
run_ph_test      <- if (length(args) >= 4) as.logical(args[4]) else TRUE
run_linearity    <- if (length(args) >= 5) as.logical(args[5]) else FALSE

df <- read.csv(data_path)
df$animal_id <- as.factor(df$animal_id)

# 12 categorical ZT bins of 2h each; reference = ZT0-2
df$zt_bin <- as.integer(cut(df$zt, breaks = seq(0, 24, by = 2), include.lowest = TRUE))

# Center log(stop) so the main pka_sp coefficient is interpretable at the
# average time point within bouts rather than at stop = 1 second
df$log_stop_c <- log(df$stop) - mean(log(df$stop))

cat("Data loaded:\n")
cat(sprintf("  Rows     : %d\n", nrow(df)))
cat(sprintf("  Animals  : %d\n", length(unique(df$animal_id))))
cat(sprintf("  Bouts    : %d\n", length(unique(df$bout_id))))
cat(sprintf("  ZT range : %.2f -- %.2f\n", min(df$zt), max(df$zt)))
cat(sprintf("  log(stop) mean (centering value): %.4f\n", mean(log(df$stop))))
cat("\n")


# =============================================================================
# 1. FIT MODELS
# =============================================================================
cat("Fitting models...\n")

m_base        <- coxme(Surv(start, stop, event) ~ factor(zt_bin) + (1 | animal_id), data = df)
m_main        <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + factor(zt_bin) + (1 | animal_id), data = df)
m_ma          <- coxme(Surv(start, stop, event) ~ microarousals + factor(zt_bin) + (1 | animal_id), data = df)
m_final       <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + factor(zt_bin) + (1 | animal_id), data = df)
m_main_wo_zt  <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + (1 | animal_id), data = df)
m_final_wo_zt <- coxme(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + (1 | animal_id), data = df)


# =============================================================================
# 2. EXTRACT COVARIATE STATS
# =============================================================================
pka_main        <- covariate_stats(m_main,        "pka_sp")
pka_final       <- covariate_stats(m_final,       "pka_sp")
pka_main_wo_zt  <- covariate_stats(m_main_wo_zt,  "pka_sp")
pka_final_wo_zt <- covariate_stats(m_final_wo_zt, "pka_sp")
ma_ma           <- covariate_stats(m_ma,          "microarousals")
ma_final        <- covariate_stats(m_final,       "microarousals")
ma_final_wo_zt  <- covariate_stats(m_final_wo_zt, "microarousals")
pka_time_main   <- covariate_stats(m_main,        "pka_sp:log_stop_c")
pka_time_final  <- covariate_stats(m_final,       "pka_sp:log_stop_c")

cat(sprintf("PKA-SP HR at mean time (main)         : %.4f [%.4f, %.4f]  p=%.4e\n",
            pka_main$hr,       pka_main$hr_low,       pka_main$hr_high,       pka_main$pval))
cat(sprintf("PKA-SP x log(time) coef (main)        : %.4f  p=%.4e\n",
            pka_time_main$coef, pka_time_main$pval))
cat(sprintf("PKA-SP HR at mean time (main_wo_zt)   : %.4f [%.4f, %.4f]  p=%.4e\n",
            pka_main_wo_zt$hr, pka_main_wo_zt$hr_low, pka_main_wo_zt$hr_high, pka_main_wo_zt$pval))
cat(sprintf("PKA-SP HR at mean time (final)        : %.4f [%.4f, %.4f]  p=%.4e\n",
            pka_final$hr,      pka_final$hr_low,      pka_final$hr_high,      pka_final$pval))
cat(sprintf("PKA-SP x log(time) coef (final)       : %.4f  p=%.4e\n",
            pka_time_final$coef, pka_time_final$pval))
cat(sprintf("PKA-SP HR at mean time (final_wo_zt)  : %.4f [%.4f, %.4f]  p=%.4e\n",
            pka_final_wo_zt$hr, pka_final_wo_zt$hr_low, pka_final_wo_zt$hr_high, pka_final_wo_zt$pval))
cat(sprintf("MA HR (MA model)                      : %.4f [%.4f, %.4f]  p=%.4e\n",
            ma_ma$hr,          ma_ma$hr_low,          ma_ma$hr_high,          ma_ma$pval))
cat(sprintf("MA HR (final model)                   : %.4f [%.4f, %.4f]  p=%.4e\n",
            ma_final$hr,       ma_final$hr_low,       ma_final$hr_high,       ma_final$pval))
cat(sprintf("MA HR (final_wo_zt model)             : %.4f [%.4f, %.4f]  p=%.4e\n",
            ma_final_wo_zt$hr, ma_final_wo_zt$hr_low, ma_final_wo_zt$hr_high, ma_final_wo_zt$pval))

frailty_var_main  <- m_main$vcoef$animal_id
frailty_var_final <- m_final$vcoef$animal_id
cat(sprintf("Frailty variance (main)               : %.4f\n", frailty_var_main))
cat(sprintf("Frailty variance (final)              : %.4f\n", frailty_var_final))

m_main_nofrail  <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + factor(zt_bin), data = df)
m_final_nofrail <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + factor(zt_bin), data = df)
se_coxph_main   <- sqrt(diag(vcov(m_main_nofrail)))["pka_sp"]
se_coxme_main   <- sqrt(diag(vcov(m_main)))["pka_sp"]
se_coxph_final  <- sqrt(diag(vcov(m_final_nofrail)))["pka_sp"]
se_coxme_final  <- sqrt(diag(vcov(m_final)))["pka_sp"]
cat(sprintf("SE pka_sp — coxph/coxme (main) : %.6f / %.6f  (inflation: %.4f)\n",
            se_coxph_main, se_coxme_main, se_coxme_main / se_coxph_main))
cat(sprintf("SE pka_sp — coxph/coxme (final): %.6f / %.6f  (inflation: %.4f)\n",
            se_coxph_final, se_coxme_final, se_coxme_final / se_coxph_final))
se_inflation_main  <- as.numeric(se_coxme_main  / se_coxph_main)
se_inflation_final <- as.numeric(se_coxme_final / se_coxph_final)

# Cluster-robust SEs (sandwich estimator) — reused in PH test section
m_main_coxph  <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + factor(zt_bin),
                        data = df, cluster = animal_id)
m_final_coxph <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + factor(zt_bin),
                        data = df, cluster = animal_id)
robust_coef_main  <- summary(m_main_coxph)$coefficients
robust_coef_final <- summary(m_final_coxph)$coefficients
robust_se_pka_main    <- as.numeric(robust_coef_main["pka_sp",  "robust se"])
robust_pval_pka_main  <- as.numeric(robust_coef_main["pka_sp",  "Pr(>|z|)"])
robust_se_pka_final   <- as.numeric(robust_coef_final["pka_sp", "robust se"])
robust_pval_pka_final <- as.numeric(robust_coef_final["pka_sp", "Pr(>|z|)"])
cat(sprintf("Robust SE / p pka_sp (main) : SE=%.6f  p=%.4e\n", robust_se_pka_main,  robust_pval_pka_main))
cat(sprintf("Robust SE / p pka_sp (final): SE=%.6f  p=%.4e\n", robust_se_pka_final, robust_pval_pka_final))

# Confirm coxph (no frailty) point estimate is consistent with coxme point estimate —
# the robust SE substitution should change precision, not the coefficient itself
coef_coxph_main  <- as.numeric(robust_coef_main["pka_sp",  "coef"])
coef_coxme_main  <- as.numeric(fixef(m_main)["pka_sp"])
coef_coxph_final <- as.numeric(robust_coef_final["pka_sp", "coef"])
coef_coxme_final <- as.numeric(fixef(m_final)["pka_sp"])
cat(sprintf("Coef pka_sp — coxph/coxme (main) : %.6f / %.6f  (diff: %.6f)\n",
            coef_coxph_main, coef_coxme_main, coef_coxph_main - coef_coxme_main))
cat(sprintf("Coef pka_sp — coxph/coxme (final): %.6f / %.6f  (diff: %.6f)\n",
            coef_coxph_final, coef_coxme_final, coef_coxph_final - coef_coxme_final))


# =============================================================================
# 3. LIKELIHOOD RATIO TESTS
# =============================================================================
ll_base        <- m_base$loglik[2]
ll_main        <- m_main$loglik[2]
ll_ma          <- m_ma$loglik[2]
ll_final       <- m_final$loglik[2]
ll_main_wo_zt  <- m_main_wo_zt$loglik[2]
ll_final_wo_zt <- m_final_wo_zt$loglik[2]

n_zt_dummies <- length(unique(df$zt_bin)) - 1

# main/final vs base: PKA-SP + interaction adds 2 df
lrt_main_base  <- lr_test(ll_main,  ll_base, df = 2)
lrt_ma_base    <- lr_test(ll_ma,    ll_base, df = 1)
lrt_final_base <- lr_test(ll_final, ll_base, df = 3)

# ZT contribution: cat ZT adds n_zt_dummies df
lrt_zt_in_main  <- lr_test(ll_main,  ll_main_wo_zt,  df = n_zt_dummies)
lrt_zt_in_final <- lr_test(ll_final, ll_final_wo_zt, df = n_zt_dummies)

cat(sprintf("\nMain  vs Base        (PKA-SP + interaction beyond cat ZT) : LR=%.4f, df=2, p=%.4e\n",
            lrt_main_base$lr,   lrt_main_base$p))
cat(sprintf("MA    vs Base        (MA beyond cat ZT)                   : LR=%.4f, df=1, p=%.4e\n",
            lrt_ma_base$lr,     lrt_ma_base$p))
cat(sprintf("Final vs Base        (PKA-SP + interaction + MA)          : LR=%.4f, df=3, p=%.4e\n",
            lrt_final_base$lr,  lrt_final_base$p))
cat(sprintf("Main vs Main_wo_ZT   (cat ZT beyond PKA-SP)               : LR=%.4f, df=%d, p=%.4e\n",
            lrt_zt_in_main$lr,  n_zt_dummies, lrt_zt_in_main$p))
cat(sprintf("Final vs Final_wo_ZT (cat ZT beyond PKA-SP + MA)          : LR=%.4f, df=%d, p=%.4e\n",
            lrt_zt_in_final$lr, n_zt_dummies, lrt_zt_in_final$p))

atten_pka <- (pka_main$coef - pka_final$coef) / pka_main$coef * 100
cat(sprintf("\nPKA-SP attenuation (main -> final) : %.1f%%\n", atten_pka))


# =============================================================================
# 4. LOG-LINEARITY CHECK (MARTINGALE RESIDUALS)
# =============================================================================
if (run_linearity) {
    # Martingale residuals from ZT-only base model (no PKA-SP),
    # plotted against PKA-SP to visualise functional form given ZT
    cat("\nComputing Martingale residuals for log-linearity check (main model)...\n")
    m_base_nopka <- coxph(Surv(start, stop, event) ~ factor(zt_bin), data = df)
    mart_resid_main <- residuals(m_base_nopka, type = "martingale")
    mart_df_main <- data.frame(pka_sp = df$pka_sp, martingale = mart_resid_main)
    mart_path <- sub("\\.csv$", "_martingale_main.csv", output_path)
    write.csv(mart_df_main, mart_path, row.names = FALSE)
    cat(sprintf("Martingale residuals (main) saved to: %s\n", mart_path))

    cat("\nComputing Martingale residuals for log-linearity check (final model)...\n")
    m_base_nopka_final <- coxph(Surv(start, stop, event) ~ microarousals + factor(zt_bin), data = df)
    mart_resid_final <- residuals(m_base_nopka_final, type = "martingale")
    mart_df_final <- data.frame(pka_sp = df$pka_sp, martingale = mart_resid_final)
    mart_path_final <- sub("\\.csv$", "_martingale_final.csv", output_path)
    write.csv(mart_df_final, mart_path_final, row.names = FALSE)
    cat(sprintf("Martingale residuals (final) saved to: %s\n", mart_path_final))

    # LRT: linear+interaction (main model spec) vs spline+interaction
    # df difference = 4 (spline adds 2 df for main effect, 2 df for interaction)
    cat("\nSpline vs linear LRT for PKA-SP log-linearity (main model)...\n")
    m_linear_main <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + factor(zt_bin), data = df)
    m_spline_main <- coxph(Surv(start, stop, event) ~ splines::ns(pka_sp, df = 3) + splines::ns(pka_sp, df = 3):log_stop_c + factor(zt_bin), data = df)
    lrt_linearity_main  <- 2 * (m_spline_main$loglik[2] - m_linear_main$loglik[2])
    pval_linearity_main <- pchisq(lrt_linearity_main, df = 4, lower.tail = FALSE)
    cat(sprintf("Spline vs linear LRT (main) : chi2=%.4f, df=4, p=%.4e\n", lrt_linearity_main, pval_linearity_main))

    cat("\nSpline vs linear LRT for PKA-SP log-linearity (final model)...\n")
    m_linear_final <- coxph(Surv(start, stop, event) ~ pka_sp + pka_sp:log_stop_c + microarousals + factor(zt_bin), data = df)
    m_spline_final <- coxph(Surv(start, stop, event) ~ splines::ns(pka_sp, df = 3) + splines::ns(pka_sp, df = 3):log_stop_c + microarousals + factor(zt_bin), data = df)
    lrt_linearity_final  <- 2 * (m_spline_final$loglik[2] - m_linear_final$loglik[2])
    pval_linearity_final <- pchisq(lrt_linearity_final, df = 4, lower.tail = FALSE)
    cat(sprintf("Spline vs linear LRT (final): chi2=%.4f, df=4, p=%.4e\n", lrt_linearity_final, pval_linearity_final))
    cat("(non-significant p supports log-linearity)\n")

    # HR comparison: linear vs spline predictions at mean log_stop_c (= 0 by construction)
    # across the observed PKA-SP range (1st–99th percentile)
    pka_grid <- seq(quantile(df$pka_sp, 0.01), quantile(df$pka_sp, 0.99), length.out = 100)
    newdata_grid <- data.frame(
        pka_sp    = pka_grid,
        log_stop_c = 0,
        zt_bin    = 1,
        microarousals = 0
    )
    newdata_grid$zt_bin <- factor(newdata_grid$zt_bin, levels = levels(factor(df$zt_bin)))

    lp_linear_main <- predict(m_linear_main, newdata = newdata_grid, type = "lp")
    lp_spline_main <- predict(m_spline_main, newdata = newdata_grid, type = "lp")
    lp_linear_final <- predict(m_linear_final, newdata = newdata_grid, type = "lp")
    lp_spline_final <- predict(m_spline_final, newdata = newdata_grid, type = "lp")

    hr_comparison <- data.frame(
        pka_sp          = pka_grid,
        hr_linear_main  = exp(lp_linear_main),
        hr_spline_main  = exp(lp_spline_main),
        hr_linear_final = exp(lp_linear_final),
        hr_spline_final = exp(lp_spline_final)
    )
    hr_comparison$hr_diff_main  <- abs(hr_comparison$hr_spline_main  - hr_comparison$hr_linear_main)
    hr_comparison$hr_diff_final <- abs(hr_comparison$hr_spline_final - hr_comparison$hr_linear_final)

    hr_comp_path <- sub("\\.csv$", "_hr_linearity.csv", output_path)
    write.csv(hr_comparison, hr_comp_path, row.names = FALSE)
    cat(sprintf("Max HR difference linear vs spline (main) : %.4f\n", max(hr_comparison$hr_diff_main)))
    cat(sprintf("Max HR difference linear vs spline (final): %.4f\n", max(hr_comparison$hr_diff_final)))
    cat(sprintf("HR comparison saved to: %s\n", hr_comp_path))
} else {
    cat("\nLog-linearity check skipped (run_linearity = FALSE)\n")
    lrt_linearity_main  <- NA_real_
    pval_linearity_main <- NA_real_
    lrt_linearity_final  <- NA_real_
    pval_linearity_final <- NA_real_
}


# =============================================================================
# 5. PROPORTIONAL HAZARDS ASSUMPTION
# =============================================================================
if (run_ph_test) {
    cat("\nTesting proportional hazards assumption (main model)...\n")
    ph_test_main <- cox.zph(m_main_coxph)
    print(ph_test_main)

    cat("\nTesting proportional hazards assumption (final model)...\n")
    ph_test_final <- cox.zph(m_final_coxph)
    print(ph_test_final)

    ph_main_df        <- as.data.frame(ph_test_main$table)
    ph_main_df$term   <- rownames(ph_main_df)
    ph_main_df$model  <- "main"
    ph_final_df       <- as.data.frame(ph_test_final$table)
    ph_final_df$term  <- rownames(ph_final_df)
    ph_final_df$model <- "final"

    ph_path <- sub("\\.csv$", "_ph_test.csv", output_path)
    write.csv(rbind(ph_main_df, ph_final_df), ph_path, row.names = FALSE)
    cat(sprintf("PH test results saved to: %s\n", ph_path))

    resid_main_df      <- as.data.frame(ph_test_main$y)
    resid_main_df$time <- ph_test_main$x
    ph_resid_main_path <- sub("\\.csv$", "_ph_residuals_main.csv", output_path)
    write.csv(resid_main_df, ph_resid_main_path, row.names = FALSE)
    cat(sprintf("PH residuals (main) saved to: %s\n", ph_resid_main_path))

    resid_final_df      <- as.data.frame(ph_test_final$y)
    resid_final_df$time <- ph_test_final$x
    ph_resid_final_path <- sub("\\.csv$", "_ph_residuals_final.csv", output_path)
    write.csv(resid_final_df, ph_resid_final_path, row.names = FALSE)
    cat(sprintf("PH residuals (final) saved to: %s\n", ph_resid_final_path))
} else {
    cat("\nPH test skipped (run_ph_test = FALSE)\n")
}


# =============================================================================
# 6. BOOTSTRAP CI ON PKA-SP ATTENUATION
# =============================================================================
if (run_bootstrap) {
    n_boot <- 100
    cat(sprintf("\nBootstrapping PKA-SP attenuation (%d iterations)...\n", n_boot))
    boot_result <- bootstrap_attenuation(df, n_boot = n_boot)
    cat(sprintf("PKA-SP attenuation bootstrap: mean=%.1f%%  95%% CI [%.1f%%, %.1f%%]  (%d/%d valid)\n",
                boot_result$mean, boot_result$ci_low, boot_result$ci_high,
                boot_result$n_valid, boot_result$n_boot))
} else {
    cat("\nBootstrap skipped (run_bootstrap = FALSE)\n")
    boot_result <- list(mean = NA_real_, ci_low = NA_real_, ci_high = NA_real_,
                        n_valid = 0L, n_boot = 0L, dist = NULL)
}


# =============================================================================
# 7. SAVE RESULTS
# =============================================================================
if (!is.null(boot_result$dist)) {
    boot_dist_path <- sub("\\.csv$", "_boot_dist.csv", output_path)
    boot_dist_df   <- data.frame(
        iteration      = seq_along(boot_result$dist),
        atten_pka_boot = boot_result$dist,
        b_main_boot    = boot_result$b_main,
        b_final_boot   = boot_result$b_final
    )
    write.csv(boot_dist_df, boot_dist_path, row.names = FALSE)
    cat(sprintf("Bootstrap distribution saved to: %s\n", boot_dist_path))
}
results <- data.frame(
    metric = c(
        "hr_pka_main",         "hr_pka_main_low",         "hr_pka_main_high",         "pval_pka_main",
        "hr_pka_main_wo_zt",   "hr_pka_main_wo_zt_low",   "hr_pka_main_wo_zt_high",   "pval_pka_main_wo_zt",
        "hr_pka_final",        "hr_pka_final_low",        "hr_pka_final_high",        "pval_pka_final",
        "hr_pka_final_wo_zt",  "hr_pka_final_wo_zt_low",  "hr_pka_final_wo_zt_high",  "pval_pka_final_wo_zt",
        "hr_ma_ma",            "hr_ma_ma_low",            "hr_ma_ma_high",            "pval_ma_ma",
        "hr_ma_final",         "hr_ma_final_low",         "hr_ma_final_high",         "pval_ma_final",
        "hr_ma_final_wo_zt",   "hr_ma_final_wo_zt_low",   "hr_ma_final_wo_zt_high",   "pval_ma_final_wo_zt",
        "coef_pka_time_main",  "pval_pka_time_main",
        "coef_pka_time_final", "pval_pka_time_final",
        "lr_main_base",        "p_main_base",
        "lr_ma_base",          "p_ma_base",
        "lr_final_base",       "p_final_base",
        "lr_zt_in_main",       "p_zt_in_main",
        "lr_zt_in_final",      "p_zt_in_final",
        "atten_pka",
        "atten_pka_boot_mean", "atten_pka_boot_ci_low", "atten_pka_boot_ci_high",
        "frailty_var_main", "frailty_var_final",
        "se_inflation_main", "se_inflation_final",
        "robust_se_pka_main",  "robust_pval_pka_main",
        "robust_se_pka_final", "robust_pval_pka_final",
        "lrt_linearity_main",  "pval_linearity_main",
        "lrt_linearity_final", "pval_linearity_final"
    ),
    value = c(
        pka_main$hr,        pka_main$hr_low,        pka_main$hr_high,        pka_main$pval,
        pka_main_wo_zt$hr,  pka_main_wo_zt$hr_low,  pka_main_wo_zt$hr_high,  pka_main_wo_zt$pval,
        pka_final$hr,       pka_final$hr_low,       pka_final$hr_high,       pka_final$pval,
        pka_final_wo_zt$hr, pka_final_wo_zt$hr_low, pka_final_wo_zt$hr_high, pka_final_wo_zt$pval,
        ma_ma$hr,           ma_ma$hr_low,           ma_ma$hr_high,           ma_ma$pval,
        ma_final$hr,        ma_final$hr_low,        ma_final$hr_high,        ma_final$pval,
        ma_final_wo_zt$hr,  ma_final_wo_zt$hr_low,  ma_final_wo_zt$hr_high,  ma_final_wo_zt$pval,
        pka_time_main$coef,  pka_time_main$pval,
        pka_time_final$coef, pka_time_final$pval,
        lrt_main_base$lr,   lrt_main_base$p,
        lrt_ma_base$lr,     lrt_ma_base$p,
        lrt_final_base$lr,  lrt_final_base$p,
        lrt_zt_in_main$lr,  lrt_zt_in_main$p,
        lrt_zt_in_final$lr, lrt_zt_in_final$p,
        atten_pka,
        boot_result$mean, boot_result$ci_low, boot_result$ci_high,
        frailty_var_main, frailty_var_final,
        se_inflation_main, se_inflation_final,
        robust_se_pka_main,  robust_pval_pka_main,
        robust_se_pka_final, robust_pval_pka_final,
        lrt_linearity_main,  pval_linearity_main,
        lrt_linearity_final, pval_linearity_final
    )
)

write.csv(results, output_path, row.names = FALSE)
cat(sprintf("\nResults saved to: %s\n", output_path))

zt_cat_path <- sub("\\.csv$", "_zt_cat.csv", output_path)
n_bins      <- length(unique(df$zt_bin))
zt_cat_all  <- rbind(zt_cat_stats(m_base,  "base",  n_bins = n_bins),
                     zt_cat_stats(m_main,  "main",  n_bins = n_bins),
                     zt_cat_stats(m_ma,    "ma",    n_bins = n_bins),
                     zt_cat_stats(m_final, "final", n_bins = n_bins))
write.csv(zt_cat_all, zt_cat_path, row.names = FALSE)
cat(sprintf("ZT categorical bins saved to: %s\n", zt_cat_path))

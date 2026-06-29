import os
import pickle
import h5py
import scipy.io as sio
import pandas as pd
import scipy.io as sio
from matplotlib import  pyplot as plt
import numpy as np
from scipy.signal import welch
from scipy.io import savemat
# %matplotlib widget
import PKA_Sleep as PKA
import importlib
# from PKA_Sleep.twomodel import two_model_fit, two_model_fit_lin, gmm_cluster_pka,remove_fast_state
from scipy.signal import savgol_filter
from joblib import Parallel, delayed
from scipy.optimize import minimize


def fit_animal_bic_fast(
    P2,
    # bounds (use your current ones)
    B1_bounds=(5.0, 300.0),   # decay tau (s)
    B2_bounds=(5.0, 100.0),   # rise tau (s)
    S1_bounds=(0.5, 0.9),     # asymptote for decay
    S2_bounds=(0.5, 0.9),     # asymptote for rise

    # search budget
    n_coarse=2000,            # random samples in coarse pass
    topK=40,                  # keep best K from coarse
    n_refine_local=8,         # run local optimizer from best N seeds

    # coarse eval speed-ups
    subsample_frac=0.25,      # evaluate ~25% of timepoints in coarse pass
    rng_seed=0,
    n_jobs=-1,                # parallel jobs
    verbose=True
):
    rng = np.random.default_rng(rng_seed)

    P2 = np.asarray(P2, float)
    m = np.isfinite(P2)
    idx_all = np.flatnonzero(m)
    if idx_all.size < 20:
        raise ValueError("Too few valid samples for fitting.")

    # -------- Stage A: COARSE random search on subsample --------
    if subsample_frac < 1.0:
        k = max(200, int(np.ceil(subsample_frac * idx_all.size)))
        idx_sub = np.sort(rng.choice(idx_all, size=k, replace=False))
    else:
        idx_sub = idx_all

    logB1_lo, logB1_hi = np.log(B1_bounds[0]), np.log(B1_bounds[1])
    logB2_lo, logB2_hi = np.log(B2_bounds[0]), np.log(B2_bounds[1])

    def draw_candidate():
        B1 = np.exp(rng.uniform(logB1_lo, logB1_hi))
        B2 = np.exp(rng.uniform(logB2_lo, logB2_hi))
        S1 = rng.uniform(*S1_bounds)
        S2 = rng.uniform(*S2_bounds)
        return B1, B2, S1, S2

    def eval_candidate_sub(cand):
        B1, B2, S1, S2 = cand
        fitS, fitState, err_t, BIC_ar = PKA.two_model_fit(P2,40, 1-1/B1, S1, 1-1/B2, S2,0)
        return BIC_ar

    cands = [draw_candidate() for _ in range(n_coarse)]
    bic_sub = Parallel(n_jobs=n_jobs, prefer="threads")(delayed(eval_candidate_sub)(c) for c in cands)
    order = np.argsort(bic_sub)
    keep_idx = order[:topK]
    kept = [cands[i] for i in keep_idx]

    if verbose:
        best_sub = float(np.min(np.array(bic_sub)[keep_idx]))
        print(f"[coarse] evaluated={n_coarse}, kept={topK}, best BIC (subsample)={best_sub:.3f}")

    # -------- Stage B: refine topK on FULL data --------
    def eval_candidate_full(cand):
        B1, B2, S1, S2 = cand
        fitS, fitState, err_t, BIC_ar = PKA.two_model_fit(P2,40, 1-1/B1, S1, 1-1/B2, S2,0)
        return BIC_ar

    bic_full = Parallel(n_jobs=n_jobs, prefer="threads")(delayed(eval_candidate_full)(c) for c in kept)
    order2 = np.argsort(bic_full)
    seeds = [kept[i] for i in order2[:n_refine_local]]

    if verbose:
        print(f"[refine] topK→local seeds={n_refine_local}, best BIC (full)={float(np.min(np.array(bic_full)[order2[:1]])):.3f}")

    # -------- Stage C: local optimization on FULL data --------
    def obj(x):
        # x = [logB1, logB2, S1, S2]
        logB1, logB2, S1, S2 = x
        B1 = np.clip(np.exp(logB1), *B1_bounds)
        B2 = np.clip(np.exp(logB2), *B2_bounds)
        S1 = np.clip(S1, *S1_bounds)
        S2 = np.clip(S2, *S2_bounds)
        fitS, fitState, err_t, BIC_ar = PKA.two_model_fit(P2,40, 1-1/B1, S1, 1-1/B2, S2,0)
        return BIC_ar

    bounds_local = [
        (np.log(B1_bounds[0]), np.log(B1_bounds[1])),
        (np.log(B2_bounds[0]), np.log(B2_bounds[1])),
        (S1_bounds[0], S1_bounds[1]),
        (S2_bounds[0], S2_bounds[1]),
    ]

    best = {"B1": None, "B2": None, "S1": None, "S2": None, "bic": np.inf}

    for s in seeds:
        x0 = np.array([np.log(s[0]), np.log(s[1]), s[2], s[3]], float)
        res = minimize(obj, x0, method="L-BFGS-B", bounds=bounds_local, options=dict(maxiter=200))
        x = res.x
        B1 = float(np.clip(np.exp(x[0]), *B1_bounds))
        B2 = float(np.clip(np.exp(x[1]), *B2_bounds))
        S1 = float(np.clip(x[2], *S1_bounds))
        S2 = float(np.clip(x[3], *S2_bounds))
        fitS, fitState, err_t, BIC_ar = PKA.two_model_fit(P2,40, 1-1/B1, S1, 1-1/B2, S2,0)
        bic = BIC_ar
        if bic < best["bic"]:
            best.update(dict(B1=B1, B2=B2, S1=S1, S2=S2, bic=float(bic)))

    if verbose:
        print(f"[done] Best: {best}")

    return best


def fit_animal_bic_lin_fast(P2,
    n=40,                          # window length passed to two_model_fit_lin

    # bounds for slopes
    s1_bounds=(0.0, 1.0),          # rise slope
    s2_bounds=(-1.0, 0.0),         # fall slope (often negative)

    # search budget
    n_coarse=2000,
    topK=40,
    n_refine_local=8,

    # coarse eval speed-ups
    subsample_frac=0.25,
    rng_seed=0,
    n_jobs=-1,
    verbose=True,

    # OPTIONAL: pass through plotting flags to the fitter if you want
    plotflag=False
):
    """
    Coarse→refine→local optimization for linear two-state model using BIC.

    Fits slopes s1 (state +1) and s2 (state -1) to minimize BIC_lin returned by:
        two_model_fit_lin(P2, n, s1, s2, plotflag=False)

    Returns
    -------
    best : dict
        {"s1": ..., "s2": ..., "bic": ...}
    """
    rng = np.random.default_rng(rng_seed)

    P2 = np.asarray(P2, float)
    m = np.isfinite(P2)
    idx_all = np.flatnonzero(m)
    if idx_all.size < 20:
        raise ValueError("Too few valid samples for fitting.")

    # --- Stage A: COARSE random search on subsample ---
    if subsample_frac < 1.0:
        k = max(200, int(np.ceil(subsample_frac * idx_all.size)))
        idx_sub = np.sort(rng.choice(idx_all, size=k, replace=False))
    else:
        idx_sub = idx_all

    def draw_candidate():
        s1 = rng.uniform(*s1_bounds)
        s2 = rng.uniform(*s2_bounds)
        return float(s1), float(s2)

    def eval_candidate_sub(cand):
        s1, s2 = cand
        # Evaluate on a subsampled series with NaNs elsewhere to keep indexing consistent
        P2_sub = np.full_like(P2, np.nan, dtype=float)
        P2_sub[idx_sub] = P2[idx_sub]

        fitSL, fitErrorL, fitStateL, BIC_lin = PKA.two_model_fit_lin(
            P2_sub, n, s1, s2, plotflag=False, ax=None
        )
        return float(BIC_lin)

    cands = [draw_candidate() for _ in range(n_coarse)]
    bic_sub = Parallel(n_jobs=n_jobs, prefer="threads")(
        delayed(eval_candidate_sub)(c) for c in cands
    )
    order = np.argsort(bic_sub)
    keep_idx = order[:topK]
    kept = [cands[i] for i in keep_idx]

    if verbose:
        best_sub = float(np.min(np.array(bic_sub)[keep_idx]))
        print(f"[coarse] evaluated={n_coarse}, kept={topK}, best BIC (subsample)={best_sub:.3f}")

    # --- Stage B: refine topK on FULL data ---
    def eval_candidate_full(cand):
        s1, s2 = cand
        fitSL, fitErrorL, fitStateL, BIC_lin = PKA.two_model_fit_lin(
            P2, n, s1, s2, plotflag=False, ax=None
        )
        return float(BIC_lin)

    bic_full = Parallel(n_jobs=n_jobs, prefer="threads")(
        delayed(eval_candidate_full)(c) for c in kept
    )
    order2 = np.argsort(bic_full)
    seeds = [kept[i] for i in order2[:n_refine_local]]

    if verbose:
        print(f"[refine] topK→local seeds={n_refine_local}, best BIC (full)={float(np.min(np.array(bic_full)[order2[:1]])):.3f}")

    # --- Stage C: local optimization on FULL data ---
    def obj(x):
        s1, s2 = x
        s1 = float(np.clip(s1, *s1_bounds))
        s2 = float(np.clip(s2, *s2_bounds))
        fitSL, fitErrorL, fitStateL, BIC_lin = PKA.two_model_fit_lin(
            P2, n, s1, s2, plotflag=False, ax=None
        )
        return float(BIC_lin)

    bounds_local = [s1_bounds, s2_bounds]

    best = {"s1": None, "s2": None, "bic": np.inf}

    for s in seeds:
        x0 = np.array([s[0], s[1]], float)
        res = minimize(obj, x0, method="L-BFGS-B", bounds=bounds_local, options=dict(maxiter=200))
        x = res.x
        s1 = float(np.clip(x[0], *s1_bounds))
        s2 = float(np.clip(x[1], *s2_bounds))

        # re-eval (full) with clipped params
        fitSL, fitErrorL, fitStateL, BIC_lin = PKA.two_model_fit_lin(
            P2, n, s1, s2, plotflag=False, ax=None
        )
        bic = float(BIC_lin)
        if bic < best["bic"]:
            best.update(dict(s1=s1, s2=s2, bic=bic))

    if verbose:
        print(f"[done] Best: {best}")

    # Optional: final diagnostic plot
    if plotflag:
        _ = PKA.two_model_fit_lin(P2, n, best["s1"], best["s2"], plotflag=True, ax=None)

    return best

if __name__ == "__main__":
    df = PKA.pull_experiment_names()
    epoch_len = 4
    filter_bounds = [None, None]
    binned = False
    shuffle_window = 200
    experimental_sensor = 'FLIM-mAKAR'
    sleep_states = True
    microarousals = True
    seperate_acqs = False
    emp_lifetime = False
    gather_timestamps = False
    parent_data_directory = '/Volumes/yaochen/Active/Lizzie/FLP_data/'
    baseline_only = True
    experiment_names = list(df['Experiment Name'])
    mouse_names = list(df['Mouse ID'])

    raw_datadirs = [os.path.join(parent_data_directory, e) for e in experiment_names]
    if baseline_only:
        # df = pd.read_excel('/Volumes/yaochen/Active/Lizzie/FLP_data/FLiP_Experiment_Summary.xlsx')
        # df = df[df['Experiment Name'].isin(experiment_names)]
        baseline_idxs = [(start,end) for start, end in zip(df['Baseline Start'], df['Baseline End'])]
        excluded_acqs = PKA.choose_excluded_acqs(raw_datadirs, first_acqs = 3, specific_acqs = False, 
                                                  pull_baseline = True, baseline_idxs = baseline_idxs)
    else:
         excluded_acqs = PKA.choose_excluded_acqs(raw_datadirs, first_acqs = 3, specific_acqs = False, pull_baseline = False)
       
    FLP_classes_dicts = PKA.build_classes(experiment_names, mouse_names, epoch_len = epoch_len, 
                                         filter_bounds = filter_bounds, binned = binned, 
                                         shuffle_window = shuffle_window, experimental_sensor = experimental_sensor, 
                                         sleep_states = sleep_states, microarousals = microarousals, 
                                         seperate_acqs = seperate_acqs, emp_lifetime = False,
                                         parent_data_directory = parent_data_directory, gather_timestamps = True, 
                                          exclude_acqs = excluded_acqs)

    all_fits = {}
    for b, FLP_exp in zip(experiment_names,FLP_classes_dicts):
    	clipped_time_SSidx = PKA.clip_wake(FLP_exp.SleepStates, slide = 1, thresh = 0.2, max_length = 7200)
    	clipped_time_idx, = np.where((FLP_exp.Time >= FLP_exp.SSTime[clipped_time_SSidx[0]]) & 
    	                             (FLP_exp.Time < FLP_exp.SSTime[clipped_time_SSidx[1]]))
    	all_fits[b]['Fit Index'] = clipped_time_idx
    	all_fits[b]['Exponential Fit'] = fit_animal_bic_fast(savgol_filter(FLP_exp.Lifetime[clipped_time_idx], 11, 2))
    	all_fits[b]['Linear Fit'] = fit_animal_bic_lin_fast(savgol_filter(FLP_exp.Lifetime[clipped_time_idx], 11, 2),
    		    n=40,
    		    s1_bounds=(-0.001, 0.0),
    		    s2_bounds=(0.0, 0.01),
    		    n_coarse=3000,
    		    topK=60,
    		    n_refine_local=10,
    		    subsample_frac=0.25,
    		    rng_seed=0,
    		    n_jobs=-1,
    		    verbose=True)
        np.save('/Volumes/yaochen/Active/Lizzie/FLP_data/exp_lin_fits.npy')
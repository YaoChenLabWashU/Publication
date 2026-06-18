import numpy as np
import math
import matplotlib.pyplot as plt
from scipy import stats
from sklearn.linear_model import LinearRegression
from sklearn.preprocessing import StandardScaler
from sklearn.mixture import GaussianMixture
from scipy.stats import zscore,qmc
import os, glob, pickle, warnings
import pandas as pd
from scipy.signal import welch, savgol_filter
from scipy.ndimage import uniform_filter1d
from numpy.polynomial.polynomial import polyfit
from scipy.optimize import minimize
from sklearn.metrics import r2_score
from PKA_Sleep.PKA_utils import find_continuous

def two_model_fit(S, n, B1, S1, B2, S2, plotflag=False, ax=None):
    """
    Fits a time series S with two alternating AR(1)-style models in a sliding window of length n.
    Window step is (n-1).

    Model 1 (state = +1): x_t = B1*x_{t-1} + C1,   C1 = S1*(1-B1)
    Model 2 (state = -1): x_t = B2*x_{t-1} + C2,   C2 = S2*(1-B2)

    Parameters
    ----------
    S : array_like
        1D time series.
    n : int
        Window length (>= 2).
    B1, S1, B2, S2 : float
        Model parameters.
    plotflag : bool, optional
        If True, plots similar diagnostics (requires matplotlib).
    ax : tuple(matplotlib.axes.Axes, matplotlib.axes.Axes, matplotlib.axes.Axes) or None
        Optional axes (ax1, ax2, ax3) to plot into when plotflag=True.

    Returns
    -------
    fitS : np.ndarray
        Fitted trajectory (same length as S).
    fitState : np.ndarray
        Estimated state sequence in {+1, -1}.
    fitError : np.ndarray
        Squared error per sample of the chosen trajectory.
    BIC_ar : float
        BIC-like score.
    """
    S = np.asarray(S, dtype=float).ravel()
    T = S.size
    if n < 2:
        raise ValueError("n must be >= 2")
    if T < n:
        raise ValueError("Length of S must be at least n")

    C1 = S1 * (1.0 - B1)
    C2 = S2 * (1.0 - B2)

    # --- Build the switch matrix 'smat' (rows = switch patterns over n-1 steps) ---
    # MATLAB builds:
    #   start with all-false row;
    #   then for each (i,j) in 1..n-1, set those positions true (i==j -> 1 switch; i!=j -> 2 switches).
    # This yields all patterns with 0, 1, or 2 switch points.
    m = n - 1
    smat_rows = [np.zeros(m, dtype=bool)]
    idx = np.arange(m)
    for i in range(m):
        for j in range(m):
            temp = np.zeros(m, dtype=bool)
            temp[[i, j]] = True
            smat_rows.append(temp)
    smat = np.stack(smat_rows, axis=0)         # shape: (ntraj, m)
    ntraj = smat.shape[0]

    # --- Construct state trajectory matrices for starting in +1 and starting in -1 ---
    # stmat1/2 each have shape (ntraj, m), representing states for steps 1..(n-1)
    # where column t corresponds to state used to transition from time t to t+1.
    stmat1 = np.ones_like(smat, dtype=int)     # start in +1
    stmat1[smat[:, 0], 0] *= -1
    for t in range(1, m):
        stmat1[smat[:, t], t] = -stmat1[smat[:, t], t-1]
        stmat1[~smat[:, t], t] =  stmat1[~smat[:, t], t-1]

    stmat2 = -np.ones_like(smat, dtype=int)    # start in -1
    stmat2[smat[:, 0], 0] *= -1
    for t in range(1, m):
        stmat2[smat[:, t], t] = -stmat2[smat[:, t], t-1]
        stmat2[~smat[:, t], t] =  stmat2[~smat[:, t], t-1]

    # --- Outputs ---
    fitState = np.ones(T, dtype=int)   # default +1
    fitError = np.zeros(T, dtype=float)

    fitS = np.zeros(T, dtype=float)
    fitS[0] = S[0]  # initialize with first data point

    # Window starts: MATLAB uses 1:(n-1):T-n (1-based). In 0-based:
    winstarts = list(range(0, T - n + 1, n - 1))

    # --- Slide ---
    for wstart in winstarts:
        dat = S[wstart : wstart + n]  # n samples

        # Pick trajectory set based on current state's value at window start
        stmat = stmat1 if fitState[wstart] == 1 else stmat2  # shape (ntraj, n-1)

        # Simulate all trajectories (vectorized)
        simset = np.empty((ntraj, n), dtype=float)
        simset[:, 0] = fitS[wstart]  # previous chosen fit value at window start

        # For each step t=1..n-1 (MATLAB's 2..n), use state at t-1 (stmat[:, t-1])
        for t in range(1, n):
            prev = simset[:, t-1]
            # where state == +1, apply (B1, C1); where -1, apply (B2, C2)
            s_prev = stmat[:, t-1]
            pos = (s_prev == 1)
            neg = ~pos
            nxt = np.empty_like(prev)
            nxt[pos] = B1 * prev[pos] + C1
            nxt[neg] = B2 * prev[neg] + C2
            simset[:, t] = nxt

        # Choose best trajectory by RMSE over the window
        allerr = (simset - dat)**2                              # (ntraj, n)
        rmse = np.sqrt(np.mean(allerr, axis=1))
        best = np.argmin(rmse)

        # Write back chosen state, error, and fit
        # states for times (wstart+1 .. wstart+n-1) come from stmat row (length n-1)
        fitState[wstart+1 : wstart+n] = stmat[best, :]
        fitError[wstart : wstart+n] = allerr[best, :]
        fitS[wstart : wstart+n] = simset[best, :]

    # Count switches from ±1 sequence
    d = np.diff(fitState)
    num_switches = int(np.sum(np.abs(d) == 2))

    # BIC-like score (same formula as MATLAB)
    k_ar = num_switches + 2
    NN = fitError.size
    # guard against tiny/zero mean error
    #mse = float(np.mean(fitError)) if np.mean(fitError) > 0 else np.finfo(float).tiny
    BIC_ar =_bic_from_resid(fitError, k_params=k_ar)
    #BIC_ar = NN * math.log(mse) + math.log(NN) * k_ar

    # --- Optional plotting (roughly mirrors MATLAB) ---
    if plotflag:
        if ax is None:
            fig, (ax1, ax2, ax3) = plt.subplots(3, 1, sharex=True, num=20, figsize=(10, 7))
        else:
            ax1, ax2, ax3 = ax

        ax1.plot(S, lw=1)
        ax1.plot(fitS, ".", ms=3)
        ax1.plot(winstarts, S[np.array(winstarts)], "*")
        ax1.set_xlim(0, max(1, T - 100))
        ax1.set_title("Signal and fit")

        ax2.plot(fitState, "o-", ms=3)
        ax2.set_ylim(-2, 2)
        ax2.set_xlim(0, max(1, T - 100))
        ax2.set_title("State (+1 / -1)")

        ax3.plot(fitError, "o-", ms=3)
        ax3.set_xlim(0, max(1, T - 100))
        ax3.set_title("Squared error")

        plt.tight_layout()

    return fitS, fitState, fitError, BIC_ar

def _bic_from_resid(resid, k_params=4):
    resid = np.asarray(resid, float)
    m = np.isfinite(resid)
    r = resid[m]
    n = r.size
    if n == 0: return np.inf
    mse = np.mean(r*r)
    if mse <= 0: mse = 1e-18
    return n*np.log(mse) + k_params*np.log(n)
def two_model_fit_lin(S, n, s1, s2, plotflag=False, ax=None):
    """
    Linear two-model sliding-window fit (Python version of twoModelFitLin).

    Models:
      state = +1  ->  x[t] = s1 * t + b   (slope s1)
      state = -1  ->  x[t] = s2 * t + b   (slope s2)
    For each contiguous segment of constant state, b is chosen to ensure
    continuity with the previous point/segment (or the data's first value
    at the very beginning). Among all trajectories with up to 2 switches
    in the window, picks the one with minimal RMSE.

    Parameters
    ----------
    S : array_like
        1D time series (length T).
    n : int
        Window length (>= 2). Window step is (n-1).
    s1, s2 : float
        Slopes for the +1 (rise) and -1 (fall) states.
    plotflag : bool, optional
        If True, produce diagnostic plots (matplotlib).
    ax : tuple(matplotlib.axes.Axes, matplotlib.axes.Axes, matplotlib.axes.Axes) or None
        Optional axes to plot into when plotflag=True.

    Returns
    -------
    fitSL : ndarray
        Best-fit reconstructed signal, length T.
    fitErrorL : ndarray
        Squared error per-sample for the chosen trajectory, length T.
    fitStateL : ndarray
        Estimated state sequence in {+1, -1}, length T.
    BIC_lin : float
        BIC-like score as in the MATLAB code.
    """
    S = np.asarray(S, dtype=float).ravel()
    T = S.size
    if n < 2:
        raise ValueError("n must be >= 2")
    if T < n:
        raise ValueError("Length of S must be at least n")

    # --- Build switch patterns (smat) over the n-1 transitions ---
    m = n - 1
    smat_rows = [np.zeros(m, dtype=bool)]  # no switches
    for i in range(m):
        for j in range(m):
            temp = np.zeros(m, dtype=bool)
            temp[[i, j]] = True            # i==j -> 1 switch; i!=j -> 2 switches
            smat_rows.append(temp)
    smat = np.stack(smat_rows, axis=0)     # shape (ntraj, m)
    ntraj = smat.shape[0]

    # --- State trajectory matrices (start in +1 or -1) ---
    stmat1 = np.ones_like(smat, dtype=int)
    stmat1[smat[:, 0], 0] *= -1
    for t in range(1, m):
        stmat1[smat[:, t], t] = -stmat1[smat[:, t], t-1]
        stmat1[~smat[:, t], t] =  stmat1[~smat[:, t], t-1]

    stmat2 = -np.ones_like(smat, dtype=int)
    stmat2[smat[:, 0], 0] *= -1
    for t in range(1, m):
        stmat2[smat[:, t], t] = -stmat2[smat[:, t], t-1]
        stmat2[~smat[:, t], t] =  stmat2[~smat[:, t], t-1]

    # --- Outputs ---
    fitErrorL = np.zeros(T, dtype=float)
    fitStateL = np.ones(T, dtype=int)          # default +1
    fitSL     = np.zeros(T, dtype=float)

    # Window starts (0-based): 0, n-1, 2(n-1), ...
    winstarts = list(range(0, T - n + 1, n - 1))
    tvec = np.arange(n)

    last_val = None  # will be set after first chosen trajectory
    for wstart in winstarts:
        dat = S[wstart : wstart + n]

        # pick state matrix based on last state's value at window start
        stmat = stmat1 if fitStateL[wstart] == 1 else stmat2

        linsimset = np.zeros((ntraj, n), dtype=float)

        # simulate each trajectory with piecewise-linear segments
        for traj in range(ntraj):
            pattern = stmat[traj, :]                 # length n-1
            pattern = np.append(pattern, pattern[-1])# extend to length n
            xfit = np.zeros(n, dtype=float)

            # change points for state (segment boundaries)
            change_pts = np.concatenate(([0], np.where(np.diff(pattern) != 0)[0] + 1, [n]))

            for seg in range(len(change_pts) - 1):
                idx_start = change_pts[seg]
                idx_end   = change_pts[seg + 1]      # exclusive
                idx_range = np.arange(idx_start, idx_end)

                t_seg = tvec[idx_range]
                y_seg = dat[idx_range]
                state = pattern[idx_start]

                # Determine offset for continuity
                if wstart == 0 and seg == 0:
                    # first window, first segment: start from the data value
                    offset_val = y_seg[0]
                elif seg == 0 and last_val is not None:
                    # first segment in new window: continue from previous window's end
                    offset_val = last_val
                else:
                    # continue from previous point within this window
                    offset_val = xfit[idx_start - 1]

                slope = s1 if state == 1 else s2
                # y = slope * t + b, with continuity at t0 -> b = offset_val - slope*t0
                t0 = t_seg[0]
                b  = offset_val - slope * t0
                xfit[idx_range] = slope * t_seg + b

            linsimset[traj, :] = xfit

        # choose best trajectory by RMSE
        errs = (linsimset - dat)**2
        rmse = np.sqrt(np.mean(errs, axis=1))
        best = int(np.argmin(rmse))

        last_val = linsimset[best, -1]
        fitSL[wstart : wstart + n] = linsimset[best, :]
        fitErrorL[wstart : wstart + n] = errs[best, :]
        fitStateL[wstart + 1 : wstart + n] = stmat[best, :]

    # switches and BIC-like metric
    # dd = np.diff(fitStateL)
    # num_switchesL = int(np.sum(np.abs(dd) == 2))
    # k_lin = num_switchesL + 2
    # NN = fitErrorL.size
    # mse = float(np.mean(fitErrorL)) if np.mean(fitErrorL) > 0 else np.finfo(float).tiny
    # BIC_lin = NN * math.log(mse) + math.log(NN) * k_lin
    d = np.diff(fitStateL)
    num_switches = int(np.sum(np.abs(d) == 2))

    # BIC-like score (matching MATLAB formula)
    k_ar = num_switches + 2
    NN = fitStateL.size
    BIC_lin = _bic_from_resid(fitErrorL, k_params=k_ar)

    # optional plotting
    if plotflag:
        if ax is None:
            fig, (ax1, ax2, ax3) = plt.subplots(3, 1, sharex=True, num=20, figsize=(10, 7))
        else:
            ax1, ax2, ax3 = ax

        ax1.plot(S, lw=1)
        ax1.plot(fitSL, ".k", ms=3)
        ax1.plot(winstarts, S[np.array(winstarts)], "*")
        ax1.set_xlim(0, max(1, T - 100))
        ax1.set_title("Signal and linear fit")

        ax2.plot(fitStateL, "o-", ms=3)
        ax2.set_ylim(-2, 2)
        ax2.set_xlim(0, max(1, T - 100))
        ax2.set_title("State (+1/-1)")

        ax3.plot(fitErrorL, "*-", ms=3)
        ax3.set_xlim(0, max(1, T - 100))
        ax3.set_title("Squared error")

        plt.tight_layout()

    return fitSL, fitStateL, fitErrorL, BIC_lin

def _movmean_matlab_shrink(x, w):
    """
    MATLAB-like movmean(x, w) with Endpoints='shrink' and centered window.
    For even w, the window is biased one sample to the right (like MATLAB).
    """
    x = np.asarray(x, dtype=float).ravel()
    n = x.size
    if w <= 1 or n == 0:
        return x.copy()

    left = (w - 1) // 2          # floor((w-1)/2)
    right = w // 2                # ceil((w-1)/2)

    idx = np.arange(n)
    starts = np.maximum(0, idx - left)
    ends   = np.minimum(n, idx + right + 1)    # exclusive

    csum = np.concatenate(([0.0], np.cumsum(x)))
    counts = ends - starts
    out = (csum[ends] - csum[starts]) / counts
    return out

def gmm_cluster_pka(signalLT, win=40, num_clusters=3, reg_covar=1e-8,
                    max_iter=1000, replicates=5, plotflag=False, fig = None, ax=None,
                    random_state=None):
    """
    Gaussian Mixture clustering of (PKA, d(PKA)/dt):

      x = movmean(signalLT, win)           # Endpoints='shrink'
      y = [diff(x), 0]                     # first element is x[1]-x[0], last is 0
      X = zscore([x y])                    # column-wise, ddof=1 (MATLAB)
      Fit GMM with reg value, reps, etc.

    Returns
    -------
    labels : (N,) int array in {1..K}
    gm     : fitted GaussianMixture
    Xz     : (N,2) z-scored features
    x      : smoothed signal
    y      : derivative with trailing 0
    """
    signalLT = np.asarray(signalLT, dtype=float).ravel()
    N = signalLT.size
    if N == 0:
        raise ValueError("signalLT is empty")
    if win < 1:
        raise ValueError("win must be >= 1")

    # --- MATLAB-like movmean with shrinking edges
    x = _movmean_matlab_shrink(signalLT, win)

    # --- Exact MATLAB diff padding: [diff(x), 0]
    y = np.empty_like(x)
    y[:-1] = np.diff(x)
    y[-1] = 0.0

    # --- zscore each column with ddof=1 to match MATLAB's std
    X = np.column_stack([x, y])
    Xz = zscore(X, axis=0, ddof=1)

    # --- Fit GMM (replicates -> n_init)
    gm = GaussianMixture(
        n_components=num_clusters,
        covariance_type="full",
        reg_covar=reg_covar,
        max_iter=max_iter,
        n_init=replicates,
        random_state=random_state
    ).fit(Xz)

    # Labels as 1..K (MATLAB-style)
    labels = gm.predict(Xz) + 1

    # --- Optional plot with distinct legend colors
    if plotflag:
        if ax is None:
            fig, ax = plt.subplots()
        colors = plt.cm.tab10(np.linspace(0, 1, num_clusters))
        for k in range(1, num_clusters + 1):
            m = labels == k
            ax.scatter(Xz[m, 0], Xz[m, 1], s=12, label=f"Cluster {k}", alpha=0.2)
        ax.set_xlabel("PKA (z-scored)")
        ax.set_ylabel("d(PKA)/dt (z-scored)")
        ax.set_title("GMM Clustering on PKA vs d(PKA)")
        ax.legend(loc="best")
        plt.tight_layout()
        return (fig, ax), labels
    return labels

def remove_fast_state(state, min_length, target_state):
    """
    Replace runs of `target_state` shorter than `min_length` with the
    neighboring state (prefer previous; if at start, use next).
    Shape and dtype are preserved.

    Parameters
    ----------
    state : array_like
        1D or ND array of integer/float labels (e.g., 1=AWAKE, 2=SLEEP, 4=MICRO).
    min_length : int
        Minimum allowed run length (in samples).
    target_state : int or float
        The specific state to clean (e.g., 4 for MICROAROUSAL).

    Returns
    -------
    new_state : ndarray
        Same shape as `state`, with short target runs replaced.
    """
    arr = np.asarray(state)
    flat = arr.ravel()
    n = flat.size
    if n == 0:
        return arr.copy()

    # --- Find contiguous segments without sentinels ---
    # changes marks boundaries (include first and last)
    changes = np.flatnonzero(np.r_[True, np.diff(flat) != 0, True])
    starts = changes[:-1]
    ends   = changes[1:] - 1
    labels = flat[starts]

    out = flat.copy()
    for s, e, lab in zip(starts, ends, labels):
        if lab != target_state:
            continue
        seg_len = e - s + 1
        if seg_len < min_length:
            if s > 0:
                replacement = out[s - 1]
            elif e < n - 1:
                replacement = out[e + 1]
            else:
                # Edge case: entire array is a short run of target_state
                continue
            out[s:e+1] = replacement

    return out.reshape(arr.shape)

pd.set_option("display.max_columns", 120)

# ==== 1) Small utilities ====
def to_abs_seconds(dt_series: pd.Series) -> np.ndarray:
    """Datetime64 -> float seconds since epoch (handles tz or naive)."""
    s = pd.to_datetime(dt_series)
    return s.view("int64") / 1e9

def infer_fs(t_abs: np.ndarray) -> float:
    d = np.diff(t_abs)
    d = d[np.isfinite(d) & (d > 0)]
    return 1.0 / np.median(d) if len(d) else np.nan

def bandpower_from_psd(freqs, psd, fmin, fmax):
    m = (freqs >= fmin) & (freqs < fmax)
    return float(np.trapz(psd[m], freqs[m])) if np.any(m) else np.nan

def spectral_edge(freqs, psd, edge=0.95, fmin=0.5, fmax=30.0):
    m = (freqs >= fmin) & (freqs <= fmax)
    if not np.any(m): return np.nan
    f, p = freqs[m], psd[m]
    cum = np.cumsum(p)
    if cum[-1] <= 0: return np.nan
    target = edge * cum[-1]
    idx = int(np.clip(np.searchsorted(cum, target), 0, len(f)-1))
    return float(f[idx])

def spectral_slope(freqs, psd, fmin=1.0, fmax=30.0):
    m = (freqs >= fmin) & (freqs <= fmax) & (psd > 0)
    if np.sum(m) < 5: return np.nan
    xf = np.log(freqs[m]); yf = np.log(psd[m])
    b1, b0 = polyfit(xf, yf, 1)  # returns [b0, b1]
    return float(b1)

def trailing_welch_features(t_abs, x, t_grid, win_s=30.0, fs=None, suffix=""):
    """Causal trailing Welch PSD features at each t_grid point."""
    if fs is None or not np.isfinite(fs):
        fs = infer_fs(t_abs)
    if not np.isfinite(fs):
        raise ValueError("Cannot infer sampling rate for EEG/EMG stream.")
    nperseg = max(int(min(max(2.0, win_s/2.0) * fs, win_s * fs)), 16)
    noverlap = nperseg // 2

    cols = ['delta','theta','alpha','beta','gamma','theta_over_delta','sef95','spec_slope']
    out = {f"{c}{suffix}": [] for c in cols}

    i0 = 0
    for tg in t_grid:
        t_start = tg - win_s
        while i0 < len(t_abs) and t_abs[i0] < t_start:
            i0 += 1
        i1 = i0
        while i1 < len(t_abs) and t_abs[i1] < tg:
            i1 += 1

        if i1 - i0 < int(0.5 * win_s * fs):
            vals = [np.nan]*8
        else:
            seg = x[i0:i1]
            f, pxx = welch(seg, fs=fs, nperseg=min(nperseg, len(seg)), noverlap=min(noverlap, len(seg)//2))
            bp_delta = bandpower_from_psd(f, pxx, 0.5, 4)
            bp_theta = bandpower_from_psd(f, pxx, 4, 8)
            bp_alpha = bandpower_from_psd(f, pxx, 8, 12)
            bp_beta  = bandpower_from_psd(f, pxx, 12, 30)
            bp_gamma = bandpower_from_psd(f, pxx, 30, 80)
            tod = bp_theta / bp_delta if (bp_delta is not None and bp_delta > 0) else np.nan
            sef = spectral_edge(f, pxx, edge=0.95, fmin=0.5, fmax=30)
            slope = spectral_slope(f, pxx, fmin=1.0, fmax=30)
            vals = [bp_delta, bp_theta, bp_alpha, bp_beta, bp_gamma, tod, sef, slope]

        for k, v in zip(cols, vals):
            out[f"{k}{suffix}"].append(v)
    df_feats = pd.DataFrame(out, index=pd.Index(t_grid, name='t_abs'))
    return df_feats.reset_index(drop=True) 

def trailing_emg_rms(t_abs, emg, t_grid, win_s, fs=None):
    if fs is None or not np.isfinite(fs):
        fs = infer_fs(t_abs)
    out = {'emg_rms': []}
    i0 = 0
    for tg in t_grid:
        t_start = tg - win_s
        while i0 < len(t_abs) and t_abs[i0] < t_start:
            i0 += 1
        i1 = i0
        while i1 < len(t_abs) and t_abs[i1] < tg:
            i1 += 1
        if i1 - i0 < max(8, int(0.5 * win_s * (fs if np.isfinite(fs) else 100))):
            out['emg_rms'].append(np.nan)
        else:
            seg = emg[i0:i1]
            out['emg_rms'].append(float(np.sqrt(np.mean(seg**2))))
    df_feats = pd.DataFrame(out, index=pd.Index(t_grid, name='t_abs'))
    return df_feats.reset_index(drop=True)  # <- important: RangeIndex

def discretize_pka_states(t_abs, P2, smooth_s=30.0, slope_win_s=20.0,
                          rise_thr=None, fall_thr=None, min_dwell_s=20.0):
    """Simple slope+Hysteresis: {1=Awake, 2=Fall, 4=Rise}."""
    dt = np.median(np.diff(t_abs[np.isfinite(t_abs)]))
    if not np.isfinite(dt) or dt <= 0:
        raise ValueError("Bad P2 timebase.")
    k = max(1, int(smooth_s / dt))
    P2_sm = uniform_filter1d(P2.astype(float), size=k, mode='nearest', origin=-(k//2))
    k2 = max(1, int(slope_win_s / dt))
    P2_sm_delayed = np.r_[ [P2_sm[0]]*k2, P2_sm[:-k2] ]
    slope = (P2_sm - P2_sm_delayed) / (k2 * dt)
    s_std = np.nanstd(slope)
    rise_thr = +0.25 * s_std if rise_thr is None else rise_thr
    fall_thr = -0.25 * s_std if fall_thr is None else fall_thr
    state = np.full_like(P2_sm, fill_value=1, dtype=int)
    state[slope >= rise_thr] = 4
    state[slope <= fall_thr] = 2
    # minimum dwell
    min_len = max(1, int(min_dwell_s / dt))
    d = np.diff(np.r_[np.nan, state, np.nan])
    brk = np.where(d != 0)[0]
    starts, ends = brk[:-1], brk[1:] - 1
    for s, e in zip(starts, ends):
        if (e - s + 1) < min_len:
            prev_state = state[s-1] if s-1 >= 0 else state[e+1]
            state[s:e+1] = prev_state
    return state, slope, P2_sm

# ==== 2) Core builder for ONE subject ====
def build_subject_dataset(
    dataLifeTime: pd.DataFrame,
    dataEEG: pd.DataFrame,
    dataSSD: pd.DataFrame = None,
    subject_id: str = "S1",
    session_id: str = "sess1",
    epoch_hz: float = 1.0,
    eeg_win_s: float = 20.0,
    emg_win_s: float = 8.0,
    compute_pka_states: bool = True
) -> pd.DataFrame:

    # --- pull raw arrays early (NumPy, not Series) ---
    t_pka = pd.to_datetime(dataLifeTime['Lifetime Time (s)']).view('int64').to_numpy() / 1e9
    P2    = dataLifeTime['P2'].to_numpy(dtype=float)

    t_eeg = pd.to_datetime(dataEEG['EEG Time (s)']).view('int64').to_numpy() / 1e9
    H     = dataEEG['EEG (Hippocampal Channel)'].to_numpy(dtype=float)
    F     = dataEEG['EEG (Frontal Channel)'].to_numpy(dtype=float)
    EMG   = dataEEG['EMG'].to_numpy(dtype=float)

    if dataSSD is not None:
        t_slp = pd.to_datetime(dataSSD['Sleep States Time (s)']).view('int64').to_numpy() / 1e9
        S     = dataSSD['Sleep States'].to_numpy()
    else:
        t_slp, S = None, None

    # --- common time grid ---
    spans = [(np.nanmin(t_pka), np.nanmax(t_pka)), (np.nanmin(t_eeg), np.nanmax(t_eeg))]
    if t_slp is not None:
        spans.append((np.nanmin(t_slp), np.nanmax(t_slp)))
    t_start = max(s[0] for s in spans)
    t_end   = min(s[1] for s in spans)
    if not (np.isfinite(t_start) and np.isfinite(t_end) and (t_end - t_start > 60)):
        raise ValueError(f"{subject_id}: insufficient overlap between streams.")
    step   = 1.0 / epoch_hz
    t_grid = np.arange(t_start, t_end + 1e-6, step)

    # --- interpolate P2 to grid ---
    P2_grid = np.interp(t_grid, t_pka, P2, left=np.nan, right=np.nan)

    # --- discretize PKA (optional) ---
    pka_state = np.full_like(P2_grid, np.nan)
    if compute_pka_states:
        mask = np.isfinite(P2_grid)
        if mask.sum() > 100:
            st, slope, P2_sm = discretize_pka_states(t_grid[mask], P2_grid[mask])
            pka_state[mask] = st

    # --- sleep nearest (pure NumPy; never Series) ---
    if t_slp is not None and len(t_slp) > 0:
        idx = np.searchsorted(t_slp, t_grid, side='left')
        idx = np.clip(idx, 0, len(t_slp)-1)
        left_idx  = np.maximum(idx - 1, 0)
        right_idx = idx
        dist_left  = np.abs(t_grid - t_slp[left_idx])
        dist_right = np.abs(t_grid - t_slp[right_idx])
        use_left   = (idx > 0) & (dist_left <= dist_right)
        chosen_idx = np.where(use_left, left_idx, right_idx)
        sleep_grid = S[chosen_idx]
    else:
        sleep_grid = np.full_like(P2_grid, np.nan)

    # --- features (each returns RangeIndex; we will row-concat) ---
    fs_eeg  = infer_fs(t_eeg)
    feats_F = trailing_welch_features(t_eeg, F, t_grid, win_s=eeg_win_s, fs=fs_eeg, suffix="_F")
    feats_H = trailing_welch_features(t_eeg, H, t_grid, win_s=eeg_win_s, fs=fs_eeg, suffix="_H")
    feats_E = trailing_emg_rms(t_eeg, EMG, t_grid, win_s=emg_win_s, fs=fs_eeg)

    # --- hard sanity: identical lengths for row-wise concat ---
    n = len(t_grid)
    assert len(feats_F) == n and len(feats_H) == n and len(feats_E) == n, \
        f"feature length mismatch: grid={n}, F={len(feats_F)}, H={len(feats_H)}, EMG={len(feats_E)}"

    # --- assemble base table (RangeIndex) ---
    df0 = pd.DataFrame({
        't_abs': t_grid,
        'animal': subject_id,
        'session': session_id,
        't': (t_grid - t_grid[0]).astype(float),
        'P2': P2_grid,
        'pka_state': pka_state,
        'sleep_state': sleep_grid
    })

    # --- row-wise concat (no index alignment) ---
    df = pd.concat([df0.reset_index(drop=True),
                    feats_F.reset_index(drop=True),
                    feats_H.reset_index(drop=True),
                    feats_E.reset_index(drop=True)], axis=1)

    # --- derived ratios (force NumPy to avoid label alignment) ---
    df['theta_over_delta'] = (df['theta_F'].to_numpy() / df['delta_F'].to_numpy())

    # --- clean rows with missing core features (purely row-based) ---
    core = ['P2','delta_F','theta_F','alpha_F','beta_F','gamma_F','emg_rms']
    df = df[~df[core].isna().any(axis=1)].reset_index(drop=True)

    # --- typed pka_state with nullable Int32 if computed ---
    if compute_pka_states:
        df['pka_state'] = pd.Series(df['pka_state'].to_numpy(), index=df.index, dtype='Int32')

    return df

# ==== 3) File discovery helpers ====
def find_triplets(root_dir):
    """
    Returns a list of dicts: [{'subject_id': '0005', 'lifetime': '...pkl', 'ssd': '...pkl', 'eeg': '...pkl'}].
    Assumes each subject has its *own folder* containing 3 PKLs with keywords:
    LifetimeData.pkl, SSData.pkl, EEGData.pkl
    """
    triplets = []
    for subject_dir in sorted([p for p in glob.glob(os.path.join(root_dir, "*")) if os.path.isdir(p)]):
        lif = glob.glob(os.path.join(subject_dir, "*LifetimeData.pkl"))
        ssd = glob.glob(os.path.join(subject_dir, "*SSData.pkl"))
        eeg = glob.glob(os.path.join(subject_dir, "*EEGData.pkl"))
        if not (lif and eeg):
            # If your sleep lives elsewhere, we still allow None
            if lif and eeg:
                pass
        subject_id = os.path.basename(subject_dir)
        triplets.append({
            "subject_id": subject_id,
            "lifetime": lif[0] if lif else None,
            "ssd": ssd[0] if ssd else None,
            "eeg": eeg[0] if eeg else None,
            "subject_dir": subject_dir
        })
    return triplets

# ==== 4) Loader for one subject from PKL paths ====
# --- replace load_subject_frames with this ---
def robust_pickle_load(path):
    import pickle, gzip, io
    with open(path, "rb") as f:
        data = f.read()

    # try plain pickle first
    for loader in (
        lambda b: pickle.loads(b),
        lambda b: pickle.loads(b, encoding="latin1"),
    ):
        try:
            return loader(data)
        except Exception:
            pass

    # try gzip-wrapped pickle (some systems compress .pkl silently)
    try:
        with gzip.GzipFile(fileobj=io.BytesIO(data)) as gz:
            blob = gz.read()
        for loader in (
            lambda b: pickle.loads(b),
            lambda b: pickle.loads(b, encoding="latin1"),
        ):
            try:
                return loader(blob)
            except Exception:
                pass
    except Exception:
        pass

    # last resort: pandas.read_pickle with latin1 (if available)
    try:
        return pd.read_pickle(io.BytesIO(data))
    except Exception:
        pass

    raise UnicodeDecodeError("pickle", b"", 0, 1, f"Cannot decode {path}")

def load_subject_frames(lifetime_pkl, eeg_pkl, ssd_pkl=None):
    dataLifeTime = robust_pickle_load(lifetime_pkl)
    dataEEG      = robust_pickle_load(eeg_pkl)
    dataSSD      = robust_pickle_load(ssd_pkl) if ssd_pkl else None

    # sanity: ensure DataFrames
    for name, df in (("Lifetime", dataLifeTime), ("EEG", dataEEG), ("Sleep", dataSSD)):
        if df is not None and not isinstance(df, pd.DataFrame):
            raise TypeError(f"{name} pickle is not a pandas DataFrame")

    # quick column checks (adjust if your real names differ)
    req_life = {'Lifetime Time (s)', 'P2'}
    req_eeg  = {'EEG Time (s)', 'EEG (Hippocampal Channel)', 'EEG (Frontal Channel)', 'EMG'}
    missing = []
    if not req_life.issubset(set(dataLifeTime.columns)): missing.append(("Lifetime", req_life - set(dataLifeTime.columns)))
    if not req_eeg.issubset(set(dataEEG.columns)): missing.append(("EEG", req_eeg - set(dataEEG.columns)))
    if missing:
        warnings.warn(f"Missing columns: {missing}")
    return dataLifeTime, dataEEG, dataSSD


# ==== 5) Batch process all subjects ====

def save_df(df, path_base, prefer="parquet", index=False):
    """
    Save df using the best available format.
    - prefer="parquet" tries pyarrow/fastparquet; else falls back to pickle, then csv.gz
    - path_base: without extension (e.g., './processed/pka_eeg_emg_1Hz')
    """
    prefer = (prefer or "").lower()
    if prefer == "parquet":
        engine = None
        try:
            import pyarrow  # noqa: F401
            engine = "pyarrow"
        except Exception:
            try:
                import fastparquet  # noqa: F401
                engine = "fastparquet"
            except Exception:
                engine = None
        if engine is not None:
            out = path_base + ".parquet"
            df.to_parquet(out, engine=engine, index=index)
            print(f"Saved Parquet ({engine}): {out}")
            return out

    # Fallback 1: Pickle (fast, Python-only)
    try:
        out = path_base + ".pkl"
        df.to_pickle(out, protocol=4)
        print(f"Saved Pickle: {out}")
        return out
    except Exception as e:
        print(f"Pickle save failed: {e}")

    # Fallback 2: CSV.gz (portable, larger)
    out = path_base + ".csv.gz"
    df.to_csv(out, index=index, compression="gzip")
    print(f"Saved CSV.gz: {out}")
    return out

def process_all_subjects(root_dir, epoch_hz=1.0, eeg_win_s=20.0, emg_win_s=10.0,
                         compute_pka_states=True, save_path=None):
    triplets = find_triplets(root_dir)
    frames = []
    for tri in triplets:
        sid = tri["subject_id"]
        lif, eeg, ssd = tri["lifetime"], tri["eeg"], tri["ssd"]
        if (lif is None) or (eeg is None):
            print(f"[skip] {sid}: missing lifetime/eeg file.")
            continue
        try:
            dataLifeTime, dataEEG, dataSSD = load_subject_frames(lif, eeg, ssd)
            df = build_subject_dataset(
                dataLifeTime=dataLifeTime,
                dataEEG=dataEEG,
                dataSSD=dataSSD,
                subject_id=sid,
                session_id="S1",
                epoch_hz=epoch_hz,
                eeg_win_s=eeg_win_s,
                emg_win_s=emg_win_s,
                compute_pka_states=compute_pka_states
            )
            frames.append(df)
            print(f"[ok] {sid}: n={len(df)} rows, span = {df['t'].iloc[-1]:.1f}s")
        except Exception as e:
            print(f"[error] {sid}: {e}")

    if not frames:
        raise RuntimeError("No subjects processed.")
    df_all = pd.concat(frames, ignore_index=True)
    if save_path:
        base, _ = os.path.splitext(save_path)
        save_df(df_all, base, prefer="parquet", index=False)
    # if save_path:
    #     os.makedirs(os.path.dirname(save_path), exist_ok=True)
    #     df_all.to_parquet(save_path, index=False)
    #     print(f"Saved: {save_path} ({len(df_all)} rows)")
    return df_all

def _zscore(x):
    x = np.asarray(x, dtype=float)
    m = np.nanmean(x); s = np.nanstd(x)
    return (x - m) / s if (np.isfinite(s) and s != 0) else np.zeros_like(x)

def _downsample(t, Y, max_points=6000):
    n = len(t)
    if n <= max_points:
        return t, Y
    step = int(np.ceil(n / max_points))
    idx = np.arange(0, n, step)
    return t[idx], [y[idx] if len(y) == n else y for y in Y]

def _plot_overlapped_lines(t, series_dict, title, z=True, rolling=None, max_points=6000):
    labels, arrays = zip(*[(k, np.asarray(v, dtype=float)) for k, v in series_dict.items()])
    t_ds, arrays_ds = _downsample(t, list(arrays), max_points=max_points)
    proc = []
    for a in arrays_ds:
        b = _zscore(a) if z else a.astype(float)
        if rolling and rolling > 1:
            k = np.ones(rolling) / float(rolling)
            b = np.convolve(b, k, mode='same')
        proc.append(b)
    plt.figure()
    for lab, arr in zip(labels, proc):
        plt.plot(t_ds, arr, label=lab)
    plt.xlabel("Time (s)")
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.show()

def _plot_step_states(t, states_dict, title, max_points=10000):
    labels, arrays = zip(*[(k, pd.to_numeric(v, errors='coerce').to_numpy(dtype=float)) for k, v in states_dict.items()])
    t_ds, arrays_ds = _downsample(t, list(arrays), max_points=max_points)
    plt.figure()
    for lab, arr in zip(labels, arrays_ds):
        plt.plot(t_ds, arr, label=lab, drawstyle='steps-post')
    plt.xlabel("Time (s)")
    plt.title(title)
    plt.legend()
    plt.tight_layout()
    plt.show()

def plot_sanity(df):
    """Plot overlapped variables for a quick alignment/causality sanity check."""
    df = df.sort_values('t').reset_index(drop=True).copy()
    df['t'] = df['t'] - df['t'].iloc[0]
    t = df['t'].to_numpy()

    # 1) P2 (keep raw units)
    if 'P2' in df.columns:
        _plot_overlapped_lines(t, {"P2": df['P2'].to_numpy()},
                               title="P2 over time (raw units)",
                               z=False, rolling=None)

    # 2) States (step lines)
    states = {}
    if 'pka_state' in df.columns:
        states['pka_state'] = df['pka_state']
    if 'sleep_state' in df.columns:
        states['sleep_state'] = df['sleep_state']
    if states:
        _plot_step_states(t, states, title="States over time (pka_state and/or sleep_state)")

    # 3) EEG bands (Frontal) — z-scored
    bands_F = [c for c in ['delta_F','theta_F','alpha_F','beta_F','gamma_F'] if c in df.columns]
    if bands_F:
        _plot_overlapped_lines(t, {c: df[c].to_numpy() for c in bands_F},
                               title="EEG bandpowers (Frontal) — z-scored overlap",
                               z=True, rolling=5)

    # 4) EEG extras (Frontal) — z-scored
    extras_F = [c for c in ['theta_over_delta','sef95_F','spec_slope_F'] if c in df.columns]
    if extras_F:
        _plot_overlapped_lines(t, {c: df[c].to_numpy() for c in extras_F},
                               title="EEG extras (Frontal): θ/δ, SEF95, spectral slope — z-scored overlap",
                               z=True, rolling=5)

    # 5) EMG RMS — z-scored
    if 'emg_rms' in df.columns:
        _plot_overlapped_lines(t, {"emg_rms": df['emg_rms'].to_numpy()},
                               title="EMG RMS — z-scored",
                               z=True, rolling=5)

    # 6) (Optional) Hippocampal bands/extras if present
    bands_H = [c for c in ['delta_H','theta_H','alpha_H','beta_H','gamma_H'] if c in df.columns]
    if bands_H:
        _plot_overlapped_lines(t, {c: df[c].to_numpy() for c in bands_H},
                               title="EEG bandpowers (Hippocampal) — z-scored overlap",
                               z=True, rolling=5)

    extras_H = [c for c in ['sef95_H','spec_slope_H'] if c in df.columns]
    if extras_H:
        _plot_overlapped_lines(t, {c: df[c].to_numpy() for c in extras_H},
                               title="EEG extras (Hippocampal) — z-scored overlap",
                               z=True, rolling=5)

# ---- usage: replace df_base with your dataframe variable name
# plot_sanity(df_base)

def add_causal_lags_and_stats(df, cols, lags=(1,2,3,6,9,12), win_steps=(5,10,15)):
    df = df.sort_values('t').reset_index(drop=True).copy()
    for c in cols:
        if c not in df.columns: 
            continue
        for L in lags:
            df[f'{c}_lag{L}'] = df[c].shift(L)
        for w in win_steps:
            df[f'{c}_mean_{w}'] = df[c].rolling(w, min_periods=w).mean()
            df[f'{c}_std_{w}']  = df[c].rolling(w, min_periods=w).std()
    # Drop rows with any NaNs introduced by lags/rolling (predictors only)
    new_cols = [k for k in df.columns if any(k.startswith(c) for c in cols) and k not in cols]
    keep = ~df[new_cols].isna().any(axis=1)
    out = df.loc[keep].reset_index(drop=True)
    # Rebase time to start at 0 (purely cosmetic)
    out['t'] = out['t'] - out['t'].iloc[0]
    return out

def fit_animal(P2, n_global=2000, top_k=30, loss_kind="huber", fit_bin = 40):
    bnd = make_bounds(P2)
    # Sobol samples in unit cube → scale to bounds
    sampler = qmc.Sobol(d=4, scramble=True)
    U = sampler.random_base2(int(np.ceil(np.log2(n_global))))[:n_global]
    # ranges
    B1_lo, B1_hi = np.log(bnd["B1"][0]), np.log(bnd["B1"][1])
    B2_lo, B2_hi = np.log(bnd["B2"][0]), np.log(bnd["B2"][1])
    S1_lo, S1_hi = bnd["S1"]; S2_lo, S2_hi = bnd["S2"]
    # scale
    thetas = np.column_stack([
        B1_lo + U[:,0]*(B1_hi - B1_lo),
        B2_lo + U[:,1]*(B2_hi - B2_lo),
        S1_lo + U[:,2]*(S1_hi - S1_lo),
        S2_lo + U[:,3]*(S2_hi - S2_lo),
    ])

    # evaluate global candidates
    losses = np.array([objective(th, P2, bnd, loss_kind,fit_bin) for th in thetas])
    idx = np.argsort(losses)[:top_k]
    seeds = thetas[idx]

    # local refinement (bounded)
    results = []
    for th0 in seeds:
        # bounds in transformed space
        bounds_opt = [(B1_lo, B1_hi), (B2_lo, B2_hi), (S1_lo, S1_hi), (S2_lo, S2_hi)]
        res = minimize(objective, th0,
                       args=(P2, bnd, loss_kind,fit_bin),
                       method="L-BFGS-B", bounds=bounds_opt,
                       options=dict(maxiter=300, ftol=1e-8))
        results.append(res)

    # pick best local
    best = min(results, key=lambda r: r.fun)
    logB1, logB2, S1, S2 = best.x
    pars = dict(B1=float(np.exp(logB1)), B2=float(np.exp(logB2)),
                S1=float(S1), S2=float(S2), loss=float(best.fun))
    return pars, best, bnd, (thetas, losses)

def get_fit_range(FLP_exp, wake_threshold = 0.9, window_length = 900, window_slide = 5, 
                    all_states_flag = True, wake_threshold_flag = True, min_flag = True, max_flag = True):
    pass_idx = []
    bnds = make_bounds(FLP_exp.Lifetime)
    S1 = bnds['S1']
    time_ranges = []
    adj_wake_thresh = wake_threshold
    while (len(time_ranges) == 0) & (adj_wake_thresh > 0):
        for b in range(0, len(FLP_exp.SleepStates)-window_length, window_slide):
            SS_seg = FLP_exp.SleepStates[b:b+window_length]
            LFT_seg = FLP_exp.Lifetime[(FLP_exp.Time >= FLP_exp.SSTime[b]) & (FLP_exp.Time < FLP_exp.SSTime[b+window_length])]
            if (1 in SS_seg) & (2 in SS_seg) & (3 in SS_seg):
                if len(SS_seg[SS_seg != 1])/len(SS_seg) > adj_wake_thresh:
                    if any(LFT_seg < S1[0]) & any(LFT_seg > S1[1]):
                        pass_idx.append(b)
        time_ranges = [[FLP_exp.SSTime[r], FLP_exp.SSTime[r+window_length]] for r in pass_idx]
        adj_wake_thresh = adj_wake_thresh-0.1
    if len(time_ranges) > 0:
        return time_ranges
    
    else:
        for b in range(0, len(FLP_exp.SleepStates)-window_length, window_slide):
            SS_seg = FLP_exp.SleepStates[b:b+window_length]
            LFT_seg = FLP_exp.Lifetime[(FLP_exp.Time >= FLP_exp.SSTime[b]) & (FLP_exp.Time < FLP_exp.SSTime[b+window_length])]
            if (1 in SS_seg) & (2 in SS_seg) & (3 in SS_seg):
                if any(LFT_seg < S1[0]) & any(LFT_seg > S1[1]):
                    pass_idx.append(b)
        time_ranges = [[FLP_exp.SSTime[r], FLP_exp.SSTime[r+window_length]] for r in pass_idx]
    
    if len(time_ranges) > 0:
        return time_ranges
    else:
        adj_wake_thresh = wake_threshold
        while (len(time_ranges) == 0) & (adj_wake_thresh > 0):
            for b in range(0, len(FLP_exp.SleepStates)-window_length, window_slide):
                SS_seg = FLP_exp.SleepStates[b:b+window_length]
                LFT_seg = FLP_exp.Lifetime[(FLP_exp.Time >= FLP_exp.SSTime[b]) & (FLP_exp.Time < FLP_exp.SSTime[b+window_length])]
                if (1 in SS_seg) & (2 in SS_seg) & (3 in SS_seg):
                    if len(SS_seg[SS_seg != 1])/len(SS_seg) > adj_wake_thresh:
                        pass_idx.append(b)
            time_ranges = [[FLP_exp.SSTime[r], FLP_exp.SSTime[r+window_length]] for r in pass_idx]
            adj_wake_thresh = adj_wake_thresh-0.1
    if len(time_ranges) > 0:
        return time_ranges
    else:
        print('No suitable time range')
        return time_ranges

def clip_wake(sleep_states, slide = 1, thresh = 0.2, max_length = 5400):
    min_perc = len(np.where(sleep_states == 1)[0])/len(sleep_states)
    target_len = max_length
    slide_starts = np.arange(0, len(sleep_states)-target_len, slide)
    percs = [len(np.where(sleep_states[s:s+target_len] == 1)[0])/len(sleep_states[s:s+target_len]) for s in slide_starts]
    min_perc = np.min(percs)
    min_perc_idx = np.argmin(percs)
    idx_range = [slide_starts[min_perc_idx], slide_starts[min_perc_idx]+target_len]
    while min_perc > thresh:
        target_len = int(target_len*.9)
        if target_len > 0:
            slide_starts = np.arange(0, len(sleep_states)-target_len, slide)
            percs = [len(np.where(sleep_states[s:s+target_len] == 1)[0])/len(sleep_states[s:s+target_len]) for s in slide_starts]
            min_perc = np.min(percs)
            min_perc_idx = np.argmin(percs)
            idx_range = [slide_starts[min_perc_idx], slide_starts[min_perc_idx]+target_len]
        else:
            return 0
    return idx_range

# ------------------ 1) robust scalar loss from error series ------------------
def loss_from_err(err, kind="huber", delta=0.01):
    err = np.asarray(err, float)
    err = err[np.isfinite(err)]
    if err.size == 0:
        return np.inf
    if kind == "mae":
        return np.median(np.abs(err))  # robust
    elif kind == "mse":
        return np.mean(err**2)
    elif kind == "huber":
        ae = np.abs(err)
        quad = np.minimum(ae, delta)
        lin  = ae - quad
        return np.mean(0.5*(quad/delta)**2 + lin)
    else:
        raise ValueError("unknown kind")

# Wrapper: parameters -> scalar loss
def objective(theta, P2, bounds, loss_kind="huber", fit_bin = 40):
    # theta in transformed space: [logB1, logB2, S1, S2]
    logB1, logB2, S1, S2 = theta
    B1 = np.exp(logB1)
    B2 = np.exp(logB2)
    # clip to bounds softly (avoid numerical blowups)
    B1 = np.clip(B1, bounds["B1"][0], bounds["B1"][1])
    B2 = np.clip(B2, bounds["B2"][0], bounds["B2"][1])
    S1 = np.clip(S1, bounds["S1"][0], bounds["S1"][1])
    S2 = np.clip(S2, bounds["S2"][0], bounds["S2"][1])
    #two_model_fit(S, n, B1, S1, B2, S2, plotflag=False, ax=None)
    fitS, fitState, err_t, BIC_ar = two_model_fit(P2,fit_bin, 1-1/B1, S1, 1-1/B2, S2,0)  # our function
    return loss_from_err(err_t, kind=loss_kind)

# ------------------ 2) bounds (data-driven) ------------------
#  B_range_s=(1.0, 600.0) sets the range of B1 and B2 on the search
# the bounds of S1 and S2 are defined based on the statistics of the P2 signal
def make_bounds(P2, B_range_s=(1.0, 600.0), pad=0.02):
    p2 = np.asarray(P2, float)
    p2 = p2[np.isfinite(p2)]
    lo, hi = np.quantile(p2, [0.01, 0.99])
    span = hi - lo
    Slo = lo - pad*span
    Shi = hi + pad*span
    return {
        "B1": (B_range_s[0], B_range_s[1]),
        "B2": (B_range_s[0], B_range_s[1]),
        "S1": (Slo, Shi),
        "S2": (Slo, Shi)
    }

# transforms to/from the optimizer vector
def to_theta(logB1, logB2, S1, S2): return np.array([logB1, logB2, S1, S2], float)

# ------------------ 3) global → local search per animal ------------------
def fit_animal(P2, n_global=2000, top_k=30, loss_kind="huber", fit_bin = 40):
    bnd = make_bounds(P2)
    # Sobol samples in unit cube → scale to bounds
    sampler = qmc.Sobol(d=4, scramble=True)
    U = sampler.random_base2(int(np.ceil(np.log2(n_global))))[:n_global]
    # ranges
    B1_lo, B1_hi = np.log(bnd["B1"][0]), np.log(bnd["B1"][1])
    B2_lo, B2_hi = np.log(bnd["B2"][0]), np.log(bnd["B2"][1])
    S1_lo, S1_hi = bnd["S1"]; S2_lo, S2_hi = bnd["S2"]
    # scale
    thetas = np.column_stack([
        B1_lo + U[:,0]*(B1_hi - B1_lo),
        B2_lo + U[:,1]*(B2_hi - B2_lo),
        S1_lo + U[:,2]*(S1_hi - S1_lo),
        S2_lo + U[:,3]*(S2_hi - S2_lo),
    ])

    # evaluate global candidates
    losses = np.array([objective(th, P2, bnd, loss_kind,fit_bin) for th in thetas])
    idx = np.argsort(losses)[:top_k]
    seeds = thetas[idx]

    # local refinement (bounded)
    results = []
    for th0 in seeds:
        # bounds in transformed space
        bounds_opt = [(B1_lo, B1_hi), (B2_lo, B2_hi), (S1_lo, S1_hi), (S2_lo, S2_hi)]
        res = minimize(objective, th0,
                       args=(P2, bnd, loss_kind,fit_bin),
                       method="L-BFGS-B", bounds=bounds_opt,
                       options=dict(maxiter=300, ftol=1e-8))
        results.append(res)

    # pick best local
    best = min(results, key=lambda r: r.fun)
    logB1, logB2, S1, S2 = best.x
    pars = dict(B1=float(np.exp(logB1)), B2=float(np.exp(logB2)),
                S1=float(S1), S2=float(S2), loss=float(best.fun))
    return pars, best, bnd, (thetas, losses)

def apply_model(LFT, pars, cluster = True, check_clusters = True, cluster_number = 1, 
    return_fitState = False, win = 40, return_full = False):
    LFT_filt = savgol_filter(LFT, 11, 2)
    fitS, fitState, fitError, BIC_ar = two_model_fit(LFT_filt, 
                                                     40, 1-1/pars['B1'], pars['S1'], 1-1/pars['B2'], 
                                                     pars['S2'], plotflag=0)
    if cluster & check_clusters:
        (fig, ax), labels = gmm_cluster_pka(LFT_filt, win=win, num_clusters=3, reg_covar=1e-12,
                            max_iter=1000, replicates=5, plotflag=1, ax=None,
                            random_state=10)
        plt.show()
        cluster_number = input('What label are you choosing to replace?')
        plt.close('all')
        fitState[labels==int(cluster_number)] = 4
        cont_list = find_continuous(fitState, [4])
        for c in cont_list:
            fitS[c] = fitS[c[0]]
    elif cluster:
        labels = gmm_cluster_pka(LFT_filt, win=win, num_clusters=3, reg_covar=1e-12,
                            max_iter=1000, replicates=5, plotflag=0, ax=None,
                            random_state=10)
        fitState[labels==int(cluster_number)] = 4
        cont_list = find_continuous(fitState, [4])
        for c in cont_list:
            fitS[c] = fitS[c[0]]

    zero_range, = np.where(fitS == 0)
    if len(zero_range) > 0:
        fit_range = [0, zero_range[0]]
    else:
        fit_range = [0, len(LFT)]
    r2 = r2_score(LFT_filt[fit_range[0]:fit_range[1]], 
                                         fitS[fit_range[0]:fit_range[1]])
    if return_full:
        if return_fitState:
            return LFT_filt, fitS, r2, fitState
        else:
            return LFT_filt, fitS, r2
    else:
        if return_fitState:
            return LFT_filt[fit_range[0]:fit_range[1]], fitS[fit_range[0]:fit_range[1]], r2, fitState[fit_range[0]:fit_range[1]]
        else:
            return LFT_filt[fit_range[0]:fit_range[1]], fitS[fit_range[0]:fit_range[1]], r2

def slope_P2(FLP_exp, ModelStates, minSleepDuration = 200, transitionLag = 2, slopeWindow = 30, fig = None, ax = None, 
    zscore = False, plot_bestfit = True):

    ModelStates[ModelStates == -1] = 2
    SleepClean = remove_fast_state(FLP_exp.SleepStates,80,1);
    StateClean = remove_fast_state(ModelStates, 5, 1)
    StateClean = remove_fast_state(StateClean, 10, 2)


    # Initialize results
    allTransitions = []  # list to hold results for each long sleep period

    # Find long sleep periods (label = 2)
    FLP_exp.SleepStates[FLP_exp.SleepStates == 5] = 2
    onoff_df = FLP_exp.ss_onset_offset()

    globalStartIndices = []
    globalEndIndices = []

    # Loop through all sleep periods
    values_global = []
    for i in onoff_df.loc[onoff_df['State'] == 2].index:

        if onoff_df['Duration'].loc[i] < minSleepDuration:
            continue

        # Restrict to this sleep segment
        if zscore:
            p2_segment = FLP_exp.ZScore[(FLP_exp.Time >= onoff_df['Start Time'].loc[i]) & (FLP_exp.Time <= onoff_df['End Time'].loc[i])]
        else:
            p2_segment = FLP_exp.Lifetime[(FLP_exp.Time >= onoff_df['Start Time'].loc[i]) & (FLP_exp.Time <= onoff_df['End Time'].loc[i])]
        state_segment = StateClean[(FLP_exp.Time >= onoff_df['Start Time'].loc[i]) & (FLP_exp.Time <= onoff_df['End Time'].loc[i])]
        t_segment = FLP_exp.Time[(FLP_exp.Time >= onoff_df['Start Time'].loc[i]) & (FLP_exp.Time <= onoff_df['End Time'].loc[i])]

        drop_start_rel, = np.where(state_segment == 2)
        
        if len(drop_start_rel) == 0:
            continue  # No drop after rise — skip
        
        drop_start_rel = drop_start_rel[0]
        idx_eval = drop_start_rel + 1  # Absolute index in segment
        idx_fit_end = idx_eval + slopeWindow - 1

        
        # yy_fit = p2_segment[:slopeWindow]
        yy_fit = p2_segment[idx_eval:idx_fit_end]
        xx_fit = t_segment[idx_eval:idx_fit_end]-t_segment[idx_eval] 
        slopeFirst = np.polyfit(xx_fit, yy_fit, 1)
        slope_valFirst = slopeFirst[0]
        # ax.axvline(idx_eval)

        # Find all rise (state = 1) sequences
        is_rise = (state_segment == 1).astype(int)
        is_rise = is_rise.flatten()
        rise_diff = np.diff(np.concatenate([[0], is_rise, [0]]))
        rise_starts = np.where(rise_diff == 1)[0]
        rise_ends = np.where(rise_diff == -1)[0] - 1
        
        values = []
        
        # Process each rise sequence
        for r in range(len(rise_starts)):
            idx1 = rise_starts[r]
            # ax.axvline(idx1)
            idx2 = rise_ends[r]
            idx3 = rise_ends[-1]  # Last rise end
        
            # Check minimum rise length
            if (idx2 - idx1) < 2:
                continue
        
            # Check rise amplitude (≥ 2%)
            val_start = p2_segment[idx1]
            val_end = p2_segment[idx2]
            # if (val_end - val_start) / abs(val_start) < 0.01:
            #     continue
        
            # Step 1: From idx2 onward, find next drop state (state == 2)
            post_rise_states = state_segment[idx2+1:]
            drop_start_rel, = np.where(post_rise_states == 2)
            
            if len(drop_start_rel) == 0:
                continue  # No drop after rise — skip
            
            drop_start_rel = drop_start_rel[0]
            idx_eval = idx2 + drop_start_rel + 1  # Absolute index in segment
            idx_fit_end = idx_eval + slopeWindow - 1
        
            if idx_fit_end >= len(p2_segment):
                continue
        
            # Step 2: Fit slope and store
            p2_val = p2_segment[idx_eval + transitionLag]
            y_fit = p2_segment[idx_eval+transitionLag:idx_fit_end+1]
            x_fit = t_segment[idx_eval+transitionLag:idx_fit_end+1]-t_segment[idx_eval+transitionLag] 
            slope = np.polyfit(x_fit, y_fit, 1)
            slope_val = slope[0]
            
            if slope_val > 0:
                continue
            # Step 3: Time to wake
            timeToWake = idx3 - idx_eval
            
            # Save result
            values.append([p2_val, slope_val, timeToWake])
        
        if slope_valFirst < 0:
            values_global.append([p2_segment[0], slope_valFirst, onoff_df['Duration'].loc[i]])        
        # Save results for this sleep period
        sleep_info = {
            'transitions': np.array(values) if values else np.array([]),
            'duration': onoff_df['Duration'].loc[i]
        }
        allTransitions.append(sleep_info)

    # Convert values_global to numpy array
    values_global = np.array(values_global)


    # Combine all transitions into one matrix
    allData = []
    for i in range(len(allTransitions)):
        if allTransitions[i]['transitions'].size > 0:
            allData.append(allTransitions[i]['transitions'])

    if len(allData) > 0:
        output_data = {}
        allData = np.vstack(allData)
        
        p2_vals = allData[:, 0]
        slopes = allData[:, 1]
        time_to_wake = allData[:, 2]
        
        # Create figure with subplots
        if ax is None:
            fig, (ax1, ax2, ax3) = plt.subplots(figsize=[12, 4], ncols = 3)
        else:
            (ax1, ax2, ax3) = ax
        
        # Subplot 1
        ax1.scatter(slopes, p2_vals, s=30, c='k', alpha = 0.3)
        ax1.set_xlabel('Slope of P2 over 30 pts')
        ax1.set_ylabel('P2')
        # ax1.grid(True)
        
        coeffs = np.polyfit(slopes, p2_vals, 1)
        x_fit = np.linspace(slopes.min(), slopes.max(), 100)
        y_fit = np.polyval(coeffs, x_fit)
        r, p = stats.pearsonr(slopes, p2_vals)
        output_data['subsequent_drop_data'] = {'slopes':slopes, 'p2_vals':p2_vals}
        if plot_bestfit:
            # Add linear fit
            ax1.plot(x_fit, y_fit, 'b-', linewidth=1.5)
            ax1.set_title(f'Slope vs. P2: r = {r:.2f}, p = {p:.2g}')
        
        # Subplot 2
        ax2.scatter(values_global[:, 1], values_global[:, 0], s=30, c='r', alpha = 0.3)
        ax2.set_xlabel('Slope of P2 over 30 pts')
        ax2.set_ylabel('P2')
        # ax2.grid(True)
        coeffsG = np.polyfit(values_global[:, 1], values_global[:, 0], 1)
        x_fitG = np.linspace(values_global[:, 1].min(), values_global[:, 1].max(), 100)
        y_fitG = np.polyval(coeffsG, x_fitG)
        r_g, p_g = stats.pearsonr(values_global[:, 1], values_global[:, 0])
        output_data['NREM_firstdrop_data'] = {'slopes':values_global[:, 1], 'p2_vals':values_global[:, 0]}
        if plot_bestfit:
            # Add linear fit
            ax2.plot(x_fitG, y_fitG, 'b-', linewidth=1.5)
            ax2.set_title(f'Slope vs. P2: r = {r_g:.2f}, p = {p_g:.2g}')
        
        ax3.scatter(slopes, p2_vals, s=40, c='k', alpha = 0.3)
        # ax3.plot(x_fit, y_fit, 'b-', linewidth=1.5)
        ax3.scatter(values_global[:, 1], values_global[:, 0], s=40, c='r', alpha = 0.3)
        # ax3.plot(x_fitG, y_fitG, 'b-', linewidth=1.5)
        ax3.set_xlabel('Slope of P2 over 30 pts')
        ax3.set_ylabel('P2 value')
        combo_slope_vals = np.concatenate([slopes,values_global[:, 1]])
        combo_p2_vals = np.concatenate([p2_vals,values_global[:, 0]])
        coeffs_both = np.polyfit(combo_slope_vals, combo_p2_vals, 1)
        x_fit_both = np.linspace(combo_slope_vals.min(), combo_slope_vals.max(), 100)
        y_fit_both = np.polyval(coeffs_both, x_fit_both)
        r_combo, p_combo = stats.pearsonr(combo_slope_vals, combo_p2_vals)
        output_data['All_drop_data'] = {'slopes':combo_slope_vals, 'p2_vals':combo_p2_vals}
        if plot_bestfit:
            # Subplot 3
            ax3.set_title(f'Slope vs. P2: r = {r_combo:.2f}, p = {p_combo:.2g}')
            ax3.plot(x_fit_both, y_fit_both, 'b-', linewidth=1.5)

        
        # Linear regression model
        X = slopes.reshape(-1, 1)
        y = p2_vals
        model = LinearRegression()
        model.fit(X, y)
        
        r2 = model.score(X, y)
        # Calculate p-value
        n = len(slopes)
        t_stat = r * np.sqrt(n - 2) / np.sqrt(1 - r**2)
        p_val = 2 * (1 - stats.t.cdf(abs(t_stat), n - 2))
        
        print(f"R² = {r2:.4f}")
        print(f"p-value = {p_val:.4g}")
        print(f"Pearson r = {r:.4f}, p = {p:.4g}")
    else:
        print("No transitions found in the data.")
    return fig, ax, output_data
    






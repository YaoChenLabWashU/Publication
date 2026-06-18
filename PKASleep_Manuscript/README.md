# PKA Sleep Manuscript — Code Repository

This repository contains the analysis code accompanying the manuscript on PKA activity dynamics during sleep, measured using fluorescence lifetime imaging photometry (FLiP) with the FLIM-AKAR and FLIM-mAKAR sensors.

## Repository structure

```
PKASleep_Manuscript/
├── *.py                        # PKA_Sleep package source modules
├── final_frailty_model_withMAZT_logtime.R   # R script for Cox frailty model
└── Figure_JupyterNotebooks/
    ├── *.ipynb                 # One notebook per manuscript figure
    └── Notebook_Concept_Maps/  # Plain-text descriptions of each notebook
```

## Python package modules

The `.py` files in the root form the `PKA_Sleep` package. Import as:

```python
import PKA_Sleep as PKA
from PKA_Sleep import Graphing_Utils as graph
from PKA_Sleep import FLPstats
```

### Core data class

**`FLPExp_class.py`** — Defines `FLiPExperiment`, the central data object. Loads concatenated `.mat` files produced by the acquisition pipeline, extracts FLiP lifetime, applies sleep scoring and microarousal labeling (via `neuroscience_sleep_scoring`), and computes shuffled control traces.

### Analysis modules

**`PKA_utils.py`** — The main analysis library. Contains utilities for building experiment class lists (`build_classes`), computing wake probability and logistic regression (`LFT_WakeSleepDistance`, `plot_wake_probability`, `wake_prob_logreg`), mutual information between EEG band power and FLiP lifetime (`nlcc_mi`), the PhosphoPlot phase-portrait visualization, and the Cox frailty model data preparation (`hazard_model`, which calls the R script via `subprocess`).

**`genPKA_Dynamics.py`** — Transition-triggered FLiP lifetime analysis (`transition_triggered_lifetime`, `transition_triggered_quant`) and EEG power aligned to sleep state transitions (`transition_triggered_power`, `plot_binned_power_p2`). Used by most figure notebooks.

**`AlarmClock_Analyses.py`** — Sound stimulus detection and alignment. Reads Bonsai audio timestamps, aligns them to the photometry timebase, detects individual sound events, and computes sound-triggered FLiP lifetime averages by behavioral outcome (`get_sound_timestamps`, `find_sound`, `sound_triggered_lifetime`).

**`AntagonistAnalyses.py`** — Analyses for pharmacology experiments (e.g., scopolamine injection). Handles drug epoch labeling and computes transition-triggered averages split by drug vs. saline condition (`transition_triggered_average_drug`, called internally by `transition_triggered_lifetime`).

**`FLPstats.py`** — Two-stage nested statistical analysis (`nested_analysis_stats_v2`). Stage 1 computes robust per-animal means using HuberT regression. Stage 2 runs a sign permutation test (primary) and Welch or paired t-test (secondary) across animals.

**`twomodel.py`** — Two-state exponential model for NREM FLiP lifetime dynamics. Fits alternating AR(1) rising and falling exponentials to continuous NREM lifetime traces (`two_model_fit`, `two_model_fit_lin`) and clusters PKA states using a Gaussian mixture model (`gmm_cluster_pka`).

**`memPKA_Dynamics.py`** — EEG band power cross-correlation with FLiP lifetime, and additional Cox proportional hazards utilities using `lifelines`.

**`intracellularPKA_Dynamics.py`** — Transient detection and visualization for intracellular (non-membrane-targeted) PKA sensor data.

**`Graphing_Utils.py`** — Shared plotting helpers: `thick_axes`, `make_bigandbold`, `linegraph_w_error`, `swarm_plot`, `get_jittered_x`, `label_axes`, and colormap utilities.

### Standalone utility scripts

**`exp_lin_compare.py`** — BIC-optimized fitting of exponential vs. linear decay models to FLiP lifetime traces, using a coarse random search followed by L-BFGS-B refinement (`joblib`-parallelized).

**`fit_trial_var.py`** — Batch script for fitting the two-state model across all experiments in a dataset.

**`get_injection_time.py`** — Detects drug injection timing from video files using frame-by-frame analysis (`opencv`).

### R script

**`final_frailty_model_withMAZT_logtime.R`** — Fits a Cox frailty proportional hazards model (using the `coxme` package) to predict time-to-wake from NREM sleep. Called automatically via `subprocess` from `PKA_utils.hazard_model()`.

## Dependencies

### Python
- `numpy`, `scipy`, `matplotlib`, `pandas`
- `statsmodels` — robust regression, mixed models
- `scikit-learn` — Gaussian mixture model, preprocessing
- `joblib` — parallel model fitting
- `natsort` — natural-order file sorting
- `pydub` — audio file loading (sound experiments)
- `lifelines` — survival analysis (Cox model utilities)
- `seaborn` — additional plotting
- `neuroscience_sleep_scoring` — custom sleep scoring package (provides `SWS_utils`; available separately)

### R
- `coxme` — Cox frailty model with random effects

## Figure notebooks

Each notebook in `Figure_JupyterNotebooks/` reproduces one or more manuscript panels. Plain-text concept maps in `Notebook_Concept_Maps/` describe each notebook's purpose, data, analysis pipeline, parameters, and outputs.

import pandas as pd
import numpy as np
from statsmodels.robust.robust_linear_model import RLM
from statsmodels.formula.api import mixedlm, ols
import statsmodels.robust.norms as norms
from scipy import stats
import matplotlib.pyplot as plt
import seaborn as sns
from statsmodels.stats.power import TTestPower
from scipy.optimize import curve_fit

class RobustMixedEffectsRLM:
    """
    Robust mixed-effects using RLM for different stages
    """
    
    def __init__(self, norm='HuberT', c=1.345):
        """
        norm: Robust norm to use ('HuberT', 'TukeyBiweight', 'LeastSquares')
        c: Tuning parameter for the norm
        """
        self.norm = norm
        self.c = c
        if norm == 'HuberT':
            self.M = norms.HuberT(t=c)
        elif norm == 'TukeyBiweight':
            self.M = norms.TukeyBiweight(c=c)
        elif norm == 'LeastSquares':
            self.M = norms.LeastSquares()
        else:
            raise ValueError("norm must be 'HuberT', 'TukeyBiweight', or 'LeastSquares'")
    
    def stage1_robust_subject_means(self, df, outcome_col='Data', 
        subject_col = 'Mouse_ID', group_col = 'Group'):
        """
        Stage 1: Get robust within-subject means using RLM
        """
        print(f"Stage 1: Computing robust subject-level means using {self.norm}...")
        
        subject_summaries = []
        
        for subject in df[subject_col].unique():
            subject_data = df[df[subject_col] == subject]
            
            # Get the group for this subject (assuming one group per subject)
            subject_groups = subject_data[group_col].unique()
            
            for group in subject_groups:
                group_data = subject_data[subject_data[group_col] == group]
                n_obs = len(group_data)
                
                if n_obs == 1:
                    # Only one observation - use it directly
                    robust_mean = group_data[outcome_col].iloc[0]
                    robust_se = np.nan
                    weights = np.array([1.0])
                else:
                    # Multiple observations - use RLM to get robust mean
                    # Create design matrix (just intercept for mean estimation)
                    X = np.ones((n_obs, 1))
                    y = group_data[outcome_col].values
                    
                    # Fit RLM
                    rlm_model = RLM(y, X, M=self.M)
                    rlm_result = rlm_model.fit()
                    
                    robust_mean = rlm_result.params[0]
                    robust_se = rlm_result.bse[0]
                    weights = rlm_result.weights
                
                subject_summaries.append({
                    subject_col: subject,
                    group_col: group,
                    'robust_mean': robust_mean,
                    'robust_se': robust_se if not np.isnan(robust_se) else 0,
                    'n_obs': n_obs,
                    'mean_weight': np.mean(weights)
                })
        
        stage1_df = pd.DataFrame(subject_summaries)

        if stage1_df.empty:
            raise ValueError(
                "stage1_robust_subject_means: no data found. "
                "Check that the DataFrame has rows and that outcome_col/subject_col/group_col match column names."
            )

        print(f"  Processed {len(stage1_df)} subject-group combinations")
        print(f"  Observations with downweighted data: {(stage1_df['mean_weight'] < 0.9).sum()}")
        
        return stage1_df
    
    def stage2_between_subjects(self, stage1_df, method='mixed', weight_by_precision=True,
        subject_col = 'Mouse_ID', group_col = 'Group'):
        """
        Stage 2: Between-subjects analysis
        
        method: 'mixed' (use mixedlm), 'rlm' (use RLM), or 'ols' (regular OLS)
        weight_by_precision: Whether to weight by 1/SE^2
        """
        print(f"Stage 2: Between-subjects analysis using {method}...")
        
        if weight_by_precision and 'robust_se' in stage1_df.columns:
            # Weight by precision (1/variance)
            stage1_df['precision_weight'] = np.where(
                stage1_df['robust_se'] > 0,
                1 / (stage1_df['robust_se'] ** 2),
                1.0  # Default weight for single observations
            )
            # Normalize weights
            stage1_df['precision_weight'] = stage1_df['precision_weight'] / stage1_df['precision_weight'].mean()
        else:
            stage1_df['precision_weight'] = 1.0
        
        if method == 'mixed':
            # Use regular mixed-effects on robust means
            model = mixedlm("robust_mean ~ "+group_col, 
                           data=stage1_df, 
                           groups=stage1_df[subject_col])
            result = model.fit()
            
        elif method == 'rlm':
            # Use RLM for between-subjects comparison
            from statsmodels.formula.api import rlm
            model = rlm("robust_mean ~ " + group_col, 
                       data=stage1_df,
                       M=self.M)
            result = model.fit()
            
        elif method == 'ols':
            # Regular OLS with weights
            from statsmodels.formula.api import wls
            model = wls("robust_mean ~ "+ group_co, 
                       data=stage1_df,
                       weights=stage1_df['precision_weight'])
            result = model.fit()
            
        else:
            raise ValueError("method must be 'mixed', 'rlm', or 'ols'")
        
        return result, stage1_df
    
    def fit(self, df, outcome_col='Data', subject_col = 'Mouse_ID', group_col = 'Group', 
        stage2_method='mixed'):
        """
        Complete two-stage robust mixed-effects analysis
        """
        print("=== ROBUST MIXED-EFFECTS USING RLM ===")
        print(f"Robust norm: {self.norm} (c={self.c})")
        print(f"Total observations: {len(df)}")
        print(f"Subjects: {df[subject_col].nunique()}")
        print(f"Groups: {df[group_col].nunique()}")
        print()
        
        # Stage 1: Robust subject means
        stage1_df = self.stage1_robust_subject_means(df, outcome_col)
        
        # Stage 2: Between-subjects analysis
        result, summary_df = self.stage2_between_subjects(stage1_df, method=stage2_method)
        
        # Store results
        self.stage1_data = stage1_df
        self.stage2_data = summary_df
        self.result = result
        
        print("\n=== FINAL RESULTS ===")
        print(result.summary())
        
        return result
    
    def plot_diagnostics(self, group_col = 'Group'):
        """
        Diagnostic plots for the robust analysis
        """
        if not hasattr(self, 'result'):
            print("No results to plot. Run fit() first.")
            return
        
        fig, axes = plt.subplots(2, 2, figsize=(12, 10))
        
        # Plot 1: Subject-level robust means by group
        sns.boxplot(data=self.stage1_data, x=group_col, y='robust_mean', ax=axes[0,0])
        axes[0,0].set_title('Robust Subject Means by Group')
        axes[0,0].set_ylabel('Robust Mean Outcome')
        
        # Plot 2: Weights from Stage 1
        axes[0,1].hist(self.stage1_data['mean_weight'], bins=20, alpha=0.7)
        axes[0,1].set_xlabel('Mean RLM Weight')
        axes[0,1].set_ylabel('Frequency')
        axes[0,1].set_title('Distribution of RLM Weights (Stage 1)')
        axes[0,1].axvline(x=1.0, color='red', linestyle='--', alpha=0.7)
        
        # Plot 3: Number of observations vs robust mean
        axes[1,0].scatter(self.stage1_data['n_obs'], self.stage1_data['robust_mean'], 
                         c=self.stage1_data['mean_weight'], cmap='viridis', alpha=0.7)
        axes[1,0].set_xlabel('Number of Observations per Subject')
        axes[1,0].set_ylabel('Robust Mean')
        axes[1,0].set_title('Robust Means vs N obs (colored by weight)')
        plt.colorbar(axes[1,0].collections[0], ax=axes[1,0])
        
        # Plot 4: Residuals from Stage 2
        if hasattr(self.result, 'resid'):
            residuals = self.result.resid
            fitted = self.result.fittedvalues
            
            axes[1,1].scatter(fitted, residuals, alpha=0.7)
            axes[1,1].axhline(y=0, color='red', linestyle='--', alpha=0.7)
            axes[1,1].set_xlabel('Fitted Values')
            axes[1,1].set_ylabel('Residuals')
            axes[1,1].set_title('Stage 2 Residuals vs Fitted')
        
        plt.tight_layout()
        plt.show()
        
        # Print summary statistics
        print("\n=== DIAGNOSTIC SUMMARY ===")
        downweighted = (self.stage1_data['mean_weight'] < 0.8).sum()
        total = len(self.stage1_data)
        print(f"Stage 1 - Subjects with downweighted observations: {downweighted}/{total} ({100*downweighted/total:.1f}%)")
        print(f"Stage 1 - Mean weight: {self.stage1_data['mean_weight'].mean():.3f}")
        print(f"Stage 1 - Min weight: {self.stage1_data['mean_weight'].min():.3f}")


def compare_robust_norms(df, outcome_col='Data'):
    """
    Compare different robust norms
    """
    norms_to_compare = [
        ('HuberT', 1.345, 'Standard Huber'),
        ('HuberT', 1.0, 'Conservative Huber'),
        ('TukeyBiweight', 4.685, 'Standard Tukey'),
        ('TukeyBiweight', 3.0, 'Conservative Tukey')
    ]
    
    results = {}
    
    for norm_name, c_val, description in norms_to_compare:
        print(f"\n{'='*60}")
        print(f"Testing {description} (c={c_val})")
        print('='*60)
        
        robust_model = RobustMixedEffectsRLM(norm=norm_name, c=c_val)
        result = robust_model.fit(df, outcome_col)
        
        results[f"{norm_name}_{c_val}"] = {
            'model': robust_model,
            'result': result,
            'description': description
        }
    
    return results


# Example usage function
def generate_rlm_and_mixed(df, outcome_col = 'Data', subject_col = 'Mouse_ID', 
    group_col = 'Group', plot_flag = False):
    """
    Demonstrate RLM-based robust mixed effects with simulated data
    """    
    print(f"  Total observations: {len(df)}")
    print(f"  Subjects: {df[subject_col].nunique()}")
    print(f"  Outcome range: [{df[outcome_col].min()}, {df[outcome_col].max()}]")
    
    # Compare with standard mixed-effects
    print("\n" + "="*60)
    print("STANDARD MIXED-EFFECTS MODEL")
    print("="*60)
    
    standard_model = mixedlm(outcome_col + " ~ "+ group_col, data=df, groups=df[subject_col])
    standard_result = standard_model.fit()
    print(standard_result.summary())
    
    # Robust analysis
    robust_model = RobustMixedEffectsRLM(norm='HuberT', c=2)
    robust_result = robust_model.fit(df, stage2_method='rlm')
    
    # Show diagnostics
    if plot_flag:
        robust_model.plot_diagnostics()
    
    return df, standard_result, robust_result

def nested_analysis_stats(grouped_data, grouped_expnames, grouped_mouseIDs, group_labels,
    outcome_col = 'Data', subject_col = 'Mouse_ID', group_col = 'Group'):
    all_dfs = []
    for i in range(len(group_labels)):
        temp_df = create_datadf(grouped_data[i], grouped_mouseIDs[i], grouped_expnames[i])
        temp_df['Group'] = group_labels[i]
        all_dfs.append(temp_df)
    data_df = pd.concat(all_dfs, ignore_index=True)

    data_df, standard_result, robust_result = generate_rlm_and_mixed(data_df,
        outcome_col = outcome_col, subject_col = subject_col, group_col = group_col)
    pvals = {l: p for l, p in zip(group_labels, robust_result.pvalues)}
    return data_df, standard_result, robust_result, pvals


EXACT_PERM_THRESHOLD = 100_000   # warn and suggest Monte Carlo above this many arrangements

def nested_analysis_stats_v2(grouped_data, grouped_expnames, grouped_mouseIDs, group_labels,
    outcome_col = 'Data', subject_col = 'Mouse_ID', group_col = 'Group',
    perm_flag = True, paired = False, parametric = True, n_perm = None, alternative='two-sided'):
    """
    Two-stage analysis with honest small-N inference.

    Stage 1 (always): per-animal robust mean via RLM (Huber M-estimator, c=1.345).
        Leverages all within-animal observations; makes each animal mean near noise-free.

    Stage 2 primary (always): permutation test — no distributional assumptions.
        independent (paired=False): group-label permutation.
        paired (paired=True): sign permutation.

        n_perm=None  → exact enumeration of all arrangements (feasible for small N).
                        independent: C(n0+n1, n1) arrangements; warns if > EXACT_PERM_THRESHOLD.
                        paired:      2^n_pairs arrangements; warns if > EXACT_PERM_THRESHOLD.
                        min two-tailed p = 2 / n_arrangements.
        n_perm=<int> → Monte Carlo: randomly sample n_perm permutations.
                        min two-tailed p ≈ 2 / n_perm; use ≥10,000 for stable estimates.
                        Recommended when N > ~12/group (independent) or > ~16 pairs (paired).

    Stage 2 secondary (controlled by parametric flag):
        parametric=True:
            independent → Welch t-test (unequal variance; CLT justifies normality of means)
            paired      → paired t-test; effect size = Cohen's dz
        parametric=False:
            independent → Mann-Whitney U (rank-sum); effect size = rank biserial r
            paired      → Wilcoxon signed-rank; effect size = rank biserial r

    Parameters
    ----------
    paired      : bool      — True if same animals appear in both conditions (matched by Mouse_ID)
    parametric  : bool      — True for t-test secondary; False for rank-based non-parametric
    perm_flag   : bool      — False to skip the permutation primary entirely
    n_perm      : int|None  — None = exact; integer = Monte Carlo with that many samples

    Returns
    -------
    stage1_df        : DataFrame, one row per animal per group
    perm_result      : dict — primary permutation result (always includes p_perm, n_arrangements)
    secondary_result : dict — secondary test result (keys vary by test; always includes p_secondary)
    """
    from itertools import combinations, product as iterproduct
    from math import comb

    all_dfs = []
    for i in range(len(group_labels)):
        temp_df = create_datadf(grouped_data[i], grouped_mouseIDs[i], grouped_expnames[i])
        temp_df['Group'] = group_labels[i]
        all_dfs.append(temp_df)
    data_df = pd.concat(all_dfs, ignore_index=True)

    # Stage 1: per-animal robust aggregation
    robust_model = RobustMixedEffectsRLM(norm='HuberT', c=1.345)
    stage1_df = robust_model.stage1_robust_subject_means(
        data_df, outcome_col=outcome_col, subject_col=subject_col, group_col=group_col
    )
    print(f"\n=== Stage 1: per-animal robust means ===")
    print(stage1_df[[subject_col, group_col, 'robust_mean', 'robust_se', 'n_obs']].to_string(index=False))

    if paired:
        # ------------------------------------------------------------------ #
        # PAIRED: same animals in both conditions, matched by Mouse_ID.       #
        # ------------------------------------------------------------------ #
        ids0 = set(stage1_df[stage1_df[group_col] == group_labels[0]][subject_col])
        ids1 = set(stage1_df[stage1_df[group_col] == group_labels[1]][subject_col])
        shared = sorted(ids0 & ids1)
        if len(shared) == 0:
            raise ValueError(
                "paired=True but no shared animal IDs found across groups. "
                "Check that the same Mouse_IDs appear in both grouped_mouseIDs lists."
            )
        if ids0 != ids1:
            print(f"  Warning: groups do not have identical animal sets. "
                  f"Analysing {len(shared)} matched pairs (unmatched animals ignored).")

        pivoted = (stage1_df[stage1_df[subject_col].isin(shared)]
                   .pivot(index=subject_col, columns=group_col, values='robust_mean')
                   .loc[shared])
        g0_paired = pivoted[group_labels[0]].values
        g1_paired = pivoted[group_labels[1]].values
        diffs = g0_paired - g1_paired   # experimental - control
        n_pairs = len(diffs)

        # Primary: sign permutation (exact or Monte Carlo)
        if perm_flag:
            observed_mean_diff = np.mean(diffs)
            n_exact = 2 ** n_pairs
            rng = np.random.default_rng()
            if n_perm is None and n_exact > EXACT_PERM_THRESHOLD:
                n_perm_run = 10_000
                print(f"  Auto-switching to Monte Carlo ({n_perm_run:,} samples): "
                      f"exact sign permutation would require {n_exact:,} arrangements.")
            else:
                n_perm_run = n_perm   # None = exact, int = Monte Carlo
            if n_perm_run is None:
                perm_stats = np.array([
                    np.mean(np.array(s) * diffs)
                    for s in iterproduct([-1, 1], repeat=n_pairs)
                ])
                n_arrangements = n_exact
                mode = 'exact'
            else:
                perm_stats = np.array([
                    np.mean(rng.choice([-1, 1], size=n_pairs) * diffs)
                    for _ in range(n_perm_run)
                ])
                n_arrangements = n_perm_run
                mode = f'Monte Carlo (n={n_perm_run:,})'
            p_perm = np.sum(np.abs(perm_stats) >= np.abs(observed_mean_diff)) / n_arrangements
            perm_result = {
                'observed_mean_diff': observed_mean_diff,
                'p_perm': p_perm,
                'n_arrangements': n_arrangements,
                'min_possible_p': 2 / n_arrangements,
                'mode': mode,
                'all_stats': perm_stats,
            }
            print(f"\n=== Stage 2 (PRIMARY): sign permutation [{mode}], {n_arrangements:,} arrangements ===")
            print(f"  Mean diff ({group_labels[0]} - {group_labels[1]}): {observed_mean_diff:.4f}")
            print(f"  p (two-tailed) = {p_perm:.4f}  [minimum possible = {2/n_arrangements:.4f}]")
        else:
            perm_result = {}

        # Secondary: parametric or non-parametric
        if parametric:
            t_stat, p_sec = stats.ttest_rel(g0_paired, g1_paired)
            sd_diffs = np.std(diffs, ddof=1)
            cohens_dz = np.mean(diffs) / sd_diffs if sd_diffs > 0 else np.nan
            secondary_result = {
                'test': 'paired t-test', 't': t_stat, 'df': n_pairs - 1,
                'p_secondary': p_sec, 'cohens_d': cohens_dz,
                'effect_size_label': "Cohen's dz",
            }
            print(f"\n=== Stage 2 (SECONDARY — parametric): paired t-test ===")
            print(f"  t({n_pairs - 1}) = {t_stat:.3f}, p = {p_sec:.4f}, Cohen's dz = {cohens_dz:.2f}")
        else:
            w_stat, p_sec = stats.wilcoxon(diffs, alternative=alternative)
            max_w = n_pairs * (n_pairs + 1) / 2
            r_rb = 1 - (2 * w_stat) / max_w
            secondary_result = {
                'test': 'Wilcoxon signed-rank', 'W': w_stat,
                'p_secondary': p_sec, 'rank_biserial_r': r_rb,
                'min_possible_p': 2 / (2 ** n_pairs),
                'effect_size_label': 'rank biserial r',
            }
            print(f"\n=== Stage 2 (SECONDARY — non-parametric): Wilcoxon signed-rank ===")
            print(f"  W = {w_stat:.1f}, p = {p_sec:.4f}  [minimum possible = {2/(2**n_pairs):.4f}]")
            print(f"  Rank biserial r = {r_rb:.3f}")

    else:
        # ------------------------------------------------------------------ #
        # INDEPENDENT: different animals in each group.                       #
        # ------------------------------------------------------------------ #
        g0 = stage1_df[stage1_df[group_col] == group_labels[0]]['robust_mean'].values
        g1 = stage1_df[stage1_df[group_col] == group_labels[1]]['robust_mean'].values
        n0, n1 = len(g0), len(g1)
        all_means = np.concatenate([g0, g1])
        n_total = n0 + n1

        # Primary: group-label permutation (exact or Monte Carlo)
        if perm_flag:
            observed_diff = np.mean(g0) - np.mean(g1)
            n_exact = comb(n_total, n1)
            rng = np.random.default_rng()
            if n_perm is None and n_exact > EXACT_PERM_THRESHOLD:
                n_perm_run = 10_000
                print(f"  Auto-switching to Monte Carlo ({n_perm_run:,} samples): "
                      f"exact permutation would require {n_exact:,} arrangements "
                      f"(n0={n0}, n1={n1}).")
            else:
                n_perm_run = n_perm   # None = exact, int = Monte Carlo
            if n_perm_run is None:
                perm_stats = np.array([
                    np.mean(all_means[[i for i in range(n_total) if i not in idx]])
                    - np.mean(all_means[list(idx)])
                    for idx in combinations(range(n_total), n1)
                ])
                n_arrangements = n_exact
                mode = 'exact'
            else:
                def _perm_diff():
                    p = rng.permutation(all_means)
                    return np.mean(p[:n0]) - np.mean(p[n0:])
                perm_stats = np.array([_perm_diff() for _ in range(n_perm_run)])
                n_arrangements = n_perm_run
                mode = f'Monte Carlo (n={n_perm_run:,})'
            p_perm = np.sum(np.abs(perm_stats) >= np.abs(observed_diff)) / n_arrangements
            perm_result = {
                'observed_diff': observed_diff,
                'p_perm': p_perm,
                'n_arrangements': n_arrangements,
                'min_possible_p': 2 / n_arrangements,
                'mode': mode,
                'all_stats': perm_stats,
            }
            print(f"\n=== Stage 2 (PRIMARY): group-label permutation [{mode}], {n_arrangements:,} arrangements ===")
            print(f"  Observed diff ({group_labels[0]} - {group_labels[1]}): {observed_diff:.4f}")
            print(f"  p (two-tailed) = {p_perm:.4f}  [minimum possible = {2/n_arrangements:.4f}]")
        else:
            perm_result = {}

        # Secondary: parametric or non-parametric
        if parametric:
            t_stat, p_sec = stats.ttest_ind(g0, g1, equal_var=False)
            sd0, sd1 = np.std(g0, ddof=1), np.std(g1, ddof=1)
            pooled_sd = np.sqrt((sd0**2 + sd1**2) / 2)
            cohens_d = (np.mean(g0) - np.mean(g1)) / pooled_sd if pooled_sd > 0 else np.nan
            welch_df = (sd0**2/n0 + sd1**2/n1)**2 / (
                (sd0**2/n0)**2/(n0 - 1) + (sd1**2/n1)**2/(n1 - 1))
            secondary_result = {
                'test': 'Welch t-test', 't': t_stat, 'df': welch_df,
                'p_secondary': p_sec, 'cohens_d': cohens_d,
                'effect_size_label': "Cohen's d",
            }
            print(f"\n=== Stage 2 (SECONDARY — parametric): Welch t-test ===")
            print(f"  t({welch_df:.1f}) = {t_stat:.3f}, p = {p_sec:.4f}, Cohen's d = {cohens_d:.2f}")
        else:
            u_stat, p_sec = stats.mannwhitneyu(g0, g1, alternative='two-sided')
            r_rb = (2 * u_stat) / (n0 * n1) - 1   # rank biserial r; >0 means g0 > g1
            secondary_result = {
                'test': 'Mann-Whitney U', 'U': u_stat,
                'p_secondary': p_sec, 'rank_biserial_r': r_rb,
                'min_possible_p': 2 / n_arrangements if perm_flag else np.nan,
                'effect_size_label': 'rank biserial r',
            }
            print(f"\n=== Stage 2 (SECONDARY — non-parametric): Mann-Whitney U ===")
            print(f"  U = {u_stat:.1f}, p = {p_sec:.4f}")
            print(f"  Rank biserial r = {r_rb:.3f}")

    return stage1_df, perm_result, secondary_result

def create_datadf(data_vals, animal_IDs, experiment_names):
    assert len(animal_IDs) == len(experiment_names) == len(data_vals)
    rows = []
    for i in range(len(animal_IDs)):
        vals = np.asarray(data_vals[i], dtype=float)
        true_vals = vals[np.isfinite(vals)]
        if len(true_vals) == 0:
            continue
        ename_raw = experiment_names[i]
        if isinstance(ename_raw, (list, tuple)):
            ename = ''.join(ename_raw) if len(ename_raw) > 1 else ename_raw[0]
        else:
            ename = ename_raw
        for v in true_vals:
            rows.append({'Experiment': ename, 'Mouse_ID': animal_IDs[i], 'Data': v})
    return pd.DataFrame(rows, columns=['Experiment', 'Mouse_ID', 'Data'])

import numpy as np

def exp_decay(x, a, b):
    """y = a * exp(-b * x)"""
    return a * np.exp(-b * x)

def WakeProb_PermutationTest(data, n_permutations=10000):
    """Test if experimental decay is significantly different from shuffled"""
    
    # Calculate observed difference
    exp_data = data[data['condition'] == 'experimental']
    shuf_data = data[data['condition'] == 'shuffled']
    
    exp_means = exp_data.groupby('position')['measurement'].mean()
    shuf_means = shuf_data.groupby('position')['measurement'].mean()
    
    positions = np.array(exp_means.index)
    
    params_exp, _ = curve_fit(exp_decay, positions, exp_means.values, p0=[exp_means.values[0], 0.1])
    params_shuf, _ = curve_fit(exp_decay, positions, shuf_means.values, p0=[shuf_means.values[0], 0.1])
    
    observed_diff = params_exp[1] - params_shuf[1]  # difference in decay rates
    
    # Permutation test
    perm_diffs = []
    all_data = data.copy()
    
    for _ in range(n_permutations):
        # Randomly shuffle condition labels
        all_data['condition_perm'] = np.random.permutation(all_data['condition'].values)
        
        exp_perm = all_data[all_data['condition_perm'] == 'experimental']
        shuf_perm = all_data[all_data['condition_perm'] == 'shuffled']
        
        exp_means_perm = exp_perm.groupby('position')['measurement'].mean()
        shuf_means_perm = shuf_perm.groupby('position')['measurement'].mean()
        
        try:
            params_exp_perm, _ = curve_fit(exp_decay, positions, exp_means_perm.values, 
                                          p0=[exp_means_perm.values[0], 0.1])
            params_shuf_perm, _ = curve_fit(exp_decay, positions, shuf_means_perm.values,
                                           p0=[shuf_means_perm.values[0], 0.1])
            perm_diffs.append(params_exp_perm[1] - params_shuf_perm[1])
        except:
            continue
    
    # P-value: proportion of permutations with difference >= observed
    p_value = np.mean(np.abs(perm_diffs) >= np.abs(observed_diff))
    
    print(f"Observed difference in decay rates: {observed_diff:.4f}")
    print(f"P-value (permutation test): {p_value:.2e}")
    
    # Visualize
    plt.hist(perm_diffs, bins=50, alpha=0.7, edgecolor='black')
    plt.axvline(observed_diff, color='red', linestyle='--', linewidth=2, 
                label=f'Observed ({observed_diff:.3f})')
    plt.xlabel('Difference in Decay Rates')
    plt.ylabel('Frequency')
    plt.legend()
    plt.title('Permutation Test Distribution')
    plt.show()
    
    return p_value

import numpy as np
from scipy.stats import wilcoxon

def wilcoxon_power_bootstrap(pilot_control, n, pct_change, alpha=0.05, n_sim=10000, seed=42):
    rng = np.random.default_rng(seed)
    rejections = 0
    
    # Convert percentage change to absolute shift based on pilot mean
    shift = np.mean(pilot_control) * (pct_change / 100)
    
    for _ in range(n_sim):
        control   = rng.choice(pilot_control, size=n, replace=True)
        treatment = rng.choice(pilot_control, size=n, replace=True) + shift

        differences = treatment - control
        _, p = wilcoxon(differences)
        if p < alpha:
            rejections += 1

    return rejections / n_sim
# Search for minimum n that achieves 80% power







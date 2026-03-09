*! dpath version 0.1.0  Subir Hait  2025
*! Decision Path Construction and Infrastructure Auditing for Stata
*! Implements decision infrastructure paradigm (Hait, 2025)

program define dpath
    version 15.0

    // Parse subcommand
    gettoken subcmd rest : 0

    if "`subcmd'" == "build" {
        dpath_build `rest'
    }
    else if "`subcmd'" == "describe" {
        dpath_describe `rest'
    }
    else if "`subcmd'" == "dri" {
        dpath_dri `rest'
    }
    else if "`subcmd'" == "entropy" {
        dpath_entropy `rest'
    }
    else if "`subcmd'" == "equity" {
        dpath_equity `rest'
    }
    else if "`subcmd'" == "audit" {
        dpath_audit `rest'
    }
    else if "`subcmd'" == "version" {
        di as text "dpath version 0.1.0 (Hait, 2025)"
    }
    else {
        di as error "Unknown subcommand: `subcmd'"
        di as text  "Valid subcommands: build describe dri entropy equity audit"
        exit 198
    }
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath build
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_build
    syntax varname(numeric) ,   ///
        ID(varname)             ///
        TIME(varname numeric)   ///
        [ OUTcome(varname numeric) ///
          GROUP(varname)          ///
          LABEL0(string)          ///
          LABEL1(string) ]

    // varname is the decision variable (must be 0/1)
    local decvar `varlist'

    // Validate binary decision
    quietly levelsof `decvar', local(dvals)
    foreach v of local dvals {
        if !inlist(`v', 0, 1) {
            di as error "Decision variable `decvar' must be binary (0/1). Found value: `v'"
            exit 198
        }
    }

    // Sort panel
    sort `id' `time'

    // Build path string per unit (stored as strL variable)
    tempvar pathstr
    qui {
        // Initialize
        gen str244 _dp_pathstr = ""
        bysort `id' (`time'): replace _dp_pathstr = ///
            cond(_n == 1, string(`decvar'), _dp_pathstr[_n-1] + "-" + string(`decvar'))
        // Keep only last obs per id (full path)
        bysort `id' (`time'): gen _dp_lastwave = (_n == _N)
    }

    // Store meta in globals (lightweight approach for v1)
    global _dp_id       "`id'"
    global _dp_time     "`time'"
    global _dp_dec      "`decvar'"
    global _dp_outcome  "`outcome'"
    global _dp_group    "`group'"
    global _dp_built    "1"

    // Summary message
    qui levelsof `id', local(nunits)
    local n_units : word count `nunits'
    qui levelsof `time', local(nwaves)
    local n_waves : word count `nwaves'

    di as text _newline "{hline 50}"
    di as text "  dpath build — Decision Path Object Created"
    di as text "{hline 50}"
    di as text "  Units    : " as result `n_units'
    di as text "  Waves    : " as result `n_waves'
    di as text "  Decision : " as result "`decvar'"
    if "`outcome'" != "" di as text "  Outcome  : " as result "`outcome'"
    if "`group'"   != "" di as text "  Group    : " as result "`group'"
    di as text "{hline 50}"
    di as text "  Use {cmd:dpath describe}, {cmd:dpath dri}, {cmd:dpath entropy},"
    di as text "  {cmd:dpath equity}, or {cmd:dpath audit} to analyse."
    di as text "{hline 50}" _newline
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath describe
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_describe, rclass
    syntax [, BY(varname) ]

    _dpath_require_build

    local id    "$_dp_id"
    local time  "$_dp_time"
    local dec   "$_dp_dec"
    local grp   = cond("`by'" != "", "`by'", "$_dp_group")

    // Per-unit statistics
    tempvar dosage switch_n switch_rate onset duration longest_run ever_treated

    sort `id' `time'

    // Dosage = mean of decision per unit
    bysort `id': egen `dosage' = mean(`dec')

    // Switching = number of 0→1 or 1→0 transitions / (T-1)
    tempvar lagged_dec diff_dec
    bysort `id' (`time'): gen `lagged_dec' = `dec'[_n-1]
    gen `diff_dec' = abs(`dec' - `lagged_dec') if `lagged_dec' != .
    bysort `id': egen `switch_n' = sum(`diff_dec')
    bysort `id': gen  `switch_rate' = `switch_n' / (_N - 1) if _n == _N

    // Onset = first wave with decision == 1
    tempvar dec_time
    gen `dec_time' = `time' if `dec' == 1
    bysort `id': egen `onset' = min(`dec_time')

    // Duration = total waves with decision == 1
    bysort `id': egen `duration' = sum(`dec')

    // Ever treated
    bysort `id': egen `ever_treated' = max(`dec')

    // Keep one obs per unit for summary
    tempvar last
    bysort `id' (`time'): gen `last' = (_n == _N)

    // Display aggregate
    di as text _newline "{hline 55}"
    di as text "  dpath describe — Path Descriptor Summary"
    di as text "{hline 55}"

    foreach v in dosage switch_rate onset duration {
        qui sum ``v'' if `last'
        di as text "  `v'" _col(22) ": mean = " as result %6.3f r(mean) ///
                   as text "  sd = " as result %6.3f r(sd)
        return scalar `v'_mean = r(mean)
        return scalar `v'_sd   = r(sd)
    }

    if "`grp'" != "" {
        di as text "{hline 55}"
        di as text "  By group: `grp'"
        di as text "{hline 55}"
        tabstat `dosage' `switch_rate' `onset' `duration' ///
            if `last', by(`grp') stat(mean sd n) nototal
    }

    di as text "{hline 55}" _newline

    // Drop temp vars (keep dataset clean)
    drop `lagged_dec' `diff_dec' `dec_time'
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath dri
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_dri, rclass
    syntax [, BY(varname) ]

    _dpath_require_build

    local id   "$_dp_id"
    local time "$_dp_time"
    local dec  "$_dp_dec"
    local grp  = cond("`by'" != "", "`by'", "$_dp_group")

    // DRI per unit: Cronbach alpha over binary items (time points)
    // For binary items: alpha = k/(k-1) * (1 - sum(p_t*(1-p_t)) / var_total_score)
    // where total score = sum of decisions for unit i

    tempvar total_score k_waves p_overall item_var_sum var_total dri_unit

    sort `id' `time'
    bysort `id': egen `total_score' = sum(`dec')
    bysort `id': gen  `k_waves'     = _N

    // p_t for each wave (overall proportion at each wave = item "difficulty")
    tempvar p_wave
    bysort `time': egen `p_wave' = mean(`dec')
    // item variance = p*(1-p) per wave; sum across waves per unit
    tempvar item_var_wave
    gen `item_var_wave' = `p_wave' * (1 - `p_wave')
    bysort `id': egen `item_var_sum' = sum(`item_var_wave')

    // Variance of total score per unit (using overall p and k)
    // var(total) = k * p_overall * (1 - p_overall) * k  (sum of iid binary)
    // More precisely: use population formula
    bysort `id': egen `p_overall' = mean(`dec')
    gen `var_total' = `k_waves'^2 * `p_overall' * (1 - `p_overall')

    // Alpha
    gen `dri_unit' = (`k_waves' / (`k_waves' - 1)) * (1 - `item_var_sum' / `var_total') ///
        if `var_total' > 0 & `k_waves' > 1
    replace `dri_unit' = max(0, min(1, `dri_unit'))  // bound to [0,1]

    // Keep one obs per unit
    tempvar last
    bysort `id' (`time'): gen `last' = (_n == _N)

    qui sum `dri_unit' if `last'
    local overall_dri = r(mean)

    di as text _newline "{hline 50}"
    di as text "  dpath dri — Decision Reliability Index"
    di as text "{hline 50}"
    di as text "  Overall DRI: " as result %6.3f `overall_dri'
    return scalar dri_overall = `overall_dri'

    if "`grp'" != "" {
        di as text "{hline 50}"
        di as text "  DRI by group: `grp'"
        tabstat `dri_unit' if `last', by(`grp') stat(mean sd n) nototal
    }

    di as text "{hline 50}" _newline

    drop `p_wave' `item_var_wave' `item_var_sum' `p_overall' `var_total' `dri_unit'
    drop `total_score' `k_waves'
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath entropy
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_entropy, rclass
    syntax [, BY(varname) TOP(integer 5) ]

    _dpath_require_build

    local id   "$_dp_id"
    local time "$_dp_time"
    local dec  "$_dp_dec"
    local grp  = cond("`by'" != "", "`by'", "$_dp_group")

    // Build path strings (reuse _dp_pathstr if available, else rebuild)
    tempvar pathstr last
    sort `id' `time'
    qui {
        bysort `id' (`time'): gen str244 `pathstr' = ///
            cond(_n == 1, string(`dec'), `pathstr'[_n-1] + "-" + string(`dec'))
        bysort `id' (`time'): gen `last' = (_n == _N)
    }

    // Frequency table of paths
    tempfile pathfreq
    preserve
        keep if `last'
        contract `pathstr', freq(_path_n)
        gen _path_prop = _path_n / _N
        gen _path_logp = log2(_path_prop)
        gen _path_contrib = -_path_prop * _path_logp
        qui sum _path_contrib
        local H = r(sum)
        qui count
        local n_paths = r(N)
        local H_norm = `H' / log2(max(`n_paths', 2))

        // Show top paths
        gsort -_path_n
        di as text _newline "{hline 55}"
        di as text "  dpath entropy — Decision Path Entropy"
        di as text "{hline 55}"
        di as text "  Shannon entropy H*  : " as result %6.3f `H' as text " bits"
        di as text "  Normalized entropy  : " as result %6.3f `H_norm'
        di as text "  Unique paths        : " as result `n_paths'
        di as text "{hline 55}"
        di as text "  Top `top' most frequent paths:"
        list `pathstr' _path_n _path_prop in 1/`top', noobs clean

    restore

    return scalar entropy      = `H'
    return scalar entropy_norm = `H_norm'
    return scalar n_paths      = `n_paths'

    di as text "{hline 55}" _newline
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath equity
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_equity, rclass
    syntax , BY(varname) [ REF(string) ]

    _dpath_require_build

    local id   "$_dp_id"
    local time "$_dp_time"
    local dec  "$_dp_dec"

    // Build per-unit descriptors
    tempvar dosage switch_n switch_rate onset duration lagged diff last

    sort `id' `time'
    bysort `id': egen `dosage'   = mean(`dec')
    bysort `id' (`time'): gen `lagged' = `dec'[_n-1]
    gen `diff' = abs(`dec' - `lagged') if `lagged' != .
    bysort `id': egen `switch_n' = sum(`diff')
    bysort `id': gen `switch_rate' = `switch_n' / (_N - 1) if _n == _N
    tempvar dec_time
    gen `dec_time' = `time' if `dec' == 1
    bysort `id': egen `onset' = min(`dec_time')
    bysort `id': egen `duration' = sum(`dec')
    bysort `id' (`time'): gen `last' = (_n == _N)

    di as text _newline "{hline 60}"
    di as text "  dpath equity — Group Equity Diagnostics"
    di as text "{hline 60}"
    di as text "  Group variable: `by'"
    di as text "{hline 60}"

    tabstat `dosage' `switch_rate' `onset' `duration' if `last', ///
        by(`by') stat(mean sd n) nototal

    // Standardized mean differences (Cohen's d)
    di as text _newline "  Standardized Mean Differences (SMD):"
    di as text "{hline 60}"

    qui levelsof `by', local(grplevels)
    local grplist : list grplevels
    local ref_lv : word 1 of `grplist'
    if "`ref'" != "" local ref_lv "`ref'"

    foreach m in dosage switch_rate onset duration {
        qui sum ``m'' if `last' & `by' == "`ref_lv'"
        local m1 = r(mean)
        local v1 = r(Var)

        foreach lv of local grplevels {
            if "`lv'" == "`ref_lv'" continue
            qui sum ``m'' if `last' & `by' == "`lv'"
            local m2 = r(mean)
            local v2 = r(Var)
            local pooled_sd = sqrt((`v1' + `v2') / 2)
            if `pooled_sd' > 0 {
                local smd = (`m1' - `m2') / `pooled_sd'
            }
            else local smd = 0
            di as text "  `m' (`ref_lv' vs `lv'): SMD = " as result %6.3f `smd'
        }
    }

    di as text "{hline 60}" _newline

    drop `lagged' `diff' `dec_time'
end


// ─────────────────────────────────────────────────────────────────────────────
// dpath audit
// ─────────────────────────────────────────────────────────────────────────────
program define dpath_audit
    syntax [, BY(varname) ]

    _dpath_require_build

    local grp = cond("`by'" != "", "`by'", "$_dp_group")

    di as text _newline
    di as text "{hline 60}"
    di as text "  DECISION INFRASTRUCTURE AUDIT"
    di as text "  (Hait, 2025 — decisionpaths framework)"
    di as text "{hline 60}"

    di as text _newline ">>> Step 1: Path Descriptors"
    if "`grp'" != "" dpath describe, by(`grp')
    else              dpath describe

    di as text _newline ">>> Step 2: Decision Reliability Index (DRI)"
    if "`grp'" != "" dpath dri, by(`grp')
    else              dpath dri

    di as text _newline ">>> Step 3: Decision Path Entropy (H*)"
    if "`grp'" != "" dpath entropy, by(`grp')
    else              dpath entropy

    if "`grp'" != "" {
        di as text _newline ">>> Step 4: Equity Diagnostics"
        dpath equity, by(`grp')
    }

    di as text _newline "{hline 60}"
    di as text "  Audit complete. Cite: Hait (2025) and dpath v0.1.0."
    di as text "{hline 60}" _newline
end


// ─────────────────────────────────────────────────────────────────────────────
// Internal helper: require dpath build to have been run
// ─────────────────────────────────────────────────────────────────────────────
program define _dpath_require_build
    if "$_dp_built" != "1" {
        di as error "Run {cmd:dpath build} first to create a decision-path object."
        exit 198
    }
end

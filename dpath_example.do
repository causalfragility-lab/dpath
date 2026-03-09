*! dpath_example.do
*! Simulation study demonstrating dpath v0.1.0
*! Author: Subir Hait, Michigan State University
*! Implements Hait (2025) Decision Infrastructure Paradigm
* =============================================================================
* OVERVIEW
* Four cohorts (N=200, K=8 waves) representing four infrastructure types:
*   Type I   — Static         : decision fixed at baseline
*   Type II  — Periodic       : recalibrated every 2 waves
*   Type III — Continuous     : updates every wave
*   Type IV  — Human-in-loop  : 20% random override
* SES groups Q1 (lowest) to Q4 (highest)
* =============================================================================

clear all
set seed 2025
set more off

* =============================================================================
* SECTION 1: GENERATE SIMULATION DATA
* =============================================================================

local N   = 200
local K   = 8

* ---- Generate unit-level data -----------------------------------------------
set obs `N'
gen id = _n

* SES group assignment
gen u_ses = runiform()
gen ses = "Q1" if u_ses < 0.30
replace ses = "Q2" if u_ses >= 0.30 & u_ses < 0.58
replace ses = "Q3" if u_ses >= 0.58 & u_ses < 0.82
replace ses = "Q4" if u_ses >= 0.82

* Baseline risk by SES
gen baseline_risk = 0.70 if ses == "Q1"
replace baseline_risk = 0.55 if ses == "Q2"
replace baseline_risk = 0.40 if ses == "Q3"
replace baseline_risk = 0.25 if ses == "Q4"

* Add noise
replace baseline_risk = baseline_risk + rnormal(0, 0.08)
replace baseline_risk = max(0.05, min(0.95, baseline_risk))

* ---- Expand to panel (N x K rows) ------------------------------------------
expand `K'
bysort id: gen wave = _n

* ---- Type I: Static (decision fixed at baseline) ----------------------------
bysort id (wave): gen d_static = (runiform() < baseline_risk) if wave == 1
bysort id (wave): replace d_static = d_static[1]

* ---- Type II: Periodic (recalibrated every 2 waves) -------------------------
gen risk_II = baseline_risk
gen d_periodic = .
forvalues t = 1/`K' {
    local odd = mod(`t', 2)
    if `odd' == 1 {
        replace risk_II = max(0.05, min(0.95, ///
            risk_II + rnormal(0, 0.05))) if wave == `t'
    }
    else {
        replace risk_II = risk_II if wave == `t'
    }
    replace d_periodic = (runiform() < risk_II) if wave == `t'
}

* ---- Type III: Continuous (updates every wave) ------------------------------
gen risk_III = baseline_risk
gen d_continuous = .
forvalues t = 1/`K' {
    replace risk_III = max(0.05, min(0.95, ///
        risk_III + rnormal(0, 0.12))) if wave == `t'
    replace d_continuous = (runiform() < risk_III) if wave == `t'
}

* ---- Type IV: Human-in-loop (20% override) ----------------------------------
gen risk_IV = baseline_risk
gen d_raw = .
gen d_override = .
gen d_humanloop = .
forvalues t = 1/`K' {
    replace risk_IV  = max(0.05, min(0.95, ///
        risk_IV + rnormal(0, 0.08))) if wave == `t'
    replace d_raw      = (runiform() < risk_IV)     if wave == `t'
    replace d_override = (runiform() < 0.20)        if wave == `t'
    replace d_humanloop = cond(d_override == 1, ///
        1 - d_raw, d_raw)                           if wave == `t'
}

drop risk_II risk_III risk_IV d_raw d_override u_ses

* =============================================================================
* SECTION 2: DEMONSTRATE dpath — TYPE I (STATIC)
* =============================================================================

di _newline as text "========================================="
di          as text "  TYPE I — STATIC INFRASTRUCTURE"
di          as text "========================================="

dpath build d_static, id(id) time(wave) group(ses)

dpath describe, by(ses)

dpath dri, by(ses)

dpath entropy, top(5)

dpath equity, by(ses) ref(Q4)

* =============================================================================
* SECTION 3: DEMONSTRATE dpath — TYPE III (CONTINUOUS)
* =============================================================================

di _newline as text "========================================="
di          as text "  TYPE III — CONTINUOUSLY ADAPTIVE"
di          as text "========================================="

dpath build d_continuous, id(id) time(wave) group(ses)

dpath describe, by(ses)

dpath dri, by(ses)

dpath entropy, top(5)

dpath equity, by(ses) ref(Q4)

* =============================================================================
* SECTION 4: FULL AUDIT — TYPE IV (HUMAN-IN-LOOP)
* =============================================================================

di _newline as text "========================================="
di          as text "  TYPE IV — HUMAN-IN-LOOP (FULL AUDIT)"
di          as text "========================================="

dpath build d_humanloop, id(id) time(wave) group(ses)

dpath audit, by(ses)

* =============================================================================
* SECTION 5: CROSS-TYPE COMPARISON
* =============================================================================

di _newline as text "========================================="
di          as text "  CROSS-TYPE DRI COMPARISON"
di          as text "========================================="

foreach type in static periodic continuous humanloop {
    local decvar = "d_`type'"
    capture confirm variable `decvar'
    if !_rc {
        dpath build `decvar', id(id) time(wave)
        dpath dri
        local dri_`type' = r(dri_overall)
    }
}

di as text _newline "DRI Summary:"
di as text "  Type I   (Static)      : " as result %6.3f `dri_static'
di as text "  Type II  (Periodic)    : " as result %6.3f `dri_periodic'
di as text "  Type III (Continuous)  : " as result %6.3f `dri_continuous'
di as text "  Type IV  (Human-loop)  : " as result %6.3f `dri_humanloop'
di as text _newline "[Expected: DRI Type I = 1.0, decreasing for II, III, IV]"

di _newline as text "========================================="
di          as text "  Session complete"
di          as text "  dpath v0.1.0 — Hait (2025)"
di          as text "========================================="

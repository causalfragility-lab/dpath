# dpath — Stata Package
## Construct and Audit Longitudinal Decision Paths

**Version:** 1.0.0  
**Author:** Subir Hait, Michigan State University  
**Email:** haitsubi@msu.edu  
**ORCID:** 0009-0004-9871-9677  
**GitHub:** https://github.com/causalfragility-lab/dpath  
**Companion R package:** https://github.com/causalfragility-lab/decisionpaths

---

## Overview

`dpath` is the Stata equivalent of the R package `decisionpaths` (Hait, 2026).
It implements the **Decision Infrastructure Paradigm**, which reconceptualises
institutional AI systems not as static classifiers but as infrastructure that
generates time-ordered binary decision sequences — the **decision path** — as
the primary empirical object.

---

## Installation

### From GitHub (recommended)
```stata
net install dpath, from("https://raw.githubusercontent.com/causalfragility-lab/dpath/main/") replace
```

### Manual Installation
Copy all `.ado` files to your Stata personal ado directory:
```stata
. adopath
```
Then place all `.ado` files and `dpath.sthlp` in that directory.

---

## Core Functions

| Command | Description |
|---|---|
| `dpath build` | Build decision-path variables from panel data |
| `dpath describe` | Per-unit path descriptors: dosage, switching, onset, duration |
| `dpath dri` | Decision Reliability Index (Cronbach, 1951 analogy) |
| `dpath entropy` | Shannon path entropy (Shannon, 1948) |
| `dpath equity` | Group equity diagnostics via SMDs |
| `dpath audit` | Full five-step integrated audit |

---

## Quick Start

```stata
* Setup panel
xtset studentid wave

* Step 1: Build decision-path variables
dpath build ai_flag, id(studentid) time(wave) group(sesq)

* Step 2: Descriptors
dpath describe, id(studentid) time(wave) by(sesq)

* Step 3: DRI
dpath dri, id(studentid) time(wave) by(sesq)

* Step 4: Entropy
dpath entropy, id(studentid) time(wave) by(sesq)

* Step 5: Equity
dpath equity, id(studentid) time(wave) by(sesq) ref(Q1)

* Or run everything at once:
dpath audit ai_flag, id(studentid) time(wave) by(sesq) ref(Q1)
```

---

## New Variables Created by `dpath build`

| Variable | Description |
|---|---|
| `_dp_path_str` | Decision path string e.g. `0-1-1-0` |
| `_dp_dosage` | Proportion of waves with decision = 1 |
| `_dp_switch` | Switching rate |
| `_dp_onset` | First wave with decision = 1 |
| `_dp_duration` | Count of waves with decision = 1 |
| `_dp_longest` | Longest consecutive run of decision = 1 |
| `_dp_n_periods` | Number of observed waves |
| `_dp_treat_count` | Total treated waves |

---

## Infrastructure Typology (Hait, 2026)

| Type | Description | DRI | Entropy |
|---|---|---|---|
| I — Static | Decision fixed at baseline | ~1.0 | Very low |
| II — Periodic | Recalibrated every N waves | ~0.70–0.95 | Medium |
| III — Continuous | Updates every wave | ~0.40–0.70 | High |
| IV — Human-in-loop | Algorithmic + human override | ~0.30–0.50 | High |

---

## Stored Results (`r()`)

After `dpath audit`:

```
r(n_units)            — number of units
r(n_waves)            — maximum waves
r(balanced)           — 1 if balanced panel
r(mean_dosage)        — mean dosage
r(mean_switch)        — mean switching rate
r(DRI)                — Decision Reliability Index
r(entropy)            — Shannon H (bits)
r(normalized_entropy) — H* (normalized)
r(n_unique_paths)     — unique path count
```

---

## References

Cronbach, L. J. (1951). Coefficient alpha and the internal structure of tests. *Psychometrika*, 16(3), 297–334.

Hait, S. (2026). Artificial intelligence as decision infrastructure: Rethinking institutional decision processes. Michigan State University. https://github.com/causalfragility-lab/decisionpaths

Nunnally, J. C. (1978). *Psychometric theory* (2nd ed.). McGraw-Hill.

Shannon, C. E. (1948). A mathematical theory of communication. *Bell System Technical Journal*, 27(3), 379–423.

---

## Citation

```
Hait, S. (2026). dpath: Construct and Audit Longitudinal Decision Paths.
Stata package version 1.0.0.
https://github.com/causalfragility-lab/dpath
```

# dpath

**Decision-Path Construction and Infrastructure Auditing for Stata**

`dpath` implements the **Decision Infrastructure Paradigm** (Hait, 2025) for analysing AI-mediated institutional decision processes in longitudinal panel data. It treats time-ordered decision sequences — not individual decisions — as the primary unit of analysis.

## Installation

### From SSC (once published)
```stata
ssc install dpath
```

### From GitHub (development version)
```stata
net install dpath, from("https://raw.githubusercontent.com/causalfragility-lab/dpath/main/")
```

## Core Workflow

```stata
* Step 1: Build decision-path object
dpath build ai_flag, id(studentid) time(wave) outcome(math) group(sesq)

* Step 2: Path descriptors
dpath describe, by(sesq)

* Step 3: Decision Reliability Index (Cronbach, 1951)
dpath dri, by(sesq)

* Step 4: Shannon path entropy (Shannon, 1948)
dpath entropy, top(10)

* Step 5: Equity diagnostics
dpath equity, by(sesq) ref(Q4)

* Or run all steps at once
dpath audit, by(sesq)
```

## Infrastructure Types

| Type | Description | Expected DRI |
|------|-------------|-------------|
| I — Static | Decision fixed at baseline | ~1.0 |
| II — Periodic | Recalibrated every N waves | ~0.6–0.8 |
| III — Continuous | Updates every wave | ~0.4–0.6 |
| IV — Human-in-loop | Algorithmic + human override | ~0.3–0.5 |

## Subcommands

| Subcommand | Description |
|-----------|-------------|
| `dpath build` | Construct decision-path object from panel data |
| `dpath describe` | Dosage, switching rate, onset, duration |
| `dpath dri` | Decision Reliability Index |
| `dpath entropy` | Shannon path entropy |
| `dpath equity` | Group equity diagnostics via SMD |
| `dpath audit` | Full five-step audit pipeline |

## Companion R Package

The companion R package `decisionpaths` is available at:
[https://github.com/causalfragility-lab/decisionpaths](https://github.com/causalfragility-lab/decisionpaths)

## References

- Cronbach, L. J. (1951). Coefficient alpha and the internal structure of tests. *Psychometrika*, 16(3), 297–334. https://doi.org/10.1007/BF02310555
- Hait, S. (2025). Artificial intelligence as decision infrastructure: Rethinking institutional decision processes. Michigan State University.
- Shannon, C. E. (1948). A mathematical theory of communication. *Bell System Technical Journal*, 27(3), 379–423. https://doi.org/10.1002/j.1538-7305.1948.tb01338.x

## Author

Subir Hait, Michigan State University  
haitsubi@msu.edu  
ORCID: [0009-0004-9871-9677](https://orcid.org/0009-0004-9871-9677)

## Citation

Hait, S. (2025). *dpath: Decision-path construction and infrastructure auditing for Stata*. Version 0.1.0. https://github.com/causalfragility-lab/dpath

{smcl}
{* *! dpath v0.1.0  Subir Hait  2025}{...}
{title:Title}

{phang}{cmd:dpath} {hline 2} Decision-Path Construction and Infrastructure Auditing{p_end}


{title:Syntax}

{p 8 17 2}
{cmd:dpath} {it:subcommand} [{it:decision_var}] [, {it:options}]

{synoptset 20 tabbed}{...}
{synopthdr:Subcommand}
{synoptline}
{synopt:{opt build}}Construct decision-path object from panel data{p_end}
{synopt:{opt describe}}Path descriptor summaries (dosage, switching, onset, duration){p_end}
{synopt:{opt dri}}Decision Reliability Index{p_end}
{synopt:{opt entropy}}Shannon path entropy{p_end}
{synopt:{opt equity}}Group equity diagnostics and standardized mean differences{p_end}
{synopt:{opt audit}}Full Decision Infrastructure Audit (all steps){p_end}
{synoptline}


{title:Description}

{pstd}
{cmd:dpath} implements the decision infrastructure paradigm for analysing
AI-mediated institutional decision processes in longitudinal panel data
(Hait, 2025). It treats decision sequences — not individual decisions —
as the primary unit of analysis.{p_end}

{pstd}
The typical workflow is:{p_end}

{phang2}1. {cmd:dpath build} — define the decision-path object{p_end}
{phang2}2. {cmd:dpath describe} — summarise path descriptors{p_end}
{phang2}3. {cmd:dpath dri} — assess decision reliability{p_end}
{phang2}4. {cmd:dpath entropy} — measure path complexity{p_end}
{phang2}5. {cmd:dpath equity} — evaluate group disparities{p_end}
{phang2}   or run all steps at once with {cmd:dpath audit}{p_end}


{title:dpath build}

{p 8 17 2}
{cmd:dpath build} {it:decisionvar}{cmd:,}
{opt id(varname)}
{opt time(varname)}
[{opt outcome(varname)}
{opt group(varname)}]

{pstd}
{it:decisionvar} must be binary (0/1). {opt id()} is the unit identifier.
{opt time()} is the wave/period variable. {opt outcome()} and {opt group()}
are optional and are used by downstream commands.{p_end}


{title:dpath describe}

{p 8 17 2}
{cmd:dpath describe} [{cmd:,} {opt by(varname)}]

{pstd}
Reports mean and SD of: dosage (proportion of waves with decision=1),
switching rate, onset (first treated wave), and duration (total treated waves).
Optional {opt by()} stratifies by a group variable.{p_end}


{title:dpath dri}

{p 8 17 2}
{cmd:dpath dri} [{cmd:,} {opt by(varname)}]

{pstd}
Computes the Decision Reliability Index (DRI) following Cronbach (1951)
and Nunnally (1978). DRI = 1 indicates a perfectly consistent decision path;
DRI = 0 indicates maximum instability.{p_end}

{pstd}Stored results:{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(dri_overall)}}Overall mean DRI{p_end}


{title:dpath entropy}

{p 8 17 2}
{cmd:dpath entropy} [{cmd:,} {opt by(varname)} {opt top(#)}]

{pstd}
Computes Shannon entropy H* of the distribution of decision-path strings
following Shannon (1948). Higher entropy indicates greater path diversity.
{opt top(#)} controls how many frequent paths to display (default 5).{p_end}

{pstd}Stored results:{p_end}
{synoptset 20 tabbed}{...}
{synopt:{cmd:r(entropy)}}Shannon entropy in bits{p_end}
{synopt:{cmd:r(entropy_norm)}}Normalized entropy (0 to 1){p_end}
{synopt:{cmd:r(n_paths)}}Number of unique paths{p_end}


{title:dpath equity}

{p 8 17 2}
{cmd:dpath equity}{cmd:,} {opt by(varname)} [{opt ref(string)}]

{pstd}
Computes group-level means and standardized mean differences (SMD) for
dosage, switching rate, onset, and duration. {opt ref()} specifies the
reference group for SMD computation (default: first group alphabetically).{p_end}


{title:dpath audit}

{p 8 17 2}
{cmd:dpath audit} [{cmd:,} {opt by(varname)}]

{pstd}
Executes the full five-step Decision Infrastructure Audit: descriptors,
DRI, entropy, and equity diagnostics. Equivalent to running all subcommands
in sequence.{p_end}


{title:Examples}

{phang2}{cmd:. * Step 1: Build decision-path object}{p_end}
{phang2}{cmd:. dpath build ai_flag, id(studentid) time(wave) outcome(math) group(sesq)}{p_end}

{phang2}{cmd:. * Step 2: Path descriptors by SES}{p_end}
{phang2}{cmd:. dpath describe, by(sesq)}{p_end}

{phang2}{cmd:. * Step 3: Decision Reliability Index}{p_end}
{phang2}{cmd:. dpath dri, by(sesq)}{p_end}

{phang2}{cmd:. * Step 4: Path entropy}{p_end}
{phang2}{cmd:. dpath entropy, top(10)}{p_end}

{phang2}{cmd:. * Step 5: Equity diagnostics}{p_end}
{phang2}{cmd:. dpath equity, by(sesq) ref(Q4)}{p_end}

{phang2}{cmd:. * Or run all steps at once}{p_end}
{phang2}{cmd:. dpath audit, by(sesq)}{p_end}


{title:References}

{pstd}
Cronbach, L. J. (1951). Coefficient alpha and the internal structure of tests.
{it:Psychometrika}, 16(3), 297-334.
{browse "https://doi.org/10.1007/BF02310555"}{p_end}

{pstd}
Hait, S. (2025). Artificial intelligence as decision infrastructure:
Rethinking institutional decision processes. Michigan State University.
{browse "https://github.com/causalfragility-lab/dpath"}{p_end}

{pstd}
Nunnally, J. C. (1978). {it:Psychometric theory} (2nd ed.). McGraw-Hill.{p_end}

{pstd}
Shannon, C. E. (1948). A mathematical theory of communication.
{it:Bell System Technical Journal}, 27(3), 379-423.
{browse "https://doi.org/10.1002/j.1538-7305.1948.tb01338.x"}{p_end}


{title:Author}

{pstd}
Subir Hait, Michigan State University{break}
{browse "mailto:haitsubi@msu.edu":haitsubi@msu.edu}{p_end}

{pstd}
Source code and documentation:{break}
{browse "https://github.com/causalfragility-lab/dpath"}{p_end}


{title:Citation}

{pstd}
Hait, S. (2025). {it:dpath: Decision-path construction and infrastructure}
{it:auditing for Stata}. Version 0.1.0.
{browse "https://github.com/causalfragility-lab/dpath"}{p_end}

{p 4 4 2}{hline}{p_end}

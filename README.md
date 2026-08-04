# Active Maintenance Report: coppock_2019a


- [Paper overview](#paper-overview)
- [Summary](#summary)
  - [Does the deposited archive run?](#does-the-deposited-archive-run)
  - [Does the maintained rewrite reproduce the
    paper?](#does-the-maintained-rewrite-reproduce-the-paper)
- [Original archive reproducibility](#original-archive-reproducibility)
  - [Filename case](#filename-case)
  - [The archive writes into itself](#the-archive-writes-into-itself)
  - [The standard error package no longer
    exists](#the-standard-error-package-no-longer-exists)
- [Number-by-number comparison](#number-by-number-comparison)
  - [Table 2 in full](#table-2-in-full)
- [Maintained rewrite](#maintained-rewrite)
  - [Deprecated patterns replaced](#deprecated-patterns-replaced)
  - [What the rewrite does not cover](#what-the-rewrite-does-not-cover)
  - [The power sentence](#the-power-sentence)
  - [Determinism](#determinism)
- [Figures](#figures)
- [Tables](#tables)
- [The extraction and the two
  instruments](#the-extraction-and-the-two-instruments)
- [Maintained rewrite verification](#maintained-rewrite-verification)
- [R environment](#r-environment)

*Drafted by Claude Opus 5 under the supervision of Alex Coppock.*

This repository holds the actively maintained replication code for
Coppock (2019), together with the reproducibility report that documents
what the original archive did and did not do. It is part of a program
applying the maintenance proposal in Peer, Orr and Coppock (2021, *PS:
Political Science & Politics*, doi
[10.1017/S1049096521000366](https://doi.org/10.1017/S1049096521000366))
to a set of published archives.

|  |  |
|----|----|
| Article | [10.1017/psrm.2018.10](https://doi.org/10.1017/psrm.2018.10) |
| Replication archive | [10.7910/DVN/F1CFFM](https://doi.org/10.7910/DVN/F1CFFM) |

**The data are not redistributed here.** The deposit is 38 files at
Harvard Dataverse, which is the only copy this repository points at.
`download_original.R` fetches it and verifies every file;
`original_manifest.csv` pins the file identifiers, sizes and checksums,
so the exact bytes this code was written against are recorded in version
control even though the bytes themselves are not.

**Repository layout.** `maintained/` is the maintained rewrite: one
script per published table or figure, writing to `output/`, which is
committed so a reader can compare a fresh run against it without
downloading anything, plus `in_text_claims.R`, which recomputes every
number the article states in prose. `ground_truth/` ties every published
number to the code that produces it: `published_claims.csv` is the
extraction of the article, `build_ground_truth.R` builds the comparison
and gates the pipeline on it. `original/` is created by the download
script and is deliberately absent from the repository. This README is
the reproducibility report, also available as a PDF in `report/`.
`coppock_2019a_errata.pdf` corrects two sentences of the published
article.

**License.** CC0 1.0 Universal, matching the terms of the deposit this
repository maintains. See `LICENSE`.

**To reproduce.** Clone or download the repository, open
`coppock_2019a.Rproj`, and run:

``` r
source("run_all.R")
```

That fetches the deposit, verifies its 38 files, and produces every
table and figure into `maintained/output/`. Required packages:
tidyverse, sandwich, lmtest, estimatr, metap, knitr, kableExtra, here.
`metap` depends on `multtest` from Bioconductor, so it needs
`BiocManager::install("multtest")` before `install.packages("metap")`.
Paths resolve through `here`, so nothing depends on the working
directory. A full run takes about a minute, most of it
`table_2_ri_heterogeneity.R` recomputing 90 randomization inference
tests. A successful run overwrites `maintained/output/`, which is
committed: **`git diff` on that folder is the reproduction check.**

# Paper overview

**Citation**: Coppock, A. (2019). “Generalizing from Survey Experiments
Conducted on Mechanical Turk: A Replication Approach.” *Political
Science Research and Methods*, 7(3), 613-628. DOI: 10.1017/psrm.2018.10

**Replication archive**: <https://doi.org/10.7910/DVN/F1CFFM>

**Summary**: The paper asks whether average treatment effects estimated
on Mechanical Turk generalize to national probability samples. Fifteen
survey experiments, originally fielded on probability or convenience
samples, were replicated on MTurk, and seven were replicated a second
time on TESS/GfK national probability samples. Treatments are framing,
priming and information manipulations; outcomes are attitudes,
standardized by the control group standard deviation in the original
study. Effects are estimated by difference in means with Neyman (HC2)
standard errors. Across 40 treatment-versus-control comparisons the
MTurk and original estimates correlate at 0.85, and a randomization
inference test of the null of treatment effect homogeneity rarely
rejects, which is the mechanism the paper offers for why the samples
agree.

------------------------------------------------------------------------

# Summary

Two questions, answered before the detail.

## Does the deposited archive run?

Not as deposited, and the reasons split cleanly into the trivial and the
substantive.

The trivial ones are two absent packages and a systematic path error.
`metap`, used to combine p-values by Fisher’s method, is not installed
by default and pulls `multtest` from Bioconductor. `commarobust`, which
supplies every standard error in the paper, was never on CRAN and now
cannot be installed in working form at all; that one is treated below,
because it has outgrown the trivial category. The path error is that
eight `load()` calls name files ending `.rdata` when the deposited files
end `.RData`. macOS does not care and Linux does, so six of the
archive’s seven scripts fail on their first data load on any
case-sensitive filesystem. Nothing about the analysis is wrong; the
archive simply cannot start.

The substantive ones are three.

First, two mistyped `sink()` calls silently destroyed two of the
archive’s own outputs. At line 249 of
`coppock_generalizability_appendix.R`, a `sink()` naming Table 1’s file
stands where a bare `sink()` was meant, so instead of closing the Table
6 sink it reopens Table 1’s file and truncates it: the deposited
`..._table_1.txt` is zero bytes. At line 566 the same script writes
Table 15’s results to `..._table_5.txt`, overwriting the Patriot Act
table that belongs there. The deposited `..._table_5.txt` contains the
terrorism spending results, and no `..._table_15.txt` exists. Both
errors are silent, and both survived into the published deposit.

Second, the uncorrected counts in Table 2 do not come back. The cause is
not a bug in the archive but the change R 3.6.0 made to `sample()`,
which replaced the rounding sampler with the rejection sampler and so
changed which permutations a given seed draws. Setting
`RNGkind(sample.kind = "Rounding")` and rerunning reproduces the
deposited output exactly, 2 and 9 and 1 across the three samples, where
the current sampler gives 1 and 8 and 1. The archive is reproducible; it
is reproducible under the R of 2018.

Third, and separately from anything R did, the published Table 2’s N
Significant column is transposed. The deposited output file prints its
three rows in alphabetical order of the sample name, TESS/GfK first and
original last, and the published table prints them in the reverse order,
original first. Table 2’s N Comparisons column was reordered to match,
40 and 40 and 10; its N Significant column was not, so the published 1
in the Original row is the TESS/GfK count and the published 2 in the
TESS/GfK row is the original count. The correct entries in the published
row order are 2, 9 and 1, which is exactly what the deposit produces.
The Holm-corrected column, which is the one the argument rests on, is
symmetric under the same interchange and reproduces exactly under both
samplers.

Fourth, the article’s two power figures are not the ones its own
simulation gives. The section is treated below and in the errata.

## Does the maintained rewrite reproduce the paper?

For 94 of the 100 comparable claims, yes. The correlations that carry
the paper’s argument reproduce to the reported precision (0.85, 0.90,
0.96, 0.85), as does the 72.5 percent replication rate. All 90 published
Table A1 entries reproduce, each an estimate, a standard error and a
significance star; so do all 180 treatment estimate and standard error
cells printed across the seventeen online appendix regression tables.

The 6 claims that do not match fall into three groups. Two are the
uncorrected significant-test counts for MTurk and TESS/GfK in Table 2,
which are sampler-dependent for the reasons above; the rewrite reports
what current R produces rather than reproducing the 2018 draw, because
pinning a deprecated sampler to recover a specific integer would
document the number rather than the finding. Two more are the power
figures the article quotes from Figure 4, which its own deposited
simulation contradicts. The last two are the sentence stating that no
TESS/GfK test was significant, where the deposit says one was, and the
sentence saying the analysis is limited to two dependent variables per
study, which holds or fails depending on what counts as a study.

The substantive claim, that these tests rarely reject the null of
treatment effect homogeneity, holds in every version: at most 9 of 40
comparisons reject before correction and at most 8 after.

------------------------------------------------------------------------

# Original archive reproducibility

| Script | Status on current R | Resolution |
|:---|:---|:---|
| coppock_generalizability_ri_functions.R | Clean (sourced by others; defines no paths) | No changes required |
| coppock_generalizability_analysis.R | Fails on load(); fails again on commarobust | Correct the filename case; inline the retired commarobust call |
| coppock_generalizability_figures.R | Fails on load() | Correct the filename case |
| coppock_generalizability_table.R | Fails on load() | Correct the filename case |
| coppock_generalizability_ri_analysis.R | Fails on load(); fails again on metap and commarobust | Correct the filename case; install multtest and metap |
| coppock_generalizability_simulation.R | Fails on load() | Correct the filename case |
| coppock_generalizability_appendix.R | Fails on load(); writes two outputs to the wrong file | Correct the filename case; correct two sink() calls |

Original archive reproducibility, checked against R 4.6.0 on a
case-sensitive reading of the deposited filenames.

## Filename case

Every deposited data file ends `.RData`. Every script asks for `.rdata`:

| Call site | Filename requested |
|:---|:---|
| coppock_generalizability_analysis.R:20 | coppock_generalizability_studies.rdata |
| coppock_generalizability_figures.R:21 | coppock_generalizability_analysis_results.rdata |
| coppock_generalizability_figures.R:22 | coppock_generalizability_study_data.rdata |
| coppock_generalizability_table.R:22 | coppock_generalizability_analysis_results.rdata |
| coppock_generalizability_table.R:23 | coppock_generalizability_study_data.rdata |
| coppock_generalizability_ri_analysis.R:20 | coppock_generalizability_studies.rdata |
| coppock_generalizability_appendix.R:20 | coppock_generalizability_studies.rdata |
| coppock_generalizability_simulation.R:60 | coppock_generalizability_simulation_results.rdata |

The eight load() calls whose case does not match the deposited files.
Each deposited counterpart ends .RData.

The same defect had propagated into the maintained rewrite, whose six
`load()` calls were copied from the archive. They are corrected here.

## The archive writes into itself

Six of the archive’s scripts write their outputs into the archive
directory, and five of those outputs are themselves deposited files.
Running the deposit in place therefore overwrites part of the deposit:
`coppock_generalizability_analysis_results.RData`, the three figure
PDFs, and `coppock_generalizability_table_2.txt` all change. A seventh
file, `ri_results.rdata`, is created and is not part of the deposit at
all. Rerunning `download_original.R` restores everything, which is the
reason the manifest records checksums rather than trusting whatever
happens to be on disk.

## The standard error package no longer exists

Every estimate in the paper passes through
`commarobust::commarobust_tidy()`. `commarobust` was never on CRAN. Its
author retired it in November 2018 in favour of `estimatr`; the current
GitHub head contains one function, a startup message reading “the
commarobust package has been entirely replaced by the estimatr package”,
and exports nothing. Installing it from the default branch and calling
`commarobust::commarobust` raises “not an exported object”. The last
working code sits on a branch named `legacy`.

An archive whose standard errors depend on an unversioned GitHub branch
is exposed to a decision nobody in this project controls, so the rewrite
does not depend on it. The retired `commarobust(fit)` was exactly

``` r
lmtest::coeftest(fit, sandwich::vcovHC(fit, type = "HC2"))
```

which is what `estimatr::lm_robust()` computes by default: HC2 is both
its default variance estimator and the Neyman variance the paper
reports. Every model in `maintained/analysis_ate_estimates.R` is
therefore fitted with `lm_robust()` directly, and no helper stands
between the call site and the estimator. Reproduction is exact to
floating point: across all 90 estimates the largest disagreement with
the values the archive’s own package produced is 1.4e-12 in the point
estimates and 8.0e-14 in the standard errors.

------------------------------------------------------------------------

# Number-by-number comparison

| Location | Quantity | Paper | Script | Match |
|:---|:---|:---|---:|---:|
| Text, p. 2 | Pairs of estimates entering the correlation | 40 | 40.0000 | 1 |
| Text, p. 2 | MTurk-original correlation | 0.85 | 0.8512 | 1 |
| Text, p. 8 | Original-MTurk pairs of coefficients | 40 | 40.0000 | 1 |
| Text, p. 8 | MTurk-original correlation, restated | 0.85 | 0.8512 | 1 |
| Text, p. 8 | MTurk-original correlation on the TESS/GfK subset | 0.90 | 0.9017 | 1 |
| Text, p. 8 | TESS/GfK-MTurk correlation | 0.96 | 0.9582 | 1 |
| Text, p. 8 | TESS/GfK-original correlation | 0.85 | 0.8517 | 1 |
| Text, p. 8 | Coefficients significant in the original studies | 25 | 25.0000 | 1 |
| Text, p. 8 | Of those, also significant on MTurk | 18 | 18.0000 | 1 |
| Text, p. 8 | Coefficients not significant in the original studies | 15 | 15.0000 | 1 |
| Text, p. 8 | Of those, also not significant on MTurk | 11 | 11.0000 | 1 |
| Text, p. 8 | Replicated significant coefficients, restated inside the formula | 18 | 18.0000 | 1 |
| Text, p. 8 | Replicated null coefficients, restated inside the formula | 11 | 11.0000 | 1 |
| Text, p. 8 | Originally significant coefficients, restated inside the formula | 25 | 25.0000 | 1 |
| Text, p. 8 | Originally null coefficients, restated inside the formula | 15 | 15.0000 | 1 |
| Text, p. 8 | Replication rate as a percentage | 72.5 | 72.5000 | 1 |
| Abstract | Replication experiments reported | 15 | 15.0000 | 1 |
| Text, p. 2 | Replication studies, restated | 15 | 15.0000 | 1 |
| Text, p. 10 | Replications the heterogeneity test covers | 15 | 15.0000 | 1 |
| Text, p. 2 | Study pairs behind the correlation | 12 | 12.0000 | 1 |
| Text, p. 8 | Study pairs, restated | 12 | 12.0000 | 1 |
| Results I heading, p. 5 | Studies the section covers | 12 | 12.0000 | 1 |
| Text, p. 10 | Original studies in the test | 12 | 12.0000 | 1 |
| Text, p. 10 | Original studies, restated in the sentence | 12 | 12.0000 | 1 |
| Text, p. 10 | Study versions the test covers | 27 | 27.0000 | 1 |
| Text, p. 8 | Coefficients behind the correlation | 40 | 40.0000 | 1 |
| Text, pp. 5-6 | Studies replicated on both platforms | 3 | 3.0000 | 1 |
| Text, p. 5 | Cases with a fresh probability sample | 3 | 3.0000 | 1 |
| Text, p. 8 | Studies with a TESS/GfK version | 3 | 3.0000 | 1 |
| Text, p. 8 | Coefficients in those studies | 10 | 10.0000 | 1 |
| Text, p. 2 | Degrees of freedom of the correlation | 38 | 38.0000 | 1 |
| Text, p. 8 | Degrees of freedom, restated | 38 | 38.0000 | 1 |
| Text, p. 8 | Degrees of freedom on the TESS/GfK subset | 8 | 8.0000 | 1 |
| Text, p. 8 | Degrees of freedom, TESS/GfK against MTurk | 8 | 8.0000 | 1 |
| Text, p. 8 | Degrees of freedom, TESS/GfK against original | 8 | 8.0000 | 1 |
| Figure 2 | Facets, one per study | 12 | 12.0000 | 1 |
| Figure 2 | Estimates plotted | 90 | 90.0000 | 1 |
| Figure 2 | Facets carrying two study versions | 9 | NA | NA |
| Figure 2 | Facets carrying three study versions | 3 | NA | NA |
| Figure 2 | Versions in each two-version facet | 2 | NA | NA |
| Figure 2 | Versions in each three-version facet | 3 | NA | NA |
| Figure 2 | Confidence level of the plotted intervals | 95 | NA | NA |
| Figure 3 | Coefficient pairs plotted | 40 | 40.0000 | 1 |
| Figure 3 | Confidence level of the plotted intervals | 95 | NA | NA |
| Text, p. 10 | Simulation parameters varied | 2 | NA | NA |
| Figure 4 | Heterogeneity scale named for the high-power claim | 0.2 | 0.2000 | 1 |
| Figure 4 | Heterogeneity scale named for the moderate-power claim | 0.1 | 0.1000 | 1 |
| Figure 4 | Simulated power at 0.2 SD and 500 subjects per arm | 0.8 | 0.6100 | 0 |
| Figure 4 | Simulated power at 0.1 SD and 500 subjects per arm | 0.6 | 0.1500 | 0 |
| Table 1 | Estimates reported for concealed_carry | 1 | 1.0000 | 1 |
| Table 1 | Estimates reported for death_penalty | 1 | 1.0000 | 1 |
| Table 1 | Estimates reported for elite_endorsements | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for expert_economists | 5 | 5.0000 | 1 |
| Table 1 | Estimates reported for frame_breadth | 4 | 4.0000 | 1 |
| Table 1 | Estimates reported for free_trade | 4 | 4.0000 | 1 |
| Table 1 | Estimates reported for immigration | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for mental_illness | 6 | 6.0000 | 1 |
| Table 1 | Estimates reported for patriot_act | 9 | 9.0000 | 1 |
| Table 1 | Estimates reported for polarization | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for superordinate_id | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for system_threat | 2 | 2.0000 | 1 |
| Table 1 | Subjects in the original Haider-Markel and Joslyn (2001) analysis | 518 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Haider-Markel and Joslyn (2001) | 1009 | NA | NA |
| Table 1 | Subjects in the original Brader (2005) analysis | 281 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Brader (2005) | 1709 | NA | NA |
| Table 1 | Subjects in the original Peffley and Hurwitz (2007) analysis | 905 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Peffley and Hurwitz (2007) | 1285 | NA | NA |
| Table 1 | Subjects in the original Transue (2007) analysis | 345 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Transue (2007) | 367 | NA | NA |
| Table 1 | Subjects in the original Chong and Druckman (2010) analysis | 1302 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Chong and Druckman (2010) | 1887 | NA | NA |
| Table 1 | Subjects in the original Nicholson (2012) analysis | 1491 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Nicholson (2012) | 1249 | NA | NA |
| Table 1 | Subjects in the original McGinty, Webster and Barry (2013) analysis | 2935 | NA | NA |
| Table 1 | Subjects in the MTurk replication of McGinty, Webster and Barry (2013) | 2487 | NA | NA |
| Table 1 | Subjects in the original Craig and Richeson (2014) analysis | 611 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Craig and Richeson (2014) | 709 | NA | NA |
| Table 1 | Subjects in the original Johnston and Ballard (2016) analysis | 2041 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Johnston and Ballard (2016) | 2985 | NA | NA |
| Table 1 | Subjects in the original Hiscox (2006) analysis | 1610 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Hiscox (2006) | 2972 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Hiscox (2006) | 2084 | NA | NA |
| Table 1 | Subjects in the original Levendusky and Malhotra (2016) analysis | 1041 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Levendusky and Malhotra (2016) | 1987 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Levendusky and Malhotra (2016) | 1411 | NA | NA |
| Table 1 | Subjects in the original Hopkins and Mummolo (2017) analysis | 3269 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Hopkins and Mummolo (2017) | 2972 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Hopkins and Mummolo (2017) | 3189 | NA | NA |
| Table 2 | Table 2, original, comparisons tested | 40 | 40.0000 | 1 |
| Table 2 | Table 2, original, significant after the Holm correction | 0 | 0.0000 | 1 |
| Table 2 | Table 2, mt, comparisons tested | 40 | 40.0000 | 1 |
| Table 2 | Table 2, mt, significant after the Holm correction | 8 | 8.0000 | 1 |
| Table 2 | Table 2, gfk, comparisons tested | 10 | 10.0000 | 1 |
| Table 2 | Table 2, gfk, significant after the Holm correction | 0 | 0.0000 | 1 |
| Table 2 | Table 2, original, significant before correction | 1 | 2.0000 | 0 |
| Table 2 | Table 2, MTurk, significant before correction | 9 | 9.0000 | 1 |
| Table 2 | Table 2, TESS/GfK, significant before correction | 2 | 1.0000 | 0 |
| Text, p. 10 | Original comparisons tested, as the text states them | 40 | 40.0000 | 1 |
| Text, p. 10 | MTurk comparisons tested, as the text states them | 40 | 40.0000 | 1 |
| Text, p. 10 | TESS/GfK comparisons tested, as the text states them | 10 | 10.0000 | 1 |
| Text, p. 10 | Original comparisons the text says rejected homogeneity | 1 | 2.0000 | 0 |
| Text, p. 10 | MTurk comparisons the text says rejected homogeneity | 8 | 9.0000 | 0 |
| Text, p. 10 | TESS/GfK comparisons the text says rejected homogeneity | 0 | 1.0000 | 0 |
| Table A1 | Table A1 original entries reproduced of 40 published | 40 | 40.0000 | 1 |
| Table A1 | Table A1 mt entries reproduced of 40 published | 40 | 40.0000 | 1 |
| Table A1 | Table A1 gfk entries reproduced of 10 published | 10 | 10.0000 | 1 |
| Online Appendix Table 1 | Treatment estimate and standard error cells reproduced of 4 published | 4 | NA | NA |
| Online Appendix Table 1 | Intercept, sample size and R-squared cells of appendix Table 1 (Gun Control) | 8 | NA | NA |
| Online Appendix Table 2 | Treatment estimate and standard error cells reproduced of 8 published | 8 | NA | NA |
| Online Appendix Table 2 | Intercept, sample size and R-squared cells of appendix Table 2 (Immigration) | 16 | NA | NA |
| Online Appendix Table 3 | Treatment estimate and standard error cells reproduced of 4 published | 4 | NA | NA |
| Online Appendix Table 3 | Intercept, sample size and R-squared cells of appendix Table 3 (Death Penalty) | 8 | NA | NA |
| Online Appendix Table 4 | Treatment estimate and standard error cells reproduced of 8 published | 8 | NA | NA |
| Online Appendix Table 4 | Intercept, sample size and R-squared cells of appendix Table 4 (Superordinate Identity) | 8 | NA | NA |
| Online Appendix Table 5 | Treatment estimate and standard error cells reproduced of 36 published | 36 | NA | NA |
| Online Appendix Table 5 | Intercept, sample size and R-squared cells of appendix Table 5 (Patriot Act) | 8 | NA | NA |
| Online Appendix Table 6 | Treatment estimate and standard error cells reproduced of 8 published | 8 | NA | NA |
| Online Appendix Table 6 | Intercept, sample size and R-squared cells of appendix Table 6 (Elite Endorsements) | 24 | NA | NA |
| Online Appendix Table 7 | Treatment estimate and standard error cells reproduced of 24 published | 24 | NA | NA |
| Online Appendix Table 7 | Intercept, sample size and R-squared cells of appendix Table 7 (Mental Illness) | 16 | NA | NA |
| Online Appendix Table 8 | Treatment estimate and standard error cells reproduced of 8 published | 8 | NA | NA |
| Online Appendix Table 8 | Intercept, sample size and R-squared cells of appendix Table 8 (System Threat) | 16 | NA | NA |
| Online Appendix Table 9 | Treatment estimate and standard error cells reproduced of 12 published | 12 | NA | NA |
| Online Appendix Table 9 | Intercept, sample size and R-squared cells of appendix Table 9 (Expert Economists: Immigration, Health Care and China) | 24 | NA | NA |
| Online Appendix Table 10 | Treatment estimate and standard error cells reproduced of 8 published | 8 | NA | NA |
| Online Appendix Table 10 | Intercept, sample size and R-squared cells of appendix Table 10 (Expert Economists: Tax Cuts and Gold Standard) | 16 | NA | NA |
| Online Appendix Table 11 | Treatment estimate and standard error cells reproduced of 24 published | 24 | NA | NA |
| Online Appendix Table 11 | Intercept, sample size and R-squared cells of appendix Table 11 (Free Trade) | 12 | NA | NA |
| Online Appendix Table 12 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 12 | Intercept, sample size and R-squared cells of appendix Table 12 (Extremity) | 12 | NA | NA |
| Online Appendix Table 13 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 13 | Intercept, sample size and R-squared cells of appendix Table 13 (Perceived Polarization) | 12 | NA | NA |
| Online Appendix Table 14 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 14 | Intercept, sample size and R-squared cells of appendix Table 14 (Crime Spending) | 12 | NA | NA |
| Online Appendix Table 15 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 15 | Intercept, sample size and R-squared cells of appendix Table 15 (Health Care Spending) | 12 | NA | NA |
| Online Appendix Table 16 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 16 | Intercept, sample size and R-squared cells of appendix Table 16 (Stimulus Spending) | 12 | NA | NA |
| Online Appendix Table 17 | Treatment estimate and standard error cells reproduced of 6 published | 6 | NA | NA |
| Online Appendix Table 17 | Intercept, sample size and R-squared cells of appendix Table 17 (Terrorism Spending) | 12 | NA | NA |
| Text, p. 6 | Most dependent variables in any of the deposit’s study groupings | 2 | 5.0000 | 0 |
| Footnote 5 | Mean absolute standardized effect | 0.2 | 0.2002 | 1 |
| Text, p. 8 | Pairs significant in both versions with opposite signs | 0 | 0.0000 | 1 |
| Text, pp. 10-11 | Comparisons rejecting homogeneity in more than one sample | 1 | NA | NA |
| Figure 4 | Subjects per treatment arm the MTurk replications typically employ | 500 | NA | NA |

Ground truth: 145 rows, comparing the published value to the deposit’s
own committed output.

67 of the 75 published values with an archive counterpart are reproduced
by the deposit’s own committed output. `value_script` is read out of the
objects and text files the archive itself deposited rather than typed or
produced by re-running anything, and it is blank where the deposit
prints nothing: Table 1’s sample sizes, and the online appendix
regression tables, whose deposited text files include two the archive’s
own mistyped `sink()` calls destroyed.

## Table 2 in full

| Cell | Table 2 | Body text | Deposited output | Rounding sampler, 2026 | Current sampler, 2026 |
|:---|---:|:---|---:|---:|---:|
| Original, uncorrected | 1 | 1 | 2 | 2 | 1 |
| Mechanical Turk, uncorrected | 9 | 8 | 9 | 9 | 8 |
| TESS/GfK, uncorrected | 2 | 0 | 1 | 1 | 1 |
| Original, Holm | 0 |  | 0 | 0 | 0 |
| Mechanical Turk, Holm | 8 |  | 8 | 8 | 8 |
| TESS/GfK, Holm | 0 | 0 | 0 | 0 | 0 |

Table 2’s counts of significant homogeneity tests, from five sources.
‘Deposited output’ is the archive’s own table 2 text file as it sits in
the deposit. ‘Rounding sampler’ restores the pre-R-3.6.0 behaviour of
the sampler behind sample().

Three things follow. The archive is internally reproducible: the
rounding sampler recovers the deposited output in every cell. The R
3.6.0 sampler change moves two cells, the MTurk and original counts,
because one test in each of those samples has a maximum p-value of
exactly 0.05 under the 2018 draw and none does under the current one.

And the published table’s N Significant column is the deposited column
in the deposited file’s own row order. That file prints its rows
alphabetically, `gfk` then `mt` then `original`, and reads 1, 9, 2 down
the column. The published table prints its rows in the reverse order,
Original then Mechanical Turk then TESS/GfK, and its N Significant
column also reads 1, 9, 2. The N Comparisons column beside it was
reordered correctly, 40 and 40 and 10 rather than 10 and 40 and 40,
which is why the interchange is invisible from inside the table. The
Holm column is symmetric under it and so cannot show it either. Under
this reading every cell of the published table is accounted for: the
correct entries in the published row order are 2, 9 and 1.

The alternative, that Table 2 was typeset from a run other than the one
deposited, does not survive measurement.
`ground_truth/measure_table_2_dispersion.R` runs the deposited procedure
over a range of seeds under both samplers and records what it gets:

| Sample   | Sampler   | Runs | N Significant, values taken |
|:---------|:----------|-----:|:----------------------------|
| gfk      | rejection |   16 | 1                           |
| gfk      | rounding  |    8 | 1                           |
| mt       | rejection |   16 | 8, 9, 10                    |
| mt       | rounding  |    8 | 8, 9, 10                    |
| original | rejection |   16 | 1, 2                        |
| original | rounding  |    8 | 1, 2                        |

Counts of significant homogeneity tests across 24 runs of the deposited
procedure at different seeds.

The TESS/GfK count was 1 in every one of the 24 runs and never 2, while
the original and MTurk counts both moved. A published TESS/GfK count of
2 is not something the deposited code produces.

The body text is a separate matter and is not settled by any of this. It
reads 1, 8 and 0 where the deposit reads 2, 9 and 1. Its first two
figures are the counts a strict `<` 0.05 would give on the deposit’s own
draw, where Table 2’s own rule is `<=`, so the sentence and the table
can differ legitimately by one in each of those samples. Its third
figure has no such account: the TESS/GfK count is 1 under either rule
and under either sampler. That sentence is corrected in
`coppock_2019a_errata.pdf`; the other two are recorded as unresolved.

------------------------------------------------------------------------

# Maintained rewrite

`maintained/` holds eight scripts and a shared `helpers.R`, replacing
the archive’s six analysis scripts and its function file. The rewrite is
a translation: estimators, specifications and sample restrictions are
unchanged.

| Script | Output |
|:---|:---|
| helpers.R | packages; Table A1 cell formatter |
| analysis_ate_estimates.R | output/analysis_results.rds |
| table_a1_ate_summary.R | output/table_a1_ate_summary.csv, .tex |
| table_2_ri_heterogeneity.R | output/table_2_ri_heterogeneity.csv, .tex, output/ri_results.rds |
| figure_2_study_estimates.R | output/figure_2_study_estimates.csv, .pdf, .png |
| figure_3_mt_original_scatter.R | output/figure_3_mt_original_scatter.csv, .pdf, .png |
| figure_4_power_simulation.R | output/figure_4_power_simulation.csv, .pdf, .png |
| text_correlations.R | output/text_correlations.csv |
| in_text_claims.R | printed CLAIM lines only |

Maintained rewrite script inventory.

## Deprecated patterns replaced

| Original pattern | Replacement |
|:---|:---|
| `rm(list = ls())` | (omitted) |
| `setwd(\"\")` | `here::here()` |
| `load(\"...rdata\")` against a `.RData` file | the deposited filename, exact case |
| `commarobust::commarobust_tidy()` | `estimatr::lm_robust()`, whose default is HC2 |
| `do(...$summary_df)` | `reframe(...)` with `pick(everything())` |
| `spread()` / `gather()` | `pivot_wider()` / `pivot_longer()` |
| `geom_errorbarh()` | `geom_linerange()` |
| `ggstance::position_dodgev()` | `position_dodge(width = 0.5)` |
| `reshape2::melt()` | (the archive’s saved result is read directly) |
| `sink()` to a hardcoded path | `write_csv()` and `readr::write_lines()` to `output/` |
| magrittr pipes | the native pipe |

Deprecated patterns and their replacements in the maintained rewrite.

## What the rewrite does not cover

The archive’s `coppock_generalizability_appendix.R` produces the
seventeen per-study regression tables of the online appendix. Each
prints the same treatment coefficients the rewrite estimates, to three
decimal places rather than Table A1’s two, and every one of those 180
cells reproduces. Each table also prints an intercept, a sample size and
an R-squared, and appendix Table 6 prints a party identification
covariate. The rewrite drops the intercept and that covariate before
writing its estimates and exports neither sample sizes nor R-squared, so
those cells have no counterpart in `maintained/output/`; the ground
truth records them as uncovered rather than as reproduced. Table 1’s
sample size columns are uncovered for the same reason.

Figure 1 is uncovered by anything. It illustrates the theoretical
argument with a simulated population, and no script in the deposit draws
it.

The rewrite also does not re-run the power simulation behind Figure 4.
Neither does the archive: the simulation is commented out in
`coppock_generalizability_simulation.R`, with a note that it “takes a
*very* long time to run”, and the deposited result object is loaded
instead. The figure is reproduced from that object, and
`figure_4_power_simulation.R` now writes the plotted grid to a CSV so
the numbers the text quotes from it have a source.

## The power sentence

The article says of Figure 4 that at 500 subjects per treatment arm “we
would be well powered (power $\approx$ 0.8) to detect treatment effect
heterogeneity on the scale of 0.2 SD, and moderately powered for 0.1 SD
(power $\approx$ 0.6).”

| Heterogeneity scale | Power stated in the text | Power in the deposited simulation |
|:---|:---|:---|
| 0.2 SD | 0.8 | 0.61 |
| 0.1 SD | 0.6 | 0.15 |

The two power figures the article quotes, against the simulation results
it deposits, both at 500 subjects per treatment arm.

Figure 4 draws a dashed guide line at 500 subjects and another at power
0.8, and annotates the 0.2 SD curve where it crosses the second of them.
The curve first reaches 0.8 at 600 subjects per arm, not 500, so the
sentence reads the height of the guide line rather than the curve. The
figure is right; the sentence is not, and it is corrected in
`coppock_2019a_errata.pdf`. The claim the paper rests on, that the tests
are powered against politically meaningful heterogeneity, survives at
0.2 SD and is weaker at 0.1 SD than the text says.

## Determinism

`table_2_ri_heterogeneity.R` sets the archive’s seed once and recomputes
all 90 tests on every run rather than reading back a cached result. Two
independent runs, five months apart on different R versions, agree in
every one of the 90 p-values to the last bit. The 90 tests take a
minute. The script deliberately does not skip its work when
`output/ri_results.rds` already exists: a script that does that cannot
be checked by diffing its own output, which is what this repository asks
a reader to do.

------------------------------------------------------------------------

# Figures

<img src="maintained/output/figure_2_study_estimates.png"
style="width:100.0%"
alt="Figure 2: standardized ATE estimates by study and sample." />

<img src="maintained/output/figure_3_mt_original_scatter.png"
style="width:80.0%"
alt="Figure 3: MTurk versus original standardized estimates." />

<img src="maintained/output/figure_4_power_simulation.png"
style="width:80.0%"
alt="Figure 4: power of the homogeneity test by sample size and effect heterogeneity." />

------------------------------------------------------------------------

# Tables

| Sample   | N comparisons | N significant | N significant (Holm) |
|:---------|--------------:|--------------:|---------------------:|
| gfk      |            10 |             1 |                    0 |
| mt       |            40 |             8 |                    8 |
| original |            40 |             1 |                    0 |

Table 2 as the maintained rewrite produces it.

| Study | Outcome | Coefficient | Original | MTurk | GfK |
|:---|:---|:---|:---|:---|:---|
| Haider-Markel and Joslyn (2001) | Support for Concealed Carry Law | Citizens’ Rights Frame | 0.33 (0.08)\* | 0.21 (0.05)\* | NA |
| Brader (2005) | Negative Impact | Positive Frame | -0.28 (0.13)\* | -0.22 (0.04)\* | NA |
| NA | Support for Immigration | Positive Frame | 0.39 (0.14)\* | 0.26 (0.05)\* | NA |
| Peffley and Hurwitz (2007) | Favor Death Penalty | African Americans | 0.42 (0.09)\* | 0.10 (0.05)\* | NA |
| Transue (2007) | Willingness to Pay Tax | Other Americans | 0.18 (0.10) | -0.08 (0.10) | NA |
| NA | Willingness to Pay Tax | Public Schools | 0.16 (0.10) | 0.19 (0.09)\* | NA |
| Chong and Druckman (2010) | Patriot Act Support | Con / Memory Based | -0.38 (0.12)\* | -0.18 (0.11) | NA |
| NA | Patriot Act Support | Con / No Processing | -0.41 (0.13)\* | -0.39 (0.11)\* | NA |
| NA | Patriot Act Support | Con / Online Processing | -0.45 (0.12)\* | -0.40 (0.11)\* | NA |
| NA | Patriot Act Support | Pro / Memory Based | 0.33 (0.12)\* | 0.20 (0.11) | NA |
| NA | Patriot Act Support | Pro / No Processing | 0.43 (0.12)\* | 0.32 (0.11)\* | NA |
| NA | Patriot Act Support | Pro / Online Processing | 0.33 (0.12)\* | 0.27 (0.11)\* | NA |
| NA | Patriot Act Support | Both / Memory Based | -0.07 (0.14) | -0.10 (0.12) | NA |
| NA | Patriot Act Support | Both / No Processing | -0.08 (0.16) | 0.01 (0.13) | NA |
| NA | Patriot Act Support | Both / Online Processing | 0.01 (0.13) | -0.16 (0.13) | NA |
| Nicholson (2012) | Support for Foreclosure Bill | In Party Cue | 0.18 (0.08)\* | 0.11 (0.07) | NA |
| NA | Support for Immigration Bill | In Party Cue | 0.23 (0.09)\* | 0.10 (0.06) | NA |
| McGinty, Webster, and Barry (2013) | Magazines | News | 0.11 (0.04)\* | 0.01 (0.04) | NA |
| NA | Magazines | LCM Ban | 0.18 (0.06)\* | 0.12 (0.05)\* | NA |
| NA | Magazines | Mental Illness | 0.10 (0.05) | -0.01 (0.05) | NA |
| NA | SMI Danger | News | 0.09 (0.05) | 0.02 (0.04) | NA |
| NA | SMI Danger | LCM Ban | -0.07 (0.06) | 0.01 (0.05) | NA |
| NA | SMI Danger | Mental Illness | -0.12 (0.06)\* | -0.08 (0.05) | NA |
| Craig and Richeson (2014) | Support for Immigration | Majority Minority | -0.00 (0.10) | -0.22 (0.07)\* | NA |
| NA | Way of Life | Majority Minority | -0.14 (0.11) | 0.08 (0.07) | NA |
| Johnston and Ballard (2016) | Agree on Gold Standard | Expert Treatment | 0.38 (0.11)\* | 0.50 (0.04)\* | NA |
| NA | Agree on Health Care | Expert Treatment | 0.15 (0.10) | 0.34 (0.04)\* | NA |
| NA | Agree on Immigration | Expert Treatment | 0.14 (0.11) | 0.33 (0.04)\* | NA |
| NA | Agree on Tax Cut | Expert Treatment | 0.35 (0.10)\* | 0.44 (0.04)\* | NA |
| NA | Agree on Trade with China | Expert Treatment | 0.24 (0.10)\* | 0.42 (0.04)\* | NA |
| Hiscox (2006) | Support for Free Trade | Expert | 0.25 (0.06)\* | 0.28 (0.03)\* | 0.17 (0.05)\* |
| NA | Support for Free Trade | Positive | -0.17 (0.08)\* | -0.08 (0.04) | -0.03 (0.07) |
| NA | Support for Free Trade | Negative | -0.28 (0.08)\* | -0.32 (0.05)\* | -0.32 (0.07)\* |
| NA | Support for Free Trade | Pos + Neg | -0.41 (0.09)\* | -0.33 (0.05)\* | -0.23 (0.07)\* |
| Levendusky and Malhotra (2015) | Extremity of Policy Views | Polarizied Treatment | 0.02 (0.08) | -0.05 (0.04) | 0.05 (0.06) |
| NA | Perceived Polarization | Polarizied Treatment | 0.16 (0.08)\* | 0.36 (0.05)\* | 0.47 (0.08)\* |
| Hopkins and Mummolo (2017) | Support for Crime Spending | Crime Argument | 0.06 (0.05) | -0.01 (0.05) | 0.09 (0.05) |
| NA | Support for Health Care Spending | Health Care Argument | -0.03 (0.05) | -0.05 (0.04) | -0.03 (0.05) |
| NA | Support for Stimulus Spending | Stimulus Argument | -0.16 (0.04)\* | -0.21 (0.04)\* | -0.23 (0.04)\* |
| NA | Support for Terrorism Spending | Terrorism Argument | 0.25 (0.05)\* | 0.11 (0.05)\* | 0.18 (0.06)\* |

Table A1 as the maintained rewrite produces it: standardized ATE
estimates by study, outcome and sample, with HC2 standard errors in
parentheses.

------------------------------------------------------------------------

# The extraction and the two instruments

Every published number in this article and its online appendix is
written down once, in `ground_truth/published_claims.csv`. That file is
the extraction: 204 rows, each carrying a claim identifier, where the
number appears, what kind of claim it is, the string the page prints and
the number of decimals it prints it to. It is the only place in the
repository a published number is typed, and nothing in `maintained/`
reads it except for those decimal counts.

| Claim type   | Needs a claim block | Claims |
|:-------------|:--------------------|-------:|
| definitional | no                  |     35 |
| definitional | yes                 |      9 |
| descriptive  | no                  |      1 |
| descriptive  | yes                 |      4 |
| pipeline     | no                  |     44 |
| pipeline     | yes                 |     65 |
| structural   | no                  |     16 |
| structural   | yes                 |     22 |
| transcribed  | no                  |      8 |

The extraction: 204 published claims, classified by hand.

A `pipeline` claim is one the analysis produces; `descriptive` claims
are about shape, sign or count and have no printed number to compare;
`definitional` and `structural` claims are design parameters and layout
facts; `transcribed` claims are copied from other articles and cannot
drift. The `needs_block` column is TRUE where the pipeline can print
something true about the claim, which is 100 of the 204. The remainder
are verified where they are used: the confidence level of the
plausible-effects interval is visible in the `qnorm(0.9999)` call the
archive’s own function file makes, Figure 4’s guide lines in the
`geom_hline()` and `geom_vline()` that draw them, and the significance
threshold behind Table A1’s stars in `helpers.R`.

Two separate instruments then check the same claims.

`ground_truth/build_ground_truth.R` assembles the comparison table. It
reads `value_rewrite` back out of `maintained/output/` and
`value_script` out of the objects and text files the archive deposited,
so neither column can drift from what it describes, and it compares each
against the published string by printing the computed number to the
page’s own precision rather than by a numeric tolerance, because a
double does not record how many decimals the article printed.

`maintained/in_text_claims.R` carries one block per claim needing one:
the article’s sentence verbatim in a comment, then code that recomputes
the number from the same committed outputs by its own path. It never
reads the ground truth. The two reach the same quantities differently,
so a disagreement between them is a finding rather than a formality: the
ground truth reads the correlations out of `text_correlations.csv` while
the claims file rebuilds them from the estimates.

The build script is the gate. It runs `in_text_claims.R`
non-interactively into its own environment, counts the `CLAIM` lines it
printed, and stops unless that count equals the 100 claims the
extraction says need one, every identifier appears on both sides, every
`pipeline` and `descriptive` claim has a ground truth row, every
published float has coverage or a stated reason, every adverse verdict
carries a `defect_locus` and no clean match does, and the two
instruments agree value by value. A block that errored, or that ended in
a bare expression and so printed nothing, would satisfy a scan for
markers while checking nothing, which is why the file is run rather than
read.

Two sentences of the published article are corrected in
`coppock_2019a_errata.pdf` at the root of this repository. Neither
changes a conclusion.

# Maintained rewrite verification

| Location | Quantity | Paper | Rewrite | Match |
|:---|:---|:---|---:|---:|
| Text, p. 2 | Pairs of estimates entering the correlation | 40 | 40.0000 | 1 |
| Text, p. 2 | MTurk-original correlation | 0.85 | 0.8512 | 1 |
| Text, p. 8 | Original-MTurk pairs of coefficients | 40 | 40.0000 | 1 |
| Text, p. 8 | MTurk-original correlation, restated | 0.85 | 0.8512 | 1 |
| Text, p. 8 | MTurk-original correlation on the TESS/GfK subset | 0.90 | 0.9017 | 1 |
| Text, p. 8 | TESS/GfK-MTurk correlation | 0.96 | 0.9582 | 1 |
| Text, p. 8 | TESS/GfK-original correlation | 0.85 | 0.8517 | 1 |
| Text, p. 8 | Coefficients significant in the original studies | 25 | 25.0000 | 1 |
| Text, p. 8 | Of those, also significant on MTurk | 18 | 18.0000 | 1 |
| Text, p. 8 | Coefficients not significant in the original studies | 15 | 15.0000 | 1 |
| Text, p. 8 | Of those, also not significant on MTurk | 11 | 11.0000 | 1 |
| Text, p. 8 | Replicated significant coefficients, restated inside the formula | 18 | 18.0000 | 1 |
| Text, p. 8 | Replicated null coefficients, restated inside the formula | 11 | 11.0000 | 1 |
| Text, p. 8 | Originally significant coefficients, restated inside the formula | 25 | 25.0000 | 1 |
| Text, p. 8 | Originally null coefficients, restated inside the formula | 15 | 15.0000 | 1 |
| Text, p. 8 | Replication rate as a percentage | 72.5 | 72.5000 | 1 |
| Abstract | Replication experiments reported | 15 | 15.0000 | 1 |
| Text, p. 2 | Replication studies, restated | 15 | 15.0000 | 1 |
| Text, p. 10 | Replications the heterogeneity test covers | 15 | 15.0000 | 1 |
| Text, p. 2 | Study pairs behind the correlation | 12 | 12.0000 | 1 |
| Text, p. 8 | Study pairs, restated | 12 | 12.0000 | 1 |
| Results I heading, p. 5 | Studies the section covers | 12 | 12.0000 | 1 |
| Text, p. 10 | Original studies in the test | 12 | 12.0000 | 1 |
| Text, p. 10 | Original studies, restated in the sentence | 12 | 12.0000 | 1 |
| Text, p. 10 | Study versions the test covers | 27 | 27.0000 | 1 |
| Text, p. 8 | Coefficients behind the correlation | 40 | 40.0000 | 1 |
| Text, pp. 5-6 | Studies replicated on both platforms | 3 | 3.0000 | 1 |
| Text, p. 5 | Cases with a fresh probability sample | 3 | 3.0000 | 1 |
| Text, p. 8 | Studies with a TESS/GfK version | 3 | 3.0000 | 1 |
| Text, p. 8 | Coefficients in those studies | 10 | 10.0000 | 1 |
| Text, p. 2 | Degrees of freedom of the correlation | 38 | 38.0000 | 1 |
| Text, p. 8 | Degrees of freedom, restated | 38 | 38.0000 | 1 |
| Text, p. 8 | Degrees of freedom on the TESS/GfK subset | 8 | 8.0000 | 1 |
| Text, p. 8 | Degrees of freedom, TESS/GfK against MTurk | 8 | 8.0000 | 1 |
| Text, p. 8 | Degrees of freedom, TESS/GfK against original | 8 | 8.0000 | 1 |
| Figure 2 | Facets, one per study | 12 | 12.0000 | 1 |
| Figure 2 | Estimates plotted | 90 | 90.0000 | 1 |
| Figure 2 | Facets carrying two study versions | 9 | 9.0000 | 1 |
| Figure 2 | Facets carrying three study versions | 3 | 3.0000 | 1 |
| Figure 2 | Versions in each two-version facet | 2 | 2.0000 | 1 |
| Figure 2 | Versions in each three-version facet | 3 | 3.0000 | 1 |
| Figure 2 | Confidence level of the plotted intervals | 95 | 95.0004 | 1 |
| Figure 3 | Coefficient pairs plotted | 40 | 40.0000 | 1 |
| Figure 3 | Confidence level of the plotted intervals | 95 | 95.0004 | 1 |
| Text, p. 10 | Simulation parameters varied | 2 | 2.0000 | 1 |
| Figure 4 | Heterogeneity scale named for the high-power claim | 0.2 | 0.2000 | 1 |
| Figure 4 | Heterogeneity scale named for the moderate-power claim | 0.1 | 0.1000 | 1 |
| Figure 4 | Simulated power at 0.2 SD and 500 subjects per arm | 0.8 | 0.6100 | 0 |
| Figure 4 | Simulated power at 0.1 SD and 500 subjects per arm | 0.6 | 0.1500 | 0 |
| Table 1 | Estimates reported for concealed_carry | 1 | 1.0000 | 1 |
| Table 1 | Estimates reported for death_penalty | 1 | 1.0000 | 1 |
| Table 1 | Estimates reported for elite_endorsements | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for expert_economists | 5 | 5.0000 | 1 |
| Table 1 | Estimates reported for frame_breadth | 4 | 4.0000 | 1 |
| Table 1 | Estimates reported for free_trade | 4 | 4.0000 | 1 |
| Table 1 | Estimates reported for immigration | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for mental_illness | 6 | 6.0000 | 1 |
| Table 1 | Estimates reported for patriot_act | 9 | 9.0000 | 1 |
| Table 1 | Estimates reported for polarization | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for superordinate_id | 2 | 2.0000 | 1 |
| Table 1 | Estimates reported for system_threat | 2 | 2.0000 | 1 |
| Table 1 | Subjects in the original Haider-Markel and Joslyn (2001) analysis | 518 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Haider-Markel and Joslyn (2001) | 1009 | NA | NA |
| Table 1 | Subjects in the original Brader (2005) analysis | 281 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Brader (2005) | 1709 | NA | NA |
| Table 1 | Subjects in the original Peffley and Hurwitz (2007) analysis | 905 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Peffley and Hurwitz (2007) | 1285 | NA | NA |
| Table 1 | Subjects in the original Transue (2007) analysis | 345 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Transue (2007) | 367 | NA | NA |
| Table 1 | Subjects in the original Chong and Druckman (2010) analysis | 1302 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Chong and Druckman (2010) | 1887 | NA | NA |
| Table 1 | Subjects in the original Nicholson (2012) analysis | 1491 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Nicholson (2012) | 1249 | NA | NA |
| Table 1 | Subjects in the original McGinty, Webster and Barry (2013) analysis | 2935 | NA | NA |
| Table 1 | Subjects in the MTurk replication of McGinty, Webster and Barry (2013) | 2487 | NA | NA |
| Table 1 | Subjects in the original Craig and Richeson (2014) analysis | 611 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Craig and Richeson (2014) | 709 | NA | NA |
| Table 1 | Subjects in the original Johnston and Ballard (2016) analysis | 2041 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Johnston and Ballard (2016) | 2985 | NA | NA |
| Table 1 | Subjects in the original Hiscox (2006) analysis | 1610 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Hiscox (2006) | 2972 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Hiscox (2006) | 2084 | NA | NA |
| Table 1 | Subjects in the original Levendusky and Malhotra (2016) analysis | 1041 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Levendusky and Malhotra (2016) | 1987 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Levendusky and Malhotra (2016) | 1411 | NA | NA |
| Table 1 | Subjects in the original Hopkins and Mummolo (2017) analysis | 3269 | NA | NA |
| Table 1 | Subjects in the MTurk replication of Hopkins and Mummolo (2017) | 2972 | NA | NA |
| Table 1 | Subjects in the TESS/GfK replication of Hopkins and Mummolo (2017) | 3189 | NA | NA |
| Table 2 | Table 2, original, comparisons tested | 40 | 40.0000 | 1 |
| Table 2 | Table 2, original, significant after the Holm correction | 0 | 0.0000 | 1 |
| Table 2 | Table 2, mt, comparisons tested | 40 | 40.0000 | 1 |
| Table 2 | Table 2, mt, significant after the Holm correction | 8 | 8.0000 | 1 |
| Table 2 | Table 2, gfk, comparisons tested | 10 | 10.0000 | 1 |
| Table 2 | Table 2, gfk, significant after the Holm correction | 0 | 0.0000 | 1 |
| Table 2 | Table 2, original, significant before correction | 1 | 1.0000 | 1 |
| Table 2 | Table 2, MTurk, significant before correction | 9 | 8.0000 | 0 |
| Table 2 | Table 2, TESS/GfK, significant before correction | 2 | 1.0000 | 0 |
| Text, p. 10 | Original comparisons tested, as the text states them | 40 | 40.0000 | 1 |
| Text, p. 10 | MTurk comparisons tested, as the text states them | 40 | 40.0000 | 1 |
| Text, p. 10 | TESS/GfK comparisons tested, as the text states them | 10 | 10.0000 | 1 |
| Text, p. 10 | Original comparisons the text says rejected homogeneity | 1 | 1.0000 | 1 |
| Text, p. 10 | MTurk comparisons the text says rejected homogeneity | 8 | 8.0000 | 1 |
| Text, p. 10 | TESS/GfK comparisons the text says rejected homogeneity | 0 | 1.0000 | 0 |
| Table A1 | Table A1 original entries reproduced of 40 published | 40 | 40.0000 | 1 |
| Table A1 | Table A1 mt entries reproduced of 40 published | 40 | 40.0000 | 1 |
| Table A1 | Table A1 gfk entries reproduced of 10 published | 10 | 10.0000 | 1 |
| Online Appendix Table 1 | Treatment estimate and standard error cells reproduced of 4 published | 4 | 4.0000 | 1 |
| Online Appendix Table 1 | Intercept, sample size and R-squared cells of appendix Table 1 (Gun Control) | 8 | NA | NA |
| Online Appendix Table 2 | Treatment estimate and standard error cells reproduced of 8 published | 8 | 8.0000 | 1 |
| Online Appendix Table 2 | Intercept, sample size and R-squared cells of appendix Table 2 (Immigration) | 16 | NA | NA |
| Online Appendix Table 3 | Treatment estimate and standard error cells reproduced of 4 published | 4 | 4.0000 | 1 |
| Online Appendix Table 3 | Intercept, sample size and R-squared cells of appendix Table 3 (Death Penalty) | 8 | NA | NA |
| Online Appendix Table 4 | Treatment estimate and standard error cells reproduced of 8 published | 8 | 8.0000 | 1 |
| Online Appendix Table 4 | Intercept, sample size and R-squared cells of appendix Table 4 (Superordinate Identity) | 8 | NA | NA |
| Online Appendix Table 5 | Treatment estimate and standard error cells reproduced of 36 published | 36 | 36.0000 | 1 |
| Online Appendix Table 5 | Intercept, sample size and R-squared cells of appendix Table 5 (Patriot Act) | 8 | NA | NA |
| Online Appendix Table 6 | Treatment estimate and standard error cells reproduced of 8 published | 8 | 8.0000 | 1 |
| Online Appendix Table 6 | Intercept, sample size and R-squared cells of appendix Table 6 (Elite Endorsements) | 24 | NA | NA |
| Online Appendix Table 7 | Treatment estimate and standard error cells reproduced of 24 published | 24 | 24.0000 | 1 |
| Online Appendix Table 7 | Intercept, sample size and R-squared cells of appendix Table 7 (Mental Illness) | 16 | NA | NA |
| Online Appendix Table 8 | Treatment estimate and standard error cells reproduced of 8 published | 8 | 8.0000 | 1 |
| Online Appendix Table 8 | Intercept, sample size and R-squared cells of appendix Table 8 (System Threat) | 16 | NA | NA |
| Online Appendix Table 9 | Treatment estimate and standard error cells reproduced of 12 published | 12 | 12.0000 | 1 |
| Online Appendix Table 9 | Intercept, sample size and R-squared cells of appendix Table 9 (Expert Economists: Immigration, Health Care and China) | 24 | NA | NA |
| Online Appendix Table 10 | Treatment estimate and standard error cells reproduced of 8 published | 8 | 8.0000 | 1 |
| Online Appendix Table 10 | Intercept, sample size and R-squared cells of appendix Table 10 (Expert Economists: Tax Cuts and Gold Standard) | 16 | NA | NA |
| Online Appendix Table 11 | Treatment estimate and standard error cells reproduced of 24 published | 24 | 24.0000 | 1 |
| Online Appendix Table 11 | Intercept, sample size and R-squared cells of appendix Table 11 (Free Trade) | 12 | NA | NA |
| Online Appendix Table 12 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 12 | Intercept, sample size and R-squared cells of appendix Table 12 (Extremity) | 12 | NA | NA |
| Online Appendix Table 13 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 13 | Intercept, sample size and R-squared cells of appendix Table 13 (Perceived Polarization) | 12 | NA | NA |
| Online Appendix Table 14 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 14 | Intercept, sample size and R-squared cells of appendix Table 14 (Crime Spending) | 12 | NA | NA |
| Online Appendix Table 15 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 15 | Intercept, sample size and R-squared cells of appendix Table 15 (Health Care Spending) | 12 | NA | NA |
| Online Appendix Table 16 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 16 | Intercept, sample size and R-squared cells of appendix Table 16 (Stimulus Spending) | 12 | NA | NA |
| Online Appendix Table 17 | Treatment estimate and standard error cells reproduced of 6 published | 6 | 6.0000 | 1 |
| Online Appendix Table 17 | Intercept, sample size and R-squared cells of appendix Table 17 (Terrorism Spending) | 12 | NA | NA |
| Text, p. 6 | Most dependent variables in any of the deposit’s study groupings | 2 | 5.0000 | 0 |
| Footnote 5 | Mean absolute standardized effect | 0.2 | 0.2002 | 1 |
| Text, p. 8 | Pairs significant in both versions with opposite signs | 0 | 0.0000 | 1 |
| Text, pp. 10-11 | Comparisons rejecting homogeneity in more than one sample | 1 | 1.0000 | 1 |
| Figure 4 | Subjects per treatment arm the MTurk replications typically employ | 500 | NA | NA |

Maintained rewrite verification: published value against rewrite output.

**94** of the **100** comparable claims match the published values. The
6 that do not are discussed above: Simulated power at 0.2 SD and 500
subjects per arm; Simulated power at 0.1 SD and 500 subjects per arm;
Table 2, MTurk, significant before correction; Table 2, TESS/GfK,
significant before correction; TESS/GfK comparisons the text says
rejected homogeneity; Most dependent variables in any of the deposit’s
study groupings.

The rows with no `match_rewrite` are those the rewrite does not compute,
and they are recorded rather than dropped: Table 1’s sample sizes, the
intercept, sample size and R-squared rows of the seventeen online
appendix tables, and the article’s claim about the typical number of
subjects per treatment arm.

------------------------------------------------------------------------

# R environment

| Item       | Value                  |
|:-----------|:-----------------------|
| R version  | 4.6.0                  |
| Platform   | aarch64-apple-darwin23 |
| Date run   | 2026-08-03             |
| tidyverse  | 2.0.0                  |
| sandwich   | 3.1.1                  |
| lmtest     | 0.9.40                 |
| estimatr   | 1.0.6                  |
| metap      | 1.14                   |
| knitr      | 1.51                   |
| kableExtra | 1.4.0                  |
| here       | 1.0.2                  |

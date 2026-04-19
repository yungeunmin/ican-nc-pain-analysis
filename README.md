# ICAN-NC Cancer Pain Study Analysis

SAS analysis pipeline for the ICAN-NC longitudinal cancer pain study, evaluating the effect of mobile health Pain Coping Skills Training (mPCST) on pain outcomes in breast cancer patients.

## Overview

This project provides a reproducible SAS-based workflow to:

- Import and clean the raw ICAN-NC study dataset
- Recode missing values and apply variable labels and formats
- Derive binary and three-level pain category variables
- Summarize baseline characteristics (Table 1)
- Describe pain trajectories over four time points
- Fit linear regression models for the primary endpoint (pain at time 3)
- Conduct sensitivity analyses using complete-case and multiple imputation approaches
- Cross-classify pain categories from baseline to time 3

## Structure

```
ican-nc-pain-analysis/
│
├── code/
│   └── ican_nc_analysis.sas   # Full analysis pipeline
│
├── report/
│   └── ican_nc_analysis_report.pdf  # Written report with results and interpretation
│
├── .gitignore
└── README.md
```

> **Note:** Raw data are not included in this repository. To run the code, update the file path in Section 1.1 of the SAS script to point to your local copy of `ican_rawdata.csv`.

## Data

The analysis uses deidentified data from the ICAN-NC study (N = 200), a randomized trial comparing mPCST to a control condition in breast cancer patients with pain. Pain was assessed at four time points on a 0–10 scale.

## Statistical Methods

- Linear regression (PROC GLM)
- Multiple imputation (PROC MI, FCS method) with pooled inference (PROC MIANALYZE)
- Frequency cross-classification (PROC FREQ)
- ODS HTML output for formatted tables and figures

## Reproducibility

All analyses are script-based. Output is generated entirely from `ican_nc_analysis.sas` with no manual steps required beyond supplying the raw data file and updating the input path.

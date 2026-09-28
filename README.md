# The Fenway Interaction: Evaluating Home-Field Advantage by Batter Handedness (R / Sabermetrics)

![R](https://img.shields.io/badge/Language-R-blue.svg)
![Field](https://img.shields.io/badge/Domain-Sports%20Analytics%20%26%20Sabermetrics-red.svg)
![Methods](https://img.shields.io/badge/Methods-GLM%20%7C%20Weighted%20Linear%20Regression%20%7C%20Poisson-orange.svg)

## 📌 Project Overview
This repository contains an advanced statistical investigation analyzing the impact of **Fenway Park's unique dimensions** (e.g., the Green Monster) on hitter performance—specifically comparing **Red Sox hitters** to the broader **AL East** across batter handedness (Left, Right, and Switch hitters). 

Using raw traditional and advanced Sabermetric datasets, this project cleans, engineers, and models offensive metrics like **wOBA (Weighted On-Base Average)** and **HR (Home Runs)** using **Weighted Linear Regression** and **Poisson Generalized Linear Models (GLMs)** with log offsets for plate appearances.

---

## 🛠️ Key Analytical Features & Methods

### 1. Data Engineering & Handedness Classification
- **Data Ingestion & Cleaning**: Aggregated multi-season player performance datasets from AL East and Red Sox rosters (`dplyr`, `readr`).
- **Handedness Logic**: Automated classification of players into `Left`, `Right`, and `Switch` hitters by joining directional split data with overall plate appearances (PAs).
- **Advanced Metric Integration**: Calculated weighted averages across seasons for advanced metrics (wOBA, SLG, OPS) based on total Plate Appearances.

### 2. Statistical Modeling & Sabermetric Insights
- **Interaction Model (wOBA Analysis)**: Evaluated interaction effects between team type (`RedSox` vs. `AL East`) and batter handedness using PA-weighted linear regression (`lm`).
- **Poisson GLM (Home Run Rate Modeling)**: Modeled count data (Home Runs) using a Poisson family GLM with an `offset(log(PA))` to isolate HR rate production per plate appearance.
- **Predictive Projections**: Generated 95% Confidence Intervals for expected Home Run output standardized to a full-season workload (**600 PAs**).

---

## 📁 Repository Structure

```text
├── data/
│   ├── RedSox_Hitters_L.csv           # Red Sox Left-Handed traditional stats
│   ├── RedSox_Hitters_L_Updated.csv   # Red Sox Left-Handed advanced stats (wOBA, SLG, OPS)
│   ├── AL_East_Hitters_L.csv          # AL East Left-Handed traditional stats
│   ├── AL_East_Hitters_L_Updated.csv  # AL East Left-Handed advanced stats
│   ├── AL_East_Hitters_R.csv          # AL East Right-Handed traditional stats
│   ├── AL_East_Hitters_R_Updated.csv  # AL East Right-Handed advanced stats
│   ├── AL_East_Hitters_RandL.csv      # AL East Combined splits
│   └── AL_East_Hitters_RandL_Updated.csv # AL East Combined advanced splits
├── scripts/
│   └── ProjectWork.R                  # Full ETL pipeline, GLMs, predictions, & ggplot2 scripts
├── Math2200Project.Rproj              # RStudio project configuration file
└── README.md                          # Project documentation

# CHS_acquisition_churn_90d

## Purpose

This is a predictive modeling project within Customer Happiness Score project scope. The target of this model is to predict whether customers will stop using Ez text messaging (churn) in 90 days since they initially use it. 

## use case

The prediction scores can be used to identify the high churn risk clients, so as to feed the marketing operations for retention or customer contact activities. Scores will be produced by the scoring script that's contained in the repo. 

## Model build

A __model_documentation v1_3__ has been created in the repo with technical details. A metadata object __CHS_90d.Rds__ is created in the working directory that includes the model object, calibration object and the necessary data processing details. These are all needed for scoring process. 

## Scoring process

The scoring process starts after __bidw.customer_segmentation__ table gets refreshed. Firstly, the max(first_usage_units) is identified (e.g. 2019-01-06), then it back tracks the 4 weeks period that's 7 days before the max(first_usage_units) to be the scoring population (e.g. 2018-12-02 to 2018-12-30), to ensure (1) it only includes new acquisition clients (based on initial usage date) and (2) each client has at least 7 days' observation period.

## Scoring how do

The scoring process comprises of two R scripts that are to be executed in one go. 

1. Execute _Scoring data build.R_. This will create _scor_ data frame as the scoring cohort. 
2. Execute _Scoring process.R_. This will create the scores based on the built model and upload the scores to __bidw.chs_acquisition_churn_90d__.

## Scoring test

After scoring process, check __bidw.chs_acquisition_churn_90d__ table in MySQL instance to ensure you have got valid entries with the effective date (efft_d) as today. 
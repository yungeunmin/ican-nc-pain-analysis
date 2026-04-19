**************************************************************************
Project: ICAN-NC Cancer Pain Study Analysis
File:    ican_nc_analysis.sas   
Author:  Mattis Min
Date:    04/18/2026
Purpose: Import, clean, analyze, and report results for the ICAN-NC
         cancer pain study.
**************************************************************************;

**************************************************************************
SECTION 1.1 Import the raw ICAN-NC CSV file
**************************************************************************;
proc import
    datafile="/path/to/your/data/ican_rawdata.csv"
    out=work.ican_raw
    dbms=csv
    replace;
    guessingrows=max;
run;

* Display dataset structure: variable names, types, lengths, formats *;
proc contents data=work.ican_raw varnum;
run;

* Print first 10 observations to visually inspect imported values *;
proc print data=work.ican_raw(obs=10);
run;

**************************************************************************
SECTION 1.2 Create cleaned dataset and recode -99 values to missing
Purpose:
    - Create a cleaned working dataset from the imported raw data
    - Rename site2 to site to match the SAP
    - Convert all numeric values of -99 to SAS missing (.)
    - Inspect dataset
**************************************************************************;
data work.ican_clean;
    set work.ican_raw(rename=(site2=site));

    * If any numeric value equals -99, recode it to SAS missing *;
    array num_vars _numeric_;
    do over num_vars;
        if num_vars = -99 then num_vars = .;
    end;
run;

* Confirm that site2 was renamed to site *;
proc contents data=work.ican_clean varnum;
run;

* Confirm that numeric -99 values were converted to missing *;
proc print data=work.ican_clean(obs=10);
run;

**************************************************************************
SECTION 1.3 Define formats and apply labels/formats
Note: We are using: 2 = Black or African American as described in SAP
**************************************************************************;

* Create user-defined formats for coded variables *;
proc format;
    value rand_fmt
        1 = "mPCST"
        2 = "control";

    value site_fmt
        1  = "Gibson Cancer Center"
        2  = "Johnston Health"
        3  = "Lexington Medical Center Cancer Services"
        4  = "Scotland Cancer Treatment Center"
        5  = "Spartanburg Regional"
        6  = "Maria Parham Medical Center"
        7  = "Wilson Medical Center"
        8  = "Augusta Health"
        9  = "Cape Fear Medical Center"
        10 = "Conway Medical Center";

    value income_fmt
        1 = "Less than $10,000"
        2 = "$10,000 - $24,999"
        3 = "$25,000 - $49,999"
        4 = "$50,000 - $74,999"
        5 = "$75,000 - $99,999"
        6 = "$100,000 or more";

    value race_fmt
        1 = "Caucasian / White"
        2 = "Black or African American"
        3 = "American Indian or Alaskan Native"
        4 = "Asian"
        5 = "Native Hawaiian or other Pacific Islander"
        6 = "2 or more races"
        7 = "Other";

    value eth_fmt
        1 = "Not Hispanic or Latino"
        2 = "Hispanic or Latino";

    value stage_fmt
        1 = "Stage 1"
        2 = "Stage 2"
        3 = "Stage 3"
        4 = "Stage 4";
run;

* Apply variable labels and formats to the cleaned dataset *;
data work.ican_clean;
    set work.ican_clean;

    label
        Randomization = "Study group"
        site          = "Study site"
        Age           = "Age"
        race          = "Race"
        ethnicity     = "Ethnicity"
        income        = "Income"
        cancerstgEMR  = "Cancer stage from EMR"
        BMI           = "Body mass index"
        pain_1        = "Pain score at time 1"
        pain_2        = "Pain score at time 2"
        pain_3        = "Pain score at time 3"
        pain_4        = "Pain score at time 4"
        id            = "Participant ID"
    ;

    format
        Randomization rand_fmt.
        site          site_fmt.
        race          race_fmt.
        ethnicity     eth_fmt.
        income        income_fmt.
        cancerstgEMR  stage_fmt.
    ;
run;

* Inspect labels and formats after assignment *;
proc contents data=work.ican_clean varnum;
run;

proc print data=work.ican_clean(obs=10);
run;

**************************************************************************
SECTION 1.4 Create categorical versions of the pain variables
Purpose:
    - Create binary pain variables:
          0-6 = low
          7-10 = high
    - Create 3-level pain variables:
          0-3 = low
          4-6 = moderate
          7-10 = high
    - Preserve missing values as missing
Notes:
    - New binary variables will be named:
          pain_1_bin, pain_2_bin, pain_3_bin, pain_4_bin
    - New 3-level variables will be named:
          pain_1_cat3, pain_2_cat3, pain_3_cat3, pain_4_cat3
**************************************************************************;

* Define formats for derived pain category variables *;
proc format;
    value painbin_fmt
        0 = "Low (0-6)"
        1 = "High (7-10)";

    value pain3_fmt
        1 = "Low (0-3)"
        2 = "Moderate (4-6)"
        3 = "High (7-10)";
run;

* Create derived categorical pain variables *;
data work.ican_clean;
    set work.ican_clean;

    array pain_raw[4]  pain_1 pain_2 pain_3 pain_4;
    array pain_bin[4]  pain_1_bin pain_2_bin pain_3_bin pain_4_bin;
    array pain_cat3[4] pain_1_cat3 pain_2_cat3 pain_3_cat3 pain_4_cat3;

    do i = 1 to 4;

        * Binary version: 0-6 = low, 7-10 = high *;
        if missing(pain_raw[i])          then pain_bin[i] = .;
        else if 0 <= pain_raw[i] <= 6   then pain_bin[i] = 0;
        else if 7 <= pain_raw[i] <= 10  then pain_bin[i] = 1;
        else                                  pain_bin[i] = .;

        * Three-level version: 0-3 = low, 4-6 = moderate, 7-10 = high *;
        if missing(pain_raw[i])          then pain_cat3[i] = .;
        else if 0 <= pain_raw[i] <= 3   then pain_cat3[i] = 1;
        else if 4 <= pain_raw[i] <= 6   then pain_cat3[i] = 2;
        else if 7 <= pain_raw[i] <= 10  then pain_cat3[i] = 3;
        else                                  pain_cat3[i] = .;

    end;

    label
        pain_1_bin  = "Pain score at time 1 (binary)"
        pain_2_bin  = "Pain score at time 2 (binary)"
        pain_3_bin  = "Pain score at time 3 (binary)"
        pain_4_bin  = "Pain score at time 4 (binary)"
        pain_1_cat3 = "Pain score at time 1 (3-level)"
        pain_2_cat3 = "Pain score at time 2 (3-level)"
        pain_3_cat3 = "Pain score at time 3 (3-level)"
        pain_4_cat3 = "Pain score at time 4 (3-level)"
    ;

    format
        pain_1_bin  painbin_fmt.
        pain_2_bin  painbin_fmt.
        pain_3_bin  painbin_fmt.
        pain_4_bin  painbin_fmt.
        pain_1_cat3 pain3_fmt.
        pain_2_cat3 pain3_fmt.
        pain_3_cat3 pain3_fmt.
        pain_4_cat3 pain3_fmt.
    ;

    drop i;
run;

* Inspect the new derived variables *;
proc contents data=work.ican_clean varnum;
run;

proc print data=work.ican_clean(obs=10);
    var id pain_1 pain_1_bin pain_1_cat3
           pain_2 pain_2_bin pain_2_cat3
           pain_3 pain_3_bin pain_3_cat3
           pain_4 pain_4_bin pain_4_cat3;
run;

**************************************************************************
SECTION 1.5 Check for missing and out-of-range values
Purpose:
    - Summarize missing values in the cleaned dataset
    - Identify values outside the allowed or expected ranges
Notes:
    - BMI outside 10-60 is described as unusual in the instructions,
      so we will flag it separately rather than automatically treating
      it as impossible
**************************************************************************;

* Frequency tables for categorical variables, including missing values *;
proc freq data=work.ican_clean;
    tables Randomization
           site
           race
           ethnicity
           income
           cancerstgEMR
           pain_1
           pain_2
           pain_3
           pain_4
           pain_1_bin
           pain_2_bin
           pain_3_bin
           pain_4_bin
           pain_1_cat3
           pain_2_cat3
           pain_3_cat3
           pain_4_cat3 / missing;
run;

* Summary statistics and missing counts for continuous variables *;
proc means data=work.ican_clean n nmiss min max mean std;
    var Age BMI id;
run;

* Flag unusual BMI values based on SAP *;
data work.ican_clean;
    set work.ican_clean;

    if not missing(BMI) and (BMI < 10 or BMI > 60) then bmi_unusual = 1;
    else bmi_unusual = 0;

    label bmi_unusual = "Indicator for BMI outside 10 to 60";
run;

* Count how many observations have unusual BMI *;
proc freq data=work.ican_clean;
    tables bmi_unusual / missing;
run;

* Print observations with unusual BMI values *;
proc print data=work.ican_clean;
    where bmi_unusual = 1;
    var id BMI Age Randomization site race ethnicity income cancerstgEMR
        pain_1 pain_2 pain_3 pain_4;
run;

**************************************************************************
SECTION 2.1 Create analysis dataset for Table 1
Purpose:
    - Create a baseline dataset for the randomization table
Notes:
    - Columns:
          1) intervention patients
          2) control patients
          3) everyone
    - Categorical variables will be summarized as n (%)
    - Continuous variables will be summarized as mean (SD)
    - Study group defines the columns and is not included as a row
**************************************************************************;
data work.table1_data;
    set work.ican_clean;

    keep Randomization
         site
         Age
         race
         ethnicity
         income
         cancerstgEMR
         BMI
         pain_1
         pain_2
         pain_3
         pain_4;
run;

* Inspect the Table 1 analysis dataset *;
proc contents data=work.table1_data varnum;
run;

proc print data=work.table1_data(obs=10);
run;

**************************************************************************
SECTION 2.2 Create continuous-variable summaries for Table 1
Purpose:
    - Summarize continuous variables by study group and overall
    - Display each continuous variable as mean (SD)
    - Store results in datasets that can later be combined into Table 1
**************************************************************************;

* Sort data for BY-group summaries *;
proc sort data=work.table1_data out=work.table1_sorted;
    by Randomization;
run;

ods select none;

* Continuous summaries by study group *;
ods output Summary=work.cont_bygroup_raw;
proc means data=work.table1_sorted n mean std;
    by Randomization;
    var Age BMI pain_1 pain_2 pain_3 pain_4;
run;

* Continuous summaries overall *;
ods output Summary=work.cont_overall_raw;
proc means data=work.table1_data n mean std;
    var Age BMI pain_1 pain_2 pain_3 pain_4;
run;

ods select all;

* Reshape study-group summaries into long format *;
data work.cont_bygroup;
    set work.cont_bygroup_raw;

    length Variable $30 Group $20 Summary $40;

    if Randomization = 1 then Group = "Intervention";
    else if Randomization = 2 then Group = "Control";

    Variable = "Age";
    N = Age_N; Mean = Age_Mean; Std = Age_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "BMI";
    N = BMI_N; Mean = BMI_Mean; Std = BMI_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 1";
    N = pain_1_N; Mean = pain_1_Mean; Std = pain_1_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 2";
    N = pain_2_N; Mean = pain_2_Mean; Std = pain_2_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 3";
    N = pain_3_N; Mean = pain_3_Mean; Std = pain_3_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 4";
    N = pain_4_N; Mean = pain_4_Mean; Std = pain_4_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    keep Variable Group N Mean Std Summary;
run;

* Reshape overall summaries into long format *;
data work.cont_overall;
    set work.cont_overall_raw;

    length Variable $30 Group $20 Summary $40;

    Group = "Overall";

    Variable = "Age";
    N = Age_N; Mean = Age_Mean; Std = Age_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "BMI";
    N = BMI_N; Mean = BMI_Mean; Std = BMI_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 1";
    N = pain_1_N; Mean = pain_1_Mean; Std = pain_1_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 2";
    N = pain_2_N; Mean = pain_2_Mean; Std = pain_2_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 3";
    N = pain_3_N; Mean = pain_3_Mean; Std = pain_3_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    Variable = "Pain score at time 4";
    N = pain_4_N; Mean = pain_4_Mean; Std = pain_4_StdDev;
    Summary = cats(put(Mean, 6.2), " (", put(Std, 6.2), ")");
    output;

    keep Variable Group N Mean Std Summary;
run;

* Combine continuous summaries *;
data work.cont_table1;
    set work.cont_bygroup work.cont_overall;
run;

* Inspect continuous summary dataset *;
proc print data=work.cont_table1 noobs;
run;

**************************************************************************
SECTION 2.3 Create categorical-variable summaries for Table 1
Purpose:
    - Summarize categorical variables by study group and overall
    - Display each level as n (%)
    - Store results in long format for a manuscript-style table
Note: work.table1_sorted already exists from Section 2.2 sort
**************************************************************************;

ods select none;

* Frequencies by study group *;
ods output OneWayFreqs=work.cat_bygroup_raw;
proc freq data=work.table1_sorted;
    by Randomization;
    tables site race ethnicity income cancerstgEMR / missing;
run;

* Frequencies overall *;
ods output OneWayFreqs=work.cat_overall_raw;
proc freq data=work.table1_data;
    tables site race ethnicity income cancerstgEMR / missing;
run;

ods select all;

* Reshape by-group categorical output *;
data work.cat_bygroup;
    set work.cat_bygroup_raw;

    length Variable $30 Level $60 Group $20 Summary $30 RowLabel $70;

    if Randomization = 1 then Group = "Intervention";
    else if Randomization = 2 then Group = "Control";

    if Table = "Table site" then do;
        Variable = "Study site";
        Level = F_site;
    end;
    else if Table = "Table race" then do;
        Variable = "Race";
        Level = F_race;
    end;
    else if Table = "Table ethnicity" then do;
        Variable = "Ethnicity";
        Level = F_ethnicity;
    end;
    else if Table = "Table income" then do;
        Variable = "Income";
        Level = F_income;
    end;
    else if Table = "Table cancerstgEMR" then do;
        Variable = "Cancer stage from EMR";
        Level = F_cancerstgEMR;
    end;

    * Catch true character missing, period strings, and blank strings *;
    if missing(Level) or strip(Level) in (".", "") then Level = "Missing";

    RowLabel = Level;
    Summary  = cats(Frequency, " (", put(Percent, 5.1), "%)");

    keep Variable RowLabel Group Frequency Percent Summary;
run;

* Reshape overall categorical output *;
data work.cat_overall;
    set work.cat_overall_raw;

    length Variable $30 Level $60 Group $20 Summary $30 RowLabel $70;

    Group = "Overall";

    if Table = "Table site" then do;
        Variable = "Study site";
        Level = F_site;
    end;
    else if Table = "Table race" then do;
        Variable = "Race";
        Level = F_race;
    end;
    else if Table = "Table ethnicity" then do;
        Variable = "Ethnicity";
        Level = F_ethnicity;
    end;
    else if Table = "Table income" then do;
        Variable = "Income";
        Level = F_income;
    end;
    else if Table = "Table cancerstgEMR" then do;
        Variable = "Cancer stage from EMR";
        Level = F_cancerstgEMR;
    end;

    if missing(Level) or strip(Level) in (".", "") then Level = "Missing";

    RowLabel = Level;
    Summary  = cats(Frequency, " (", put(Percent, 5.1), "%)");

    keep Variable RowLabel Group Frequency Percent Summary;
run;

* Combine categorical summaries *;
data work.cat_table1;
    set work.cat_bygroup work.cat_overall;
run;

proc print data=work.cat_table1 noobs;
run;

**************************************************************************
SECTION 2.4 Assemble final Table 1
Purpose:
    - Combine continuous and categorical summaries
    - Create one manuscript-style table with columns for:
         Intervention, Control, and Overall
**************************************************************************;

* Make continuous rows ready for final table *;
data work.cont_final;
    set work.cont_table1;

    length Characteristic $80;
    Characteristic = Variable;

    if Variable = "Age"                  then RowOrder = 1;
    else if Variable = "BMI"             then RowOrder = 2;
    else if Variable = "Pain score at time 1" then RowOrder = 3;
    else if Variable = "Pain score at time 2" then RowOrder = 4;
    else if Variable = "Pain score at time 3" then RowOrder = 5;
    else if Variable = "Pain score at time 4" then RowOrder = 6;

    keep RowOrder Characteristic Group Summary;
run;

* Make categorical rows ready for final table *;
data work.cat_final;
    set work.cat_table1;

    length Characteristic $80;

    if Variable = "Study site" then do;
        if RowLabel = "Gibson Cancer Center" then RowOrder = 8;
        else if RowLabel = "Johnston Health" then RowOrder = 9;
        else if RowLabel = "Scotland Cancer Treatment Center" then RowOrder = 10;
        else if RowLabel = "Maria Parham Medical Center" then RowOrder = 11;
        else if RowLabel = "Wilson Medical Center" then RowOrder = 12;
        else if RowLabel = "Augusta Health" then RowOrder = 13;
        else if RowLabel = "Cape Fear Medical Center" then RowOrder = 14;
        else if RowLabel = "Conway Medical Center" then RowOrder = 15;
    end;

    else if Variable = "Race" then do;
        if RowLabel = "Caucasian / White" then RowOrder = 17;
        else if RowLabel = "Black or African American" then RowOrder = 18;
        else if RowLabel = "American Indian or Alaskan Native" then RowOrder = 19;
        else if RowLabel = "Asian" then RowOrder = 20;
        else if RowLabel = "Native Hawaiian or other Pacific Islander" then RowOrder = 21;
        else if RowLabel = "2 or more races" then RowOrder = 22;
        else if RowLabel = "Other" then RowOrder = 23;
        else if RowLabel = "Missing" then RowOrder = 24;
    end;

    else if Variable = "Ethnicity" then do;
        if RowLabel = "Not Hispanic or Latino" then RowOrder = 26;
        else if RowLabel = "Hispanic or Latino" then RowOrder = 27;
        else if RowLabel = "Missing" then RowOrder = 28;
    end;

    else if Variable = "Income" then do;
        if RowLabel = "Less than $10,000" then RowOrder = 30;
        else if RowLabel = "$10,000 - $24,999" then RowOrder = 31;
        else if RowLabel = "$25,000 - $49,999" then RowOrder = 32;
        else if RowLabel = "$50,000 - $74,999" then RowOrder = 33;
        else if RowLabel = "$75,000 - $99,999" then RowOrder = 34;
        else if RowLabel = "$100,000 or more" then RowOrder = 35;
        else if RowLabel = "Missing" then RowOrder = 36;
    end;

    else if Variable = "Cancer stage from EMR" then do;
        if RowLabel = "Stage 1" then RowOrder = 38;
        else if RowLabel = "Stage 2" then RowOrder = 39;
        else if RowLabel = "Stage 3" then RowOrder = 40;
        else if RowLabel = "Stage 4" then RowOrder = 41;
        else if RowLabel = "Missing" then RowOrder = 42;
    end;

    Characteristic = RowLabel;

    keep RowOrder Characteristic Group Summary;
run;

* Add section header rows for categorical variables *;
data work.headers;
    length Characteristic $80 Group $20 Summary $40;

    RowOrder = 7;  Characteristic = "Study site";            Group = "Intervention"; Summary = ""; output;
    RowOrder = 7;  Characteristic = "Study site";            Group = "Control";      Summary = ""; output;
    RowOrder = 7;  Characteristic = "Study site";            Group = "Overall";      Summary = ""; output;

    RowOrder = 16; Characteristic = "Race";                  Group = "Intervention"; Summary = ""; output;
    RowOrder = 16; Characteristic = "Race";                  Group = "Control";      Summary = ""; output;
    RowOrder = 16; Characteristic = "Race";                  Group = "Overall";      Summary = ""; output;

    RowOrder = 25; Characteristic = "Ethnicity";             Group = "Intervention"; Summary = ""; output;
    RowOrder = 25; Characteristic = "Ethnicity";             Group = "Control";      Summary = ""; output;
    RowOrder = 25; Characteristic = "Ethnicity";             Group = "Overall";      Summary = ""; output;

    RowOrder = 29; Characteristic = "Income";                Group = "Intervention"; Summary = ""; output;
    RowOrder = 29; Characteristic = "Income";                Group = "Control";      Summary = ""; output;
    RowOrder = 29; Characteristic = "Income";                Group = "Overall";      Summary = ""; output;

    RowOrder = 37; Characteristic = "Cancer stage from EMR"; Group = "Intervention"; Summary = ""; output;
    RowOrder = 37; Characteristic = "Cancer stage from EMR"; Group = "Control";      Summary = ""; output;
    RowOrder = 37; Characteristic = "Cancer stage from EMR"; Group = "Overall";      Summary = ""; output;

    keep RowOrder Characteristic Group Summary;
run;

* Combine all rows *;
data work.table1_long;
    set work.cont_final work.headers work.cat_final;
run;

proc sort data=work.table1_long;
    by RowOrder Characteristic;
run;

* Transpose from long to wide so each group becomes a column *;
proc transpose data=work.table1_long out=work.table1_final(drop=_name_);
    by RowOrder Characteristic;
    id Group;
    var Summary;
run;

* Replace blank cells with 0 (0%) for non-header rows *;
data work.table1_final;
    set work.table1_final;

    if Characteristic not in ("Study site",
                              "Race",
                              "Ethnicity",
                              "Income",
                              "Cancer stage from EMR") then do;
        if missing(Intervention) then Intervention = "0 (0%)";
        if missing(Control)      then Control      = "0 (0%)";
        if missing(Overall)      then Overall      = "0 (0%)";
    end;
run;

proc print data=work.table1_final noobs label;
    var Characteristic Intervention Control Overall;
    label Characteristic = "Characteristic"
          Intervention   = "Intervention"
          Control        = "Control"
          Overall        = "Overall";
run;

* Output final Table 1 *;
ods html path="/path/to/your/output/folder"
         file="table1_randomization.html"
         style=htmlblue;

title "Table 1. Baseline characteristics by study group";

proc print data=work.table1_final noobs label;
    var Characteristic Intervention Control Overall;
    label Characteristic = "Characteristic"
          Intervention   = "Intervention"
          Control        = "Control"
          Overall        = "Overall";
run;

title;
ods html close;

**************************************************************************
SECTION 3.1 Create long dataset for pain scores over time
Purpose:
    - Reshape pain_1 to pain_4 from wide format to long format
    - Create one pain score variable and one time variable
    - Keep study group for grouped summaries and plotting
**************************************************************************;
data work.pain_long;
    set work.ican_clean;

    array pain_vars[4] pain_1 pain_2 pain_3 pain_4;

    do TimeNum = 1 to 4;
        Pain = pain_vars[TimeNum];

        if TimeNum = 1      then Time = "t1";
        else if TimeNum = 2 then Time = "t2";
        else if TimeNum = 3 then Time = "t3";
        else if TimeNum = 4 then Time = "t4";

        output;
    end;

    keep Randomization TimeNum Time Pain;
run;

proc print data=work.pain_long(obs=20);
run;

**************************************************************************
SECTION 3.2 Create descriptive table of pain over time by study group
Purpose:
    - Create a compact table of mean pain over time by study group
    - Display one row per time point
    - Display intervention, control, and overall columns
**************************************************************************;

* Summarize pain over time by study group *;
proc sort data=work.pain_long out=work.pain_long_sorted;
    by Randomization TimeNum Time;
run;

proc means data=work.pain_long_sorted noprint n mean std;
    by Randomization TimeNum Time;
    var Pain;
    output out=work.pain_bygroup_stats
        n=Pain_N
        mean=Pain_Mean
        std=Pain_SD;
run;

* Keep only actual BY-group summary rows *;
data work.pain_bygroup;
    set work.pain_bygroup_stats;

    length StudyGroup $20 Summary $40;

    if Randomization = 1      then StudyGroup = "Intervention";
    else if Randomization = 2 then StudyGroup = "Control";
    else delete;

    Summary = cats(put(Pain_Mean, 6.2), " (", put(Pain_SD, 6.2), ")");

    keep StudyGroup TimeNum Time Pain_N Pain_Mean Pain_SD Summary;
run;

* Summarize pain over time overall *;
proc sort data=work.pain_long out=work.pain_long_overall_sorted;
    by TimeNum Time;
run;

proc means data=work.pain_long_overall_sorted noprint n mean std;
    by TimeNum Time;
    var Pain;
    output out=work.pain_overall_stats
        n=Pain_N
        mean=Pain_Mean
        std=Pain_SD;
run;

* Keep only actual overall summary rows *;
data work.pain_overall;
    set work.pain_overall_stats;

    length StudyGroup $20 Summary $40;

    StudyGroup = "Overall";
    Summary = cats(put(Pain_Mean, 6.2), " (", put(Pain_SD, 6.2), ")");

    keep StudyGroup TimeNum Time Pain_N Pain_Mean Pain_SD Summary;
run;

* Combine group-specific and overall summaries *;
data work.pain_table_long;
    set work.pain_bygroup work.pain_overall;

    length Characteristic $20;
    Characteristic = Time;
run;

proc sort data=work.pain_table_long;
    by TimeNum Characteristic;
run;

* Transpose to create a single descriptive table *;
proc transpose data=work.pain_table_long
    out=work.pain_table_final(drop=_NAME_);
    by TimeNum Characteristic;
    id StudyGroup;
    var Summary;
run;

proc print data=work.pain_table_final noobs label;
    var Characteristic Intervention Control Overall;
    label Characteristic = "Time point"
          Intervention   = "Intervention"
          Control        = "Control"
          Overall        = "Overall";
run;

**************************************************************************
SECTION 3.3 Output descriptive table using ODS
**************************************************************************;
ods html path="/path/to/your/output/folder"
         file="pain_over_time_table.html"
         style=htmlblue;

title "Table 2. Mean pain score over time by study group";

proc print data=work.pain_table_final noobs label;
    var Characteristic Intervention Control Overall;
    label Characteristic = "Time point"
          Intervention   = "Intervention"
          Control        = "Control"
          Overall        = "Overall";
run;

title;
ods html close;

**************************************************************************
SECTION 3.4 Plot mean pain over time by study group
**************************************************************************;
ods graphics on;

title "Figure 1. Mean pain score over time by study group";

proc sgplot data=work.pain_bygroup;
    series x=TimeNum y=Pain_Mean / group=StudyGroup markers;
    xaxis values=(1 2 3 4)
          valuesdisplay=("t1" "t2" "t3" "t4")
          label="Time point";
    yaxis label="Mean pain score";
run;

title;
ods graphics off;

**************************************************************************
SECTION 4.1 Fit baseline model: pain_1 by study group
Purpose:
    - Outcome: pain_1
    - Predictor: Randomization
**************************************************************************;
proc glm data=work.ican_clean;
    class Randomization;
    model pain_1 = Randomization;
run;
quit;

**************************************************************************
SECTION 4.2 Fit unadjusted model for pain at time 3 by study group
Purpose:
    - Outcome: pain_3
    - Predictor: Randomization
**************************************************************************;
proc glm data=work.ican_clean;
    class Randomization;
    model pain_3 = Randomization;
run;
quit;

**************************************************************************
SECTION 4.3 Fit model with pain_1, pain_2, and pain_3 as outcomes
Purpose:
    - Fit the model described in SAP using
      pain_1 through pain_3 as outcomes and study group as predictor
**************************************************************************;
proc glm data=work.ican_clean;
    class Randomization;
    model pain_1 pain_2 pain_3 = Randomization;
run;
quit;

**************************************************************************
SECTION 4.4 Fit adjusted model for pain at time 3 controlling for baseline pain
Purpose:
    - Compare pain score at time 3 between study groups
      after adjusting for baseline pain score
    - Outcome: pain_3
    - Predictors: pain_1 and Randomization
**************************************************************************;
proc glm data=work.ican_clean;
    class Randomization;
    model pain_3 = pain_1 Randomization;
run;
quit;

**************************************************************************
SECTION 4.5 Fit model for pain at time 3 controlling for baseline pain and site
Purpose:
    - Compare pain score at time 3 between study groups
      after adjusting for baseline pain score and study site
    - Outcome: pain_3
    - Predictors: pain_1, Randomization, and site
Notes:
    - No additional baseline-unbalanced covariates were formally identified
      from Table 1, so none were added beyond site
**************************************************************************;
proc glm data=work.ican_clean;
    class Randomization site;
    model pain_3 = pain_1 Randomization site;
run;
quit;

**************************************************************************
SECTION 4.6 Create long-thin dataset using all 4 time points
Purpose:
    - Reshape pain_1 to pain_4 into long format
    - Create one record per participant per time point
    - Print the first 20 records
**************************************************************************;
data work.long_thin_pain;
    set work.ican_clean;

    array pain_vars[4] pain_1 pain_2 pain_3 pain_4;

    do TimeNum = 1 to 4;
        Pain = pain_vars[TimeNum];

        if TimeNum = 1      then Time = "t1";
        else if TimeNum = 2 then Time = "t2";
        else if TimeNum = 3 then Time = "t3";
        else if TimeNum = 4 then Time = "t4";

        output;
    end;

    keep id Randomization site TimeNum Time Pain;
run;

proc print data=work.long_thin_pain(obs=20);
run;

**************************************************************************
SECTION 5.1 Create complete-case dataset for pain_1 through pain_4
Purpose:
    - Restrict to participants with complete data on pain_1, pain_2,
      pain_3, and pain_4
    - Use this dataset for the complete-case sensitivity analysis
**************************************************************************;
data work.complete_cases;
    set work.ican_clean;

    if not missing(pain_1)
       and not missing(pain_2)
       and not missing(pain_3)
       and not missing(pain_4);
run;

proc print data=work.complete_cases(obs=10);
run;

proc means data=work.complete_cases n;
    var pain_1 pain_2 pain_3 pain_4;
run;

**************************************************************************
SECTION 5.2 Fit complete-case sensitivity model for pain at time 3
Purpose:
    - Repeat the unadjusted pain_3 by study group analysis
      using only participants with complete pain data at all 4 time points
**************************************************************************;
proc glm data=work.complete_cases;
    class Randomization;
    model pain_3 = Randomization;
run;
quit;

**************************************************************************
SECTION 5.3 Multiple imputation sensitivity analysis for pain at time 3
Purpose:
    - Fit pain_3 = Randomization using the full cohort
      after imputing missing pain values
    - Use 10 imputations and seed = 123
**************************************************************************;

* Impute missing pain values using study group and all four pain variables *;
proc mi data=work.ican_clean
        out=work.mi_data
        seed=123
        nimpute=10;
    class Randomization;
    fcs reg;
    var Randomization pain_1 pain_2 pain_3 pain_4;
run;

* Fit pain_3 = Randomization within each imputed dataset *;
ods select none;
ods output ParameterEstimates=work.mi_pe;

proc glm data=work.mi_data;
    by _Imputation_;
    class Randomization;
    model pain_3 = Randomization / solution;
run;
quit;

ods select all;

* Inspect parameter estimates to confirm exact parameter names *;
proc print data=work.mi_pe(obs=30);
run;

* Keep only the study-group effect for MIANALYZE *;
data work.mi_pe_randomization;
    set work.mi_pe;
    where Parameter = "Randomization control";
run;

proc print data=work.mi_pe_randomization;
run;

* Combine estimates across imputations *;
proc mianalyze data=work.mi_pe_randomization;
    modeleffects Estimate;
    stderr StdErr;
run;

**************************************************************************
SECTION 6.1 Cross-classify binary pain categories at t1 versus t3
Purpose:
    - Cross-tabulate the 2-category pain variables at time 1 and time 3
**************************************************************************;
proc freq data=work.ican_clean;
    tables pain_1_bin * pain_3_bin / missing;
run;

**************************************************************************
SECTION 6.2 Cross-classify 3-level pain categories at t1 versus t3
Purpose:
    - Cross-tabulate the 3-category pain variables at time 1 and time 3
**************************************************************************;
proc freq data=work.ican_clean;
    tables pain_1_cat3 * pain_3_cat3 / missing;
run;

**************************************************************************
SECTION 6.3 Output cross-classification tables using ODS
**************************************************************************;
ods html path="/path/to/your/output/folder
         file="pain_category_crosstabs.html"
         style=htmlblue;

title "Table 3. Cross-classification of binary pain categories at t1 and t3";
proc freq data=work.ican_clean;
    tables pain_1_bin * pain_3_bin / missing;
run;

title "Table 4. Cross-classification of 3-level pain categories at t1 and t3";
proc freq data=work.ican_clean;
    tables pain_1_cat3 * pain_3_cat3 / missing;
run;

title;
ods html close;












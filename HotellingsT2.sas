%macro HotellingsT2(data=, variables=, comparison=) / des="Compute Hotelling's T-squared Statistic";

  /****************************************************************************
    BEGIN MACRO HEADER
   ****************************************************************************
      Name:       HotellingsT2
      Author:     Chris Swenson
      Created:    2023-06-20
      Purpose:    Calculate Hotelling's T-squared statistic for one or two 
                  samples
      Arguments:  data=       - input data set
                  variables=  - input variables delimited by spaces
                  comparison= - either:
                    a) list of expected values delimited by spaces
                    b) a variable used to identify two samples

      Revisions
      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
      Date        Author  Comments
      ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
      YYYY-MM-DD  III     Please use this format and insert new entries above
   ****************************************************************************
    END MACRO HEADER
   ****************************************************************************/

    /* The J() function creates a matrix with nrow rows (argument 1) and ncol
       columns (argument 2) with all elements equal to value (argument 3). */
    /* I() function creates identity matrix of the same size as the matrix 
       passed in as argument 1. */

    %local sample_type;
    %if %sysfunc(exist(&COMPARISON)) = 0 %then %do;
        %let sample_type = One;
        /* Replace spaces in COMPARISON with commas */
        %let comparison = %sysfunc(tranwrd(&COMPARISON, %quote( ), %quote(, )));
        %put NOTE: Running the Hotelling One Sample T-Squared;
    %end;
    %else %do;
        %let sample_type = Two;
        %put NOTE: Running the Hotelling Two Sample T-Squared;
    %end;

    %let variables_print = %sysfunc(tranwrd(&VARIABLES, %quote( ), %quote(, )));

    title "Hotelling's &SAMPLE_TYPE Sample T-Squared";

    proc iml;
      start Hotelling_One;

        p = ncol(x1);
        Vars = {&VARIABLES_PRINT};

        n1 = nrow(x1);
        one1 = j(n1, 1, 1);
        ident1 = i(n1);
        Means1 = x1` * one1 / n1;
        S1 = x1` * (ident1 - one1 * one1` / n1) * x1 / (n1 - 1.0);

        Means2 = {&COMPARISON};
        n = n1;
        S = S1;
        
        T2 = n * (Means1 - Means2)` * inv(S) * (Means1 - Means2);

        DF1 = p;
        DF2 = n - p;
        F = (n - p) * T2 / p / (n - 1);
        
        prob = 1.0 - probf(F, DF1, DF2);
        if prob = 0 then do;
            prob = '<.0001';
        end;
        
        print Vars[label='Variables'] Means1[label='Means'] Means2[label='Expected'];
        print S1[label='Variance-Covariance Matrix'];
        print T2[label="Hotelling's T^2"] F[label="F Value"] DF1 DF2 prob[label="Pr > F"];
        
      finish;

      start Hotelling_Two;
      
        p = ncol(x1);
        Vars = {&VARIABLES_PRINT};
      
        n1 = nrow(x1);
        one1 = j(n1, 1, 1);
        ident1 = i(n1);
        Means1 = x1` * one1 / n1;
        S1 = x1` * (ident1 - one1 * one1` / n1) * x1 / (n1 - 1.0);

        n2 = nrow(x2);
        one2 = j(n2, 1, 1);
        ident2 = i(n2);
        Means2 = x2` * one2 / n2;
        S2 = x2` * (ident2 - one2 * one2` / n2) * x2 / (n2 - 1.0);
        
        n = n1 + n2;
        S_pool = ((n1 - 1.0) * s1 + (n2 - 1.0) * s2) / (n - 2.0);
        
        T2 = (Means1 - Means2)` * inv(S_pool * (1/n1 + 1/n2)) * (Means1 - Means2);
        
        DF1 = p;
        DF2 = n - p - 1;
        F = (n - p - 1) * T2 / p / (n - 2);
        
        prob = 1.0 - probf(F, DF1, DF2);
        if prob = 0 then do;
            prob = '<.0001';
        end;
        
        print n1[label='Sample 1 Size'] n2[label='Sample 2 Size'] n[label='Total'];
        print Vars[label='Variables'] Means1[label='Sample 1 Means'] Means2[label='Sample 2 Means'];
        print S1[label='Sample 1 Variance-Covariance Matrix'];
        print S2[label='Sample 2 Variance-Covariance Matrix'];
        print S_pool[label='Pooled Variance-Covariance Matrix'];   
        print T2[label="Hotelling's T^2"] F[label="F Value"] DF1 DF2 prob[label="Pr > F"];

      finish;

    %if &SAMPLE_TYPE = One %then %do;
      use &DATA; read all var{&VARIABLES} into x1;
      run Hotelling_One;
    %end;
    %else %do;      
      use &DATA; read all var{&VARIABLES} into x1;
      use &COMPARISON; read all var{&VARIABLES} into x2;
      run Hotelling_Two;
    %end;

    quit;

%mend HotellingsT2;

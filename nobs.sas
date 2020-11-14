%macro NObs(ds,nowarn,fmt=) / des='Number of obs';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       NObs
        Author:     Chris Swenson
        Created:    2010-07-20

        Purpose:    Output the number of observations in a data set. Modified from
                    a macro found on the SAS website.

        Arguments:  ds     - input data set to count observations
                    nowarn - whether or not to warn the user if the observations
                             cannot be obtained or the data set does not exist
                    fmt=   - format of output number

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-08-16  CAS     Added format argument for output.
        2011-10-19  CAS     Modified output message when NOWARN is specified and the
                            data set does not exist.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check if the table exists */
    /* REVISION 2011-10-19 CAS: Modified output message when NOWARN is specified. */
    %if "&ds"="" %then %do;
        %put %str(E)RROR: The data set argument is blank.;
        %return;
    %end;
    %if %eval(%sysfunc(exist(&ds, %str(DATA))) + %sysfunc(exist(&ds, %str(VIEW))))=0 %then %do;
      %if %upcase(&nowarn) ne NOWARN %then %do;
        %put %str(W)ARNING: %sysfunc(compbl(The &ds data set does not exist)).;
      %end;
      %else %put NOTE: %sysfunc(compbl(The &ds data set does not exist)).;
        %return;
    %end;

    /* Manage scope */
    %local arg dsid vid rc;

    /* Open data set */
    %let dsid=%sysfunc(open(&ds));

        %let anobs=%sysfunc(attrn(&dsid, ANOBS));
        %let nobs=%sysfunc(attrn(&dsid, NOBS));

        %if %superq(FMT) ne %str()
        %then %let nobs=%sysfunc(putn(&NOBS, %superq(FMT)));

    /* Close data set */
    %let rc=%sysfunc(close(&dsid));

    %if %upcase(&nowarn) ne NOWARN %then %do;
        %if &ANOBS=0 %then %put %str(W)ARNING: Unable to access the number of observations in &DS..;
    %end;

    /* Output type */
    &nobs

%mend NObs;

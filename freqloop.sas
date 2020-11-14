%macro FreqLoop(ds,vars,by=,out=,lib=,miss=N,print=N) / des="Output frequencies for variables";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       FreqLoop
        Author:     Chris Swenson
        Created:    2010-07-09

        Purpose:    Output frequencies for variables in a data set

        Arguments:  ds    - input data set
                    vars  - one or more variables to output frequencies for
                    by=   - split by variable
                    out=  - prefix for output data set(s)
                    lib=  - output library, defaulted to WORK or USER
                    miss= - Y/N to indicate whether to use the MISSING option,
                            defaulted to N to preserve backward compatibility
                    print=- Y/N to indicate whether to print to the output.

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-01-26  CAS     Added capacity to output crosstab (e.g., year*quarter*var)
        2011-04-27  CAS     Added view to check of input data set
        2011-10-17  CAS     Added the MISS argument to specify whether to use the
                            MISSING option.
        2012-02-02  CAS     Added LIB argument to set output library.
        2014-09-26  CAS     Added PRINT argument.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %if "&DS"="" %then %do;
        %put %str(E)RROR: No data set specified.;
        %return;
    %end;
    /* REVISION 2011-04-27 CAS: Added view to check */
    %if %eval(%sysfunc(exist(&ds)) + %sysfunc(exist(&ds, VIEW)))=0 %then %do;
        %put %str(E)RROR: The specified data set does not exist.;
        %return;
    %end;
    %if "&vars"="" %then %do;
        %put %str(E)RROR: No variables specified.;
        %return;
    %end;

    /* Check for argument values in (Y N) */
    /* REVISION 2011-10-17 CAS: Added check of MISS argument */
    %let MISS=%upcase(&MISS);
    %if %index(*Y*N*,*&MISS*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for MISS.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;

    /* REVISION 2014-9-26 CAS: Added PRINT argument */
    %let PRINT=%upcase(&PRINT);
    %if %index(*Y*N*,*&PRINT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for PRINT.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;

    /* Default the lib argument based on whether the USER option is in effect. */
    /* REVISION 2012-02-02 CAS: Added default for new LIB argument */
    %if "&LIB"="" %then %do;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
        %put NOTE: Library argument LIB= set to &LIB..;
    %end;

    /* Convert MISS argument */
    %if &MISS=Y %then %let MISS=MISSING;
    %else %let MISS=;

    %if "&OUT" ne "" %then %do;
        %let out=&OUT._;
    %end;

    /* Obtain list of all variables */
    /* REVISION 2011-01-26 CAS: Modified scan of argument */
    %if %scan(%upcase(&vars), 1, %str( *))=_ALL_ %then %do;

        /* Manage scope */
        %local dsid cnt i rc;

        /* Open data set */
        %let dsid=%sysfunc(open(&ds));

        /* Obtain count of variables */
        %let cnt=%sysfunc(attrn(&dsid, nvars));

        /* For each variable, set to a macro variable */
        %do i=1 %to &cnt;
            %if &i=1 %then %let vars=;
            %let vars=&vars %sysfunc(varname(&dsid, &i));
        %end;

        %put NOTE: Variables = &vars;

        /* Close the data set */
        %let rc=%sysfunc(close(&dsid));

    %end;
    %else %if "%substr(&vars, %length(&vars), 1)"=":" %then %do;

        /* Manage scope */
        %local dsid cnt i rc;

        /* Open data set */
        %let dsid=%sysfunc(open(&ds));

        /* Obtain count of variables */
        %let cnt=%sysfunc(attrn(&dsid, nvars));

        /* For each variable, set to a macro variable */
        %local newvar start;
        %let start=%scan(&VARS, 1, %str(:));

        %do i=1 %to &cnt;
            %if &i=1 %then %let vars=;
            %let newvar=%sysfunc(varname(&dsid, &i));
            %if "%substr(&newvar, 1, %length(&start))"="&start" %then
            %let vars=&vars &newvar;
        %end;

        %put NOTE: Variables = &vars;

        /* Close the data set */
        %let rc=%sysfunc(close(&dsid));

    %end;

    /* Manage macros */
    %local num var;

    /* Set initial scan */
    %let num=1;
    %let var=%scan(&vars, &num, %str( ));

    /* Sort if BY specified */
    %if "&BY" ne "" %then %do;
        proc sort data=&DS out=_temp_;
            by &BY;
        run;
    %end;

    /* REVISION 2014-9-26 CAS: Added PRINT argument */
    %if "&BY" ne "" %then %do;
      proc freq data=_temp_
        %if &PRINT=N %then %do;
          noprint
        %end;
      ;
        by &BY;
    %end;
    %else %do;
      proc freq data=&ds
        %if &PRINT=N %then %do;
          noprint
        %end;
      ;
    %end;

    /* Loop through each argument until blank */
    /* REVISION 2011-01-26 CAS: Added scan of argument to look at last var for output */
    /* REVISION 2011-10-17 CAS: Added MISS argument setting */
    %do %while("&var" ne "");

          table &var / out=&LIB..&OUT%sysfunc(tranwrd(&VAR, %str(*), %str(_))) &MISS;

          /* Increment scan */
          %let num=%eval(&num+1);
          %let var=%scan(&vars, &num, %str( ));

    %end;

    run;

    %if "&BY" ne "" %then %do;
        proc sql;
            drop table _temp_;
        quit;
    %end;

%mend FreqLoop;

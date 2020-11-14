%macro DupCheck(ds,by,split=,out=,sort=D,suggest=N,expect=N,small=194,test=N) / des='Check for duplicates';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       DupCheck
        Author:     Chris Swenson
        Created:    2010-09-16

        Purpose:    Check for duplicates within a data set using specified by
                    variables. Additionally, split the single records from duplciates
                    and/or suggest variables that may be involved in duplication.
                    The suggest feature uses the DupVar macro. The macro also outputs
                    a macro variable flag to indicate whether the table is distinct,
                    called DISTINCT with values YES and NO.

        Arguments:  ds      - data set
                    by      - known BY variables, which should identify distinct rows
                    split   - ALL/DUP/ONE flag to indicate whether to split duplicates
                              (DUP), non-duplicates (ONE), or both (ALL)
                              Note: This argument accepts SINGLE, BOTH, and longer
                              versions of the arguments above (e.g., DUPLICATES),
                              converting these to the relevant argument above
                    out     - prefix of the output data set, used when spliting the
                              data set into duplicates/singles, with _dup and/or _one
                              as a suffix
                    suggest - Y/N flag to indicate whether to suggest which variables
                              may contribute to duplication, defaulted to N, for the
                              same reason as SPLIT
                    expect  - Y/N flag to indicate whether duplicates are expected,
                              and when found, will not be reported as a (w)arning
                    sort    - Y/N/D flag to indicate whether or not to sort the output
                              (single and/or duplicate records), which should be used
                              with caution, as it could significantly increase
                              processing time. D indicates "dynamic", which evaluates
                              the size of the data set, using the SMALL= argument, and
                              sets the SORT= flag to Y or N depending on whether the
                              input data is small or not.
                    small=  - size of what is considered a small data set, in MB, as
                              measured by SASHELP.VTABLE, defaulted to 194 MB. This
                              value was set after some highly unscientific tests, so
                              please tweak it based on your environment.
                    test=   - Y/N flag to indicate whether to test the macro.

        External
        Macro
        Programs:   NObs      - Obtains the number of observations in a data set
                    DupVar    - Identifies variables that may contribute to
                                duplication, used when SUGGEST=YES
                    NoLabel   - Removes labels from a data set (used in DupVar)

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2010-09-29  CAS     Added distinct macro variable flag (YES, NO) to identify
                            whether the data set passed through the macro had
                            duplicates post-processing.
        2010-11-02  CAS     Set SUGGEST and EXPECT arguments to 1 character. Users
                            can then spell out YES and NO instead.
        2010-11-12  CAS     Added the SORT= argument for sorting the final output.
        2010-11-12  CAS     Replaced count process with function.
        2010-12-01  CAS     Revised handling of output messages. Revised generation
                            of SQL statements. Added reset for last table to use
                            either OUT_ONE or OUT_DUP.
        2011-01-25  CAS     Moved modification of the SYSLAST macro variable to be
                            able to populate it with any results. Added process to
                            drop output tables if they already exist.
        2011-03-04  CAS     Added Y and REP as synonyms for valid values to the
                            SPLIT argument. Y will split both single and duplicates.
                            REP, REPEAT, or REPEATS will split duplicates. Converted
                            SPLIT to blank when NO (or N) is specified.
        2011-05-20  CAS     Added handling of SPLIT=Y, which I keep specifying by
                            accident. It converts Y to ALL, splitting both duplicate
                            and single records. Additionally modified a substr call
                            since it was generating issues when the string was too
                            small.
        2011-06-20  CAS     Revised values of DISTINCT variable. Added UNKNOWN as the
                            default value, since the process can fail and YES might
                            be deceiving.
        2011-10-10  CAS     Added new macro variables to hold the record counts for
                            the temporary data sets _dup_ and _one_, with additional
                            messages output when splitting is not requested.
        2011-12-14  CAS     Revised reporting to use duplicate record count total
                            rather than the number of distinct records based on the
                            by variables for those with duplicates.
        2012-04-04  CAS     Added a process for identifying small data sets and
                            automatically setting the SORT= argument to Y. A new
                            argument, SMALL=, defines what constitutes a small data
                            set in MB, based on the value in SASHELP.VTABLE. The
                            default argument for SORT= is not D, meaning Dynamic,
                            in which DupCheck will attempt to determine if the data
                            set is small based on the SMALL= argument value.
        2012-04-11  CAS     Added note about sort status, which would be helpful when
                            using the dynamic sort.
        2018-03-07  CAS     Wrapped drops of temporary tables in if statements
                            
        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Settings
     ********************************************************************************/

    %put ;

    /* Set a global result status */
    /* REVISION 2010-09-29 CAS: Added distinct flag */
    %global DISTINCT;
    %let DISTINCT=UNKNOWN;

    /* REVISION 2010-11-02 CAS: Set suggest and expect to 1 character */
    %let suggest=%substr(%upcase(&SUGGEST), 1, 1);
    %let expect=%substr(%upcase(&EXPECT), 1, 1);
    %let sort=%substr(%upcase(&SORT), 1, 1);
    %let test=%substr(%upcase(&TEST), 1, 1);

    /* Check arguments */
    %if "&DS"="" %then %do;
        %put %str(E)RROR: No data set argument specified (argument 1).;
        %return;
    %end;
    %if %eval( %sysfunc(exist(&DS, %str(DATA))) + %sysfunc(exist(&DS, %str(VIEW))) )=0 %then %do;
        %put %str(E)RROR: The specified data set does not exist.;
        %return;
    %end;
    %if "&BY"="" %then %do;
        %put %str(E)RROR: No by argument specified (argument 2).;
        %return;
    %end;
    %if %index(*N*Y*,*&TEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid TEST argument. Please use Y or N.;
        %return;
    %end;

    /* REVISION 2011-03-04 CAS: Converted SPLIT to blank when NO (or N) is specified. */
    /* REVISION 2011-05-20 CAS: Added conversion for Y, which I keep specifying by accident */
    %if "&SPLIT" ne "" %then %do;
        %if %substr(&SPLIT, 1, 1)=N %then %let split=;
        %else %if %substr(&SPLIT, 1, 1)=Y %then %let split=ALL;
    %end;
    %if "&SPLIT" ne "" %then %do;

        /* Use only three characters */
        /* REVISION 2011-05-20 CAS: Revised handling of SPLIT when already short */
        %if %length(&SPLIT)>3 %then %let split=%upcase(%substr(&SPLIT, 1, 3));
        %else %let split=%upcase(&SPLIT);

        /* Convert synonyms */
        /* REVISION 2011-03-04 CAS: Added Y and REP as synonyms for valid values
           to the SPLIT argument. Y will split both single and duplicates. REP,
           REPEAT, or REPEATS will split duplicates. */
        %if &SPLIT=SIN %then %let split=ONE;
        %else %if &SPLIT=REP %then %let split=DUP;
        %else %if &SPLIT=BOT %then %let split=ALL;
        %else %if %substr(&SPLIT, 1, 1)=Y %then %let split=ALL;

        /* Check for (i)nvalid arguments */
        %if %index(*ALL*DUP*ONE*,*&SPLIT*)=0 %then %do;
            %put %str(E)RROR: %str(I)nvalid SPLIT argument specified. Please use ALL, DUP, or ONE.;
            %put %str(E)RROR- ALL: Split both duplicates and single records.;
            %put %str(E)RROR- %str(     )Synonyms: BOTH, YES, or Y.;
            %put %str(E)RROR- DUP: Split only duplicates.;
            %put %str(E)RROR- %str(     )Synonyms: REP or REPEAT(S).;
            %put %str(E)RROR- ONE: Split only single records.;
            %put %str(E)RROR- %str(     )Synonyms: SINGLE.;
            %return;
        %end;

    %end;

    %if %index(*N*Y*,*&SUGGEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid SUGGEST argument specified. Please use Y or N.;
        %return;
    %end;
    %if "&OUT"="" %then %do;
        %let out=%scan(&DS, -1, %str(.));
        %put NOTE: No output data set specified.;
        %put NOTE- Defaulting to &OUT._dup and/or &OUT._one.;
    %end;
    %if %index(*N*Y*,*&EXPECT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid EXPECT argument specified. Please use Y or N.;
        %return;
    %end;
    %if %index(*D*N*Y*,*&SORT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid SORT argument specified. Please use D (Dynamic), Y (Yes), or N (No).;
        %return;
    %end;

    /* Manage scope */
    %local count sqlby sqlon sqlord i msg msg_one msg_dup msg_sug;

    /* Identify how many by variables are specified */
    /* REVISION 2010-11-12 CAS: Replaced count process with COUNTW function */
    %let count=%sysfunc(countw(&BY, %str( )));
    %put ;
    %put NOTE: Number of by variables specified: &COUNT;

    /* Set SQL variables */
    /* REVISION 2010-12-01 CAS: Revised generation of SQL statements */
    %let sqlby=;
    %let sqlon=;
    %let sqlord=;
    %do i=1 %to &COUNT;
        %let sqlby=&SQLBY %scan(&BY, &I);
        %let sqlon=&SQLON a.%scan(&BY, &I)=b.%scan(&BY, &I);
        %let sqlord=&SQLORD a.%scan(&BY, &I);
    %end;
    %let sqlby=%sysfunc(tranwrd(&SQLBY, %str( ), %str(, )));
    %let sqlon=%sysfunc(tranwrd(&SQLON, %str( ), %str( and )));
    %let sqlord=%sysfunc(tranwrd(&SQLORD, %str( ), %str(, )));

    /* Set default messages */
    %let msg=NOTE: No duplicates found in %upcase(&DS) by %upcase(&SQLBY).;
    %let msg_one=;
    %let msg_dup=;
    %let msg_sug=;

    %put ;

    /* Drop pre-existing tables */
    /* REVISION 2011-01-25 CAS: Added process to drop pre-existing tables */
    proc sql;
    %if %sysfunc(exist(&OUT._DUP)) %then %do;
        drop table &OUT._DUP;
    %end;
    %if %sysfunc(exist(&OUT._ONE)) %then %do;
        drop table &OUT._ONE;
    %end;
    quit;

    /* Check if the data set is small */
    /* REVISION 2012-04-04 CAS: Added new section for Dynamic sortting */
    %if &SORT=D %then %do;

        %local size;
        proc sql noprint;
            select round(filesize/1024**2, 1)
            into :size
            from sashelp.vtable
            where memname=upcase("%scan(&DS, -1, %str(.))")
        %if %sysfunc(compress(&DS, %str(.), %str(k)))=. %then %do;
              and libname=upcase("%scan(&DS, 1, %str(.))")
        %end;
        %else %do;
              and libname="WORK"
        %end;
            ;
        quit;

        %let size=&SIZE;
        %put &SIZE;

        %if &SIZE < &SMALL %then %let sort=Y;
        %else %let sort=N;

        %put NOTE: The data set is &SIZE MB. The SORT= argument is set to &SORT..;

    %end;


    /********************************************************************************
       Analysis
     ********************************************************************************/

    /* Count by variable values */
    proc sql;
        create table _bycount_ as
        select &SQLBY, sum(1) as Count
        from &DS
        group by &SQLBY
        order by &SQLBY
        ;
    quit;

    %if &SYSERR>0 %then %return;

    data _dup_ _one_;
        set _bycount_;
        if count>1 then output _dup_;
        else output _one_;
    run;

    /* Set macro variables */
    /* REVISION 2011-10-10 CAS: Added new macro variables */
    /* REVISION 2011-12-14 CAS: Revised how duplicate counts are reported */
    %local dups ones total dupttl duppct onepct;
    %let dups=%nobs(_dup_);
    %let ones=%nobs(_one_);
    %let total=%nobs(&DS, nowarn);
    %if &TOTAL gt 0 %then %do;
        %let dupttl=%eval(&TOTAL - &ONES);
        %let onepct=%str( )(%sysfunc(strip(%sysfunc(putn(%sysevalf(&ONES/&TOTAL), percent8.2)))));
        %let duppct=%str( )(%sysfunc(strip(%sysfunc(putn(%sysevalf(&DUPTTL/&TOTAL), percent8.2)))));
    %end;
    %else %do;
        data _null_;
            set _dup_ end=end;
            format sum 8.;
            retain sum 0;
            sum+count;
            if end then call symputx('dupttl', put(sum, 8.));
        run;
    %end;

    %if %eval( &DUPS + &ONES ) ne %nobs(_bycount_) %then %do;
        %put %str(W)ARNING: The process to split the records into duplicates and single records failed.;
        %put %str(W)ARNING- Please review by argument and the _bycount_, _dup_, and _one_ data sets.;
        %return;
    %end;

    /* REVISION 2011-06-20 CAS: Revised values of DISTINCT variable */
    /* REVISION 2012-04-11 CAS: Added noted about sort status */
    %if &DUPS=0 %then %let distinct=YES;
    %else %do;

        /* Set distinct flag to no */
        /* REVISION 2010-09-29 CAS: Added distinct flag */
        %let DISTINCT=NO;

        %if &EXPECT=N %then %let msg=%str(W)ARNING: Duplicates found in %upcase(&DS) by %upcase(&SQLBY)!;
        %else %if &EXPECT=Y %then %let msg=NOTE: Duplicates found in %upcase(&DS) by %upcase(&SQLBY)! (Expected by user.);

        /* Split single records */
        %if %index(*ALL*ONE*,*&SPLIT*)>0 %then %do;

            proc sql;
            %if &COUNT=1 %then %do;
                create index &SQLBY on _one_ (&SQLBY);
            %end;
            %else %do;
                create index _index_ on _one_ (&SQLBY);
            %end;

                create table &OUT._one(label="Single records from &OUT") as
                select a.*
                from &DS a
                inner join _one_ b
                on &SQLON

            /* REVISION 2010-11-12 CAS: Added sort feature */
            %if &SORT=Y %then %do;
                order by &SQLORD
            %end;
                ;
            quit;

            %local sort_one;
            %if &SORT=Y %then %let sort_one=sorted;
            %else %let sort_one=not sorted;
            %let msg_one=NOTE: &ONES records&ONEPCT were distinct, split into %upcase(&OUT._one) (&SORT_ONE).;

        %end;
        %else %let msg_one=NOTE: &ONES records&ONEPCT were distinct.;

        /* Split duplicates */
        %if %index(*ALL*DUP*,*&SPLIT*)>0 %then %do;

            proc sql;
            %if &COUNT=1 %then %do;
                create index &SQLBY on _dup_ (&SQLBY);
            %end;
            %else %do;
                create index _index_ on _dup_ (&SQLBY);
            %end;

                create table &OUT._dup(label="Duplicates from &OUT") as
                select a.*
                from &DS a
                inner join _dup_ b
                on &SQLON

            /* REVISION 2010-11-12 CAS: Added sort feature */
            %if &SORT=Y %then %do;
                order by &SQLORD
            %end;
                ;
            quit;

            %local sort_dup;
            %if &SORT=Y %then %let sort_dup=sorted;
            %else %let sort_dup=not sorted;
            %let msg_dup=NOTE: &DUPTTL records&DUPPCT were duplicates on &DUPS records, split into %upcase(&OUT._dup) (&SORT_DUP).;

        %end;
        %else %let msg_dup=NOTE: &DUPTTL records&DUPPCT were duplicates on &DUPS records.;

        /* Suggest variables that may cause duplication */
        %if &SUGGEST=Y %then %do;

            %put %str(W)ARNING- ***** Duplicate Variable Search Begin *****; %put ;
            %DupVar(&DS, &BY, TEST=&TEST);
            %put ; %put %str(W)ARNING- ***** Duplicate Variable Search End *****; %put ;

            %let msg_sug=NOTE: See above for variables that may be involved in duplication.;

        %end;

    %end;

    %if &TEST=N %then %do;

        /* Obtain options and turn off */
        %local user_mprint user_notes;
        %let user_mprint=%sysfunc(getoption(mprint));
        %let user_notes=%sysfunc(getoption(notes));
        option nomprint;
        option nonotes;
        option nomlogic nosymbolgen nomacrogen;

        /* Drop temporary tables */
        /* REVISION 2018-03-07 CAS: Wrapped drops in if statements */
        proc sql;
        %if %sysfunc(exist(_bycount_)) %then %do;
          drop table _bycount_;
        %end;
        %if %sysfunc(exist(_dup_)) %then %do;
          drop table _dup_;
        %end;
        %if %sysfunc(exist(_one_)) %then %do;
          drop table _one_;
        %end;
        quit;

        /* Restore options */
        option &USER_NOTES;
        option &USER_MPRINT;

    %end;

    /* Reset last table */
    /* REVISION 2010-12-01 CAS: Added reset for last table to use either OUT_ONE or OUT_DUP */
    /* REVISION 2011-01-25 CAS: Moved reset to end of code */
    %if %sysfunc(exist(&OUT._DUP)) %then %let SYSLAST=&OUT._DUP;
    %else %if %sysfunc(exist(&OUT._ONE)) %then %let SYSLAST=&OUT._DUP;
    %else %let SYSLAST=&DS;

    /* Report */
    /* REVISION 2010-12-01 CAS: Revised handling of output messages */
    /* REVISION 2011-10-12 CAS: Changed logic to output total message */
    %put ;
    %put &MSG;
    %if "&MSG_DUP" ne "" %then %put &MSG_DUP;
    %if "&MSG_ONE" ne "" %then %put &MSG_ONE;
    %if &TOTAL ne -1 %then %put NOTE: &TOTAL records total in %upcase(&DS).;
    %if &SUGGEST=Y %then %put &MSG_SUG;
    %put ;

%mend DupCheck;

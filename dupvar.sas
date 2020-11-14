%macro DupVar(ds,by,distinct=Y,test=N) / des='Find var(s) creating duplicate records';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       DupVar
        Author:     Chris Swenson
        Created:    2010-08-02

        Purpose:    Find variable(s) that may be involved in duplication of records

        Arguments:  ds       - intput data set
                    by       - variable(s) that should identify distinct records
                    distinct - Y/N to complete a distinct count of variables
                    test=    - Y/N to indicate whether to test the macro

        External
        Macro
        Programs:   NObs      - Obtains the number of observations in a data set
                    NoLabel   - Removes labels from a data set

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2010-12-01  CAS     Replaced macro iteration with COUNTW function. Updated
                            output messages.
        2011-03-03  CAS     Modified output when no variables are identified.
                            Added test argument and processing.
        2011-11-21  CAS     Added DISTINCT argument to switch between distinct and
                            raw counts. Also added local statement for I variable.
        2018-08-28  CAS     Changed message color from red to green since EG
                            makes it look like the program had an (e)rror when
                            it did not.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* REVISION 2011-11-21 CAS: Added DISTINCT argument to check */
    %let test=%upcase(%substr(&TEST, 1, 1));
    %let distinct=%upcase(%substr(&DISTINCT, 1, 1));

    /* Check arguments */
    %if "&DS"="" %then %do;
        %put %str(E)RROR: Missing data set argument.;
        %return;
    %end;
    %if "&BY"="" %then %do;
        %put %str(E)RROR: Missing by variable(s) argument.;
        %return;
    %end;
    %if %index(*N*Y*,*&TEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid TEST argument. Please use Y or N.;
        %return;
    %end;
    %if %index(*N*Y*,*&DISTINCT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid DISTINCT argument. Please use Y or N.;
        %return;
    %end;

    /** Set up additional macro variables **/

    %local firstvar count othervars equation1 equation2 user_notes user_mprint;

    /* First variable in by group */
    %let firstvar=%scan(&BY, 1);

    /* Identify how many by variables are specified */
    /* REVISION 2010-12-01 CAS: Replaced macro iteration with COUNTW function */
    %let count=%sysfunc(countw(&BY, %str( )));
    %put NOTE: Number of by variables specified: &COUNT;

    /* Convert DISTINCT argument */
    %if &DISTINCT=Y %then %let distinct=distinct;
    %else %let distinct=;

    /****************************************************************************/

    /* Output contents dropping 'by' variables */
    proc contents
        data=&DS(drop=&BY)
        out=_contents_(keep=name varnum)
        noprint;
    run;

    %if &SYSERR > 3 %then %do;
        %return;
    %end;

    proc sort data=_contents_;
        by varnum;
    run;

    /* Set other variables to macro variable list */
    proc sql noprint;
        select name
        into :othervars separated by ' '
        from _contents_
        order by varnum
        ;
    quit;
    %let othervars=&OTHERVARS;

    /* Add equation for select statement */
    data _contents_;
        set _contents_;
        format equation1 equation2 $1000.;
        equation1=compbl("count(&DISTINCT " || name || ')') || ' as ' || name;
        equation2=compbl('max(' || name || ')') || ' as ' || name;
    run;

    /* Set equations to macro variable */
    proc sql noprint;
        select equation1
        into :equation1 separated by ', '
        from _contents_
        order by varnum
        ;

        select equation2
        into :equation2 separated by ', '
        from _contents_
        order by varnum
        ;
    quit;

    /* Create new table with summary of other variables by 'by' variables */
    proc sql;
        create table _counts_ as
        select distinct
        &EQUATION1
        from &DS
        group by
    /* REVISION 2011-11-21 CAS: Added local statement */
    %local i;
    %do i=1 %to &COUNT;
        %scan(&BY, &I) %if &I ne &COUNT %then %str(,);
    %end;
        ;

        create table _max_ as
        select
        &EQUATION2
        from _counts_
        ;
    quit;

    /* Rotate data */
    proc transpose
            data=_max_
            out=_transpose_(rename=(_name_=Variable col1=Maximum))
    ;
        var &OTHERVARS;
    run;

    %nolabel(_transpose_);

    proc sort data=_transpose_;
        by descending Maximum;
    run;

    %if &TEST=N %then %do;

        %let user_notes=%sysfunc(getoption(notes));
        %let user_mprint=%sysfunc(getoption(mprint));
        option nomprint;
        option nonotes;

        proc sql;
            drop table _contents_
                 table _counts_
                 table _max_
            ;
        quit;

    %end;

    /* REVISION 2010-12-01 CAS: Updated output messages */
    /* REVISION 2019-08-28 CAS: Changed message color from red to green since */
    /* EG makes it look like the program had an (e)rror when it did not. */
    data _results_;
        set _transpose_;
        where Maximum gt 1;
        if _n_=1 then do;
            put %str(" ");
            put "%str(W)ARNING- The following variables are possible identifiers of distinct records,";
            put "%str(W)ARNING- along with %sysfunc(catx(',', %upcase(&BY))):";
            put %str(" ");
        end;
        put "%str(W)ARNING- " Variable Maximum= ;
    run;
    %put ;

    /* REVISION 2011-03-03 CAS: Modified output when no variables are identified. */
    %if %nobs(_results_)=0 %then %do;
        %put %str(W)ARNING- The data set %upcase(&DS) is either distinct by %sysfunc(catx(',', %upcase(&BY)));
        %put %str(W)ARNING- or there are repeats of the same distinct values.;
    %end;

    %if &TEST=N %then %do;

        proc sql;
            drop table _transpose_ table _results_;
        quit;

        option &USER_NOTES;
        option &USER_MPRINT;

    %end;

%mend DupVar;

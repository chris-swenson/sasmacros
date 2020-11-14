%macro TransMerge(ds,by,id,idloc=PREFIX,copy=,out=,prefix=,suffix=,chardef=,numdef=0,test=N) / des='Transpose each column and remerge';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       TransMerge
        Author:     Chris Swenson
        Created:    2012-01-26

        Purpose:    Transpose and re-merge all columns in a data set. The output
                    column names will be the original followed by the ID variable,
                    then any specified suffix.

        Arguments:  ds       - input data set to transpose
                    by       - by variables to transpose by
                    id       - ID to use in naming the output columns
                    idloc=   - location of the ID in the output column name, either
                               PREFIX, SUFFIX, or NONE
                    copy=    - columns to copy and not transpose
                    out=     - output data set name (optional), defaults to input
                    prefix=  - prefix for naming output columns (optional)
                    suffix=  - suffix for naming output columns (optional)
                    chardef= - character default value, defaulted to null
                    numdef=  - numeric default value, defaulted to 0
                    test=    - Y/N flag to indicate whether to test the macro

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2012-02-13  CAS     Added the CHARDEF and NUMDEF arguments to specify what
                            value to use when the value is missing.
        2012-03-14  CAS     Added IDLOC, COPY, TEST, and PREFIX arguments.
        2012-03-21  CAS     Simplified IDLOC argument.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Settings
     ********************************************************************************/

    /* Check for blank arguments */
    %if %superq(DS)=%str() %then %do;
        %put %str(E)RROR: No argument specified for DS.;
        %return;
    %end;
    %if %eval( %sysfunc(exist(%superq(DS), %str(DATA))) + %sysfunc(exist(&DS, %str(VIEW))) )=0 %then %do;
        %put %str(E)RROR: The specified data set or view %superq(DS) does not exist.;
        %return;
    %end;
    %if %superq(BY)=%str() %then %do;
        %put %str(E)RROR: No argument specified for BY.;
        %return;
    %end;
    %if %superq(ID)=%str() %then %do;
        %put %str(E)RROR: No argument specified for ID.;
        %return;
    %end;

    /* Check for argument values in (Y N) */
    %let TEST=%substr(%upcase(&TEST), 1, 1);
    %if %index(*Y*N*,*&TEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for TEST.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;

    /* Check for character values */
    %if %superq(CHARDEF) ne %str() %then %do;
    %if %sysfunc(compress(&CHARDEF, %str(), %str(a))) ne %str() %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for CHARDEF.;
        %put %str(E)RROR: Please use character values only.;
        %return;
    %end;
    %end;

    /* Check for numeric values */
    %if %superq(NUMDEF) ne %str() and %superq(NUMDEF) ne %str(.) %then %do;
    %if %sysfunc(compress(&NUMDEF, %str(), %str(d))) ne %str() %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for NUMDEF.;
        %put %str(E)RROR: Please use numeric values only.;
        %return;
    %end;
    %end;

    /* Check for argument values in (PREFIX SUFFIX) */
    %let IDLOC=%substr(%upcase(&IDLOC), 1, 1);
    %if %index(*P*S*N*,*&IDLOC*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for IDLOC.;
        %put %str(E)RROR- Please use one of the following: P (PREFIX), S (SUFFIX), or N (NONE).;
        %return;
    %end;

    /* Set default for output */
    %if "&OUT"="" %then %let out=&DS;

    /* Manage scope */
    %local count;

    /* Identify how many by variables are specified */
    %let count=%sysfunc(countw(&BY, %str( )));
    %put ;
    %put NOTE: Number of by variables specified: &COUNT;


    /********************************************************************************
       Set Variables
     ********************************************************************************/

    /* Output contents */
    proc contents data=&DS out=_contents(keep=name varnum type) noprint;
    proc sort data=_contents;
        by varnum;
    run;

    /* Filter and create macro variables for names */
    data _null_;
        set _contents end=end;
        where upcase(name) not in (
      %local b w;
      %do b=1 %to %sysfunc(countw(&BY, %str( )));
            "%upcase(%scan(&BY, &B, %str( )))"
      %end;
      %do w=1 %to %sysfunc(countw(&ID, %str( )));
            "%upcase(%scan(&ID, &W, %str( )))"
      %end;
        );
        call symputx(compress('var' || put(_n_, 8.)), name, 'L');
        if end then call symputx('varcnt', put(_n_, 8.), 'L');
    run;

    /* Set variable for ID type */
    data _null_;
        set _contents;
        where upcase(name) in (
      %do w=1 %to %sysfunc(countw(&ID, %str( )));
            "%upcase(%scan(&ID, &W, %str( )))"
      %end;
        );
        call symputx('idtype', type, 'L');
    run;

    /* Drop temporary table */
    %if &TEST=N %then %do;
        proc sql;
            drop table _contents;
        quit;
    %end;


    /********************************************************************************
       Transpose Variables
     ********************************************************************************/

    /* Transpose each variable */
    %local i v;
    %do i=1 %to &VARCNT;

        %put NOTE: Transposing &&VAR&I.....;

        /* Run transposition, using variable name as prefix and optional suffix */
        proc transpose data=&DS out=_&&VAR&I 
      %if &IDLOC=P %then %do;
            prefix=&PREFIX.&&VAR&I.._
          %if %superq(SUFFIX) ne %str() %then %do;
            suffix=&SUFFIX
          %end;
      %end;
      %else %if &IDLOC=S %then %do;
          %if %superq(PREFIX) ne %str() %then %do;
            prefix=&PREFIX
          %end;
            suffix=_&&VAR&I..&SUFFIX
      %end;
      %else %if &IDLOC=N %then %do;
          %if %superq(PREFIX) ne %str() %then %do;
            prefix=&PREFIX
          %end;
          %if %superq(SUFFIX) ne %str() %then %do;
            suffix=&SUFFIX
          %end;
      %end;
        ;
            var &&VAR&I;
            by &BY;
        %if %superq(COPY) ne %str() %then %do;
            copy &COPY;
        %end;
            id &ID;
            where
        %do v=1 %to %sysfunc(countw(&ID, %str( )));
                not missing(%scan(&ID, &V, %str( )))
            %if &V ne %sysfunc(countw(&ID, %str( ))) %then %str( AND );
        %end;
            ;
        run;

        %if &SYSERR>3 %then %return;

        /* Output contents, ordered by variable number */
        proc contents data=_&&VAR&I out=_contents2(keep=name varnum type) noprint;
        proc sort data=_contents2;
            by varnum;
            where upcase(name) not in (
      %local b;
      %do b=1 %to %sysfunc(countw(&BY, %str( )));
            "%upcase(%scan(&BY, &B, %str( )))"
      %end;
            );
        run;

        /* Set each variable to a macro variable, along with its type */
        data _null_;
            set _contents2 end=end;
            where upcase(name) not in ('_NAME_' '_LABEL_');
            call symputx(compress('tvar' || put(_n_, 8.)), name, 'L');
            call symputx(compress('tvar_t' || put(_n_, 8.)), type, 'L');
            if end then call symputx('tvarcnt', put(_n_, 8.), 'L');
        run;

        /* Set default values */
        data _&&VAR&I;
            set _&&VAR&I(keep=&BY
        %do t=1 %to &TVARCNT;
                &&TVAR&T
        %end;
            );
        /* REVISION 2012-02-13 CAS: Added default argument check */
        %do t=1 %to &TVARCNT;
          %if &&TVAR_T&T=1 and %superq(NUMDEF) ne %str() and %superq(NUMDEF) ne %str(.) %then %do;
            if missing(&&TVAR&T) then &&TVAR&T=%superq(NUMDEF);
          %end;
          %else %if &&TVAR_T&T=2 and %superq(CHARDEF) ne %str() %then %do;
            if missing(&&TVAR&T) then &&TVAR&T="%superq(CHARDEF)";
          %end;
        %end;
        run;

        %if &TEST=N %then %do;
            proc sql;
                drop table _contents2;
            quit;
        %end;

    %end;


    /********************************************************************************
       Remerge Variables
     ********************************************************************************/

    proc sql;
        create table _temp as
        select distinct *
        from &DS(keep=&BY) a
    %do i=1 %to &VARCNT;
        natural join _&&VAR&I a&I
    %end;
        ;

    %if &TEST=N %then %do;
      %do i=1 %to &VARCNT;
        drop table _&&VAR&I;
      %end;
    %end;
    quit;

    /* Sort variables together */

    /* Output contents, dropping BY variables */
    proc contents data=_temp out=_contents3(keep=name varnum) noprint;
    proc sort data=_contents3;
        by varnum;
        where upcase(name) not in (
      %local b;
      %do b=1 %to %sysfunc(countw(&BY, %str( )));
            "%upcase(%scan(&BY, &B, %str( )))"
      %end;
        );
    run;

    /* Sort by the number in the variable name */
    proc sql;
        create table _contents4 as
        select *
        from _contents3
        order by compress(name, '', 'd'), input(compress(name, '', 'kd'), 8.)
        ;
    quit;

    /* Output to a macro variable list */
    %local varlist varlist&I;
    proc sql noprint;
        select name
        into :varlist separated by ', '
        from _contents4
        ;
    quit;

    /* Reorder the columns */
    proc sql;
        create table &OUT as
        select %sysfunc(tranwrd(&BY, %str( ), %str(, ))), &VARLIST
        from _temp
        ;
    quit;

    /* Drop temporary tables */
    %if &TEST=N %then %do;
        proc sql;
            drop table _contents3, _contents4, _temp;
        quit;
    %end;


    /********************************************************************************
       Final Messages
     ********************************************************************************/

    %dupcheck(&OUT, &BY);

    %put NOTE: The data set &DS was transposed to &OUT..;
    %put NOTE: There were %nobs(&DS) records and %nvars(&DS) in &DS..;
    %put NOTE: There are %nobs(&OUT) records and %nvars(&OUT) columns in &OUT..;

%mend TransMerge;


%macro LengthCheck(ds,vars,out=lengths,fmtlen=12) / des='Output the max length for variables';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       LengthCheck
        Author:     Chris Swenson
        Created:    2011-09-23

        Purpose:    Output the maximum length for variables

        Arguments:  ds      - input data set
                    vars    - input variable(s), can use _ALL_ to specify all vars
                    out=    - output data set, defaulted to Lengths
                    fmtlen= - format length of the output length column, defaulted
                              to 12

        Dependency: VarInfo - outputs information about variable, in this instance,
                              the variable type (char, num)

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check for blank arguments */
    %if %superq(DS)=%str() %then %do;
        %put %str(E)RROR: No argument specified for DS.;
        %return;
    %end;
    %if %superq(VARS)=%str() %then %do;
        %put %str(E)RROR: No argument specified for VARS.;
        %return;
    %end;
    %if %superq(FMTLEN)=%str() %then %do;
        %put %str(E)RROR: No argument specified for FMTLEN.;
        %return;
    %end;

    /* Check that the data set has records */
    %local ok;
    %let ok=0;
    data _null_;
        set &DS(obs=1);
        if _n_=1 then call symputx('ok', '1');
    run;
    %if &OK=0 %then %do;
        %put %str(E)RROR: The data set &DS is empty.;
        %return;
    %end;

    /* Check for numeric values */
    %if %sysfunc(compress(&FMTLEN, %str(), %str(d))) ne %str() %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for FMTLEN.;
        %put %str(E)RROR: Please use numeric values only.;
        %return;
    %end;

    /* Check for existing data */
    %if %sysfunc(exist(&OUT)) %then %do;
        %put %str(W)ARNING: The output data set &OUT already exists.;
        %return;
    %end;

    /* If ALL is specified, output all of the variables */
    %if %upcase(&VARS)=_ALL_ %then %do;

        proc contents data=&DS out=_contents_(keep=name varnum) noprint;
        proc sort data=_contents_;
            by varnum;
        run;

        proc sql noprint;
            select name
            into :vars separated by ' '
            from _contents_
            ;

            drop table _contents_;
        quit;

    %end;

    %local count i var type;
    %let count=%sysfunc(countw(&VARS, %str( )));

    %do i=1 %to &COUNT;

        %let var=%scan(&VARS, &I, %str( ));
        %let type=%VarInfo(&DS, &VAR, type);
        %let fmt=%VarInfo(&DS, &VAR, format);

        proc sql;
            create table _temp_ as
            select "&VAR" as Column length=32
        %if &TYPE=C %then %do;
                , min(length(&VAR)) as Length_Min length=8 format=comma&FMTLEN..
                , max(length(&VAR)) as Length length=8 format=comma&FMTLEN..
                , . as Max length=8 format=comma&FMTLEN..
        %end;
        %else %do;
                , min(length(strip(put(&VAR, &FMT.)))) as Length_Min length=8 format=comma&FMTLEN..
                , max(length(strip(put(&VAR, &FMT.)))) as Length length=8 format=comma&FMTLEN..
                , max(&VAR) as Max length=8 format=comma&FMTLEN..
        %end;
            from &DS
            ;
        quit;

        proc append base=&OUT data=_temp_;
        run;

        proc sql;
            drop table _temp_;
        quit;

    %end;

    data _null_;
        set &OUT;
        if _n_=1 then do;
            put          @35 'Length' @50 'Length' @65 'Max';
            put 'Column' @35 '(min)'  @50 '(max)'  @65 'Value';
            put '------' @35 '------' @50 '------' @65 '-----';
        end;
        if missing(max) then put column @35 length_min @50 length @65 'n/a';
        else put column @35 length_min @50 length @65 max;
    run;

%mend LengthCheck;

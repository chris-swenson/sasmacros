%macro freqs(ds,vars=,by=,exclude=N,out=,lib=) 
  / des = "Output frequencies for variables"
;

  /****************************************************************************
    BEGIN MACRO HEADER
   ****************************************************************************

    Name:       Freqs
    Author:     Chris Swenson
    Created:    2012-02-02

    Purpose:    Output frequencies for all variables in a data set

    Arguments:  ds        - input data set
                vars=     - variables to include in the output, defaults to all
                by=       - split by variable
                exclude=  - Y/N to indicate that the VARS list is an exclusion
                            list, defaulted to N
                out=      - output data set name, defaulted to DS_freqs
                lib=      - output library, defaulted to WORK or USER

    Revisions
    ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    Date        Author  Comments
    ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
    2012-03-12  CAS     Set Number column to highest number/decimal lengths to
                        adequately display all numeric values.
    2012-03-12  CAS     Split macro variable generation from contents recoding.
    2012-04-17  CAS     Added a sort on the final output to order by column and
                        descending percent.
    2018-05-08  CAS     Excluded BY variables from frequencies.

    YYYY-MM-DD  III     Please use this format and insert new entries above

   ****************************************************************************
    END MACRO HEADER
   ****************************************************************************/


  /****************************************************************************
     Settings
   ****************************************************************************/

  /* Check the data set argument */
  %if "&DS" = "" %then %do;
    %put %str(E)RROR: No data set specified.;
    %return;
  %end;
  %if %eval(%sysfunc(exist(&DS)) + %sysfunc(exist(&DS, VIEW))) = 0 %then %do;
    %put %str(E)RROR: The specified data set does not exist.;
    %return;
  %end;

  /* Handle the exclude flag */
  %let exclude = %substr(%upcase(&EXCLUDE), 1, 1);
  %if %index(*Y*N*,*&EXCLUDE*) = 0 %then %do;
    %put %str(E)RROR: %str(I)nvalid argument specified for EXCLUDE.;
    %put %str(E)RROR- Please use one of the following: Y or N.;
    %return;
  %end;
  %local not;
  %if &EXCLUDE = Y %then %let not = NOT;

  /* Default the output variable name */
  %if "&OUT" = "" %then %let out = %scan(&DS, -1, %str(.))_freq;

  /* Check to see if output already exists */
  %if %sysfunc(exist(&OUT)) = 1 %then %do;
    proc sql;
      drop table &OUT;
    quit;
  %end;

  /* Default the lib argument based on whether the USER option is in effect. */
  %if "&LIB" = "" %then %do;
    %if %sysfunc(libref(user)) = 0 %then %let lib = user;
    %else %let lib = work;
    %put NOTE: Library argument LIB= set to &LIB..;
  %end;

  /* Generate BY variable list */
  %local bylist bylistsql y;
  %if %superq(BY) ne %str() %then %do;
    %do y = 1 %to %sysfunc(countw(&BY, %str( )));
      %if &Y = 1 %then %do;
        %let bylist = "%scan(%upcase(&BY), &Y, %str( ))";
        %let bylistsql = a.%scan(%upcase(&BY), &Y, %str( ));
      %end;
      %else %do;
        %let bylist = &BYLIST, "%scan(%upcase(&BY), &Y, %str( ))";
        %let bylistsql = &BYLISTSQL, a.%scan(%upcase(&BY), &Y, %str( ));
      %end;
    %end;
    %put NOTE: bylist = &BYLIST;
    %put NOTE: bylistsql = &BYLISTSQL;
  %end;


  /****************************************************************************
     Obtain List of Variables
   ****************************************************************************/

  proc contents data = &DS out = _contents
    (keep = name varnum type label length format formatd formatl)
    noprint
  ;
  run;
  
  /* REVISION 2018-05-08 CAS: Excluded BY variables from frequencies */
  proc sort data = _contents;
    by varnum;
  %if "&BY" ne "" %then %do;
    where upcase(name) not in (&BYLIST);
  %end;
  run;

  data _contents;
    set _contents;
  /* Handle included/excluded variables */
  %local v;
  %if %superq(VARS) ne %str() %then %do;
    where upcase(name) &NOT in (
    %do v = 1 %to %sysfunc(countw(&VARS, %str( )));
      "%scan(%upcase(&VARS), &V, %str( ))"
      %if &V ne %sysfunc(countw(&VARS, %str( ))) %then %str(, );
    %end;
    );
  %end;

    format format2 $32. newfmt $50.;
    if formatl = 0 then formatl = .;
    if formatd = 0 then formatd2 = '';
    else formatd2 = left(put(formatd, 8.));
    if format = '' then do;
      if type = 2 then format2 = '$';
      else format2 = format;
    end;
    else format2 = format;
    newfmt = compress(
      format2 || left(put(coalesce(formatl, length) , 8.)) || '.' || formatd2
    );
  run;

  /* REVISION 2012-03-12 CAS: Split macro variable creation */
  data _null_;
    set _contents end = end;
    call symputx(compress('var' || put(_n_, 8.)), name, 'L');
    call symputx(compress('type' || put(_n_, 8.)), type, 'L');
    call symputx(compress('format' || put(_n_, 8.)), newfmt, 'L');
    if end then call symputx('varcnt', put(_n_, 8.), 'L');
  run;

  %if %symexist(varcnt) = 0 %then %do;
    %put %str(E)RROR: No variables match specifications.;
    %return;
  %end;

  /* REVISION 2012-03-12 CAS: Added format length and decimal length macros */
  %local fmtlmax fmtdmax;
  proc sql noprint;
    select
        max(input(scan(compress(newfmt, '.', 'kd'), 1, '.'), 8.))
      , max(case 
          when input(scan(compress(newfmt, '.', 'kd'), 1, '.'), 8.)
            = input(scan(compress(newfmt, '.', 'kd'), -1, '.'), 8.)
          then .
          else input(scan(compress(newfmt, '.', 'kd'), -1, '.'), 8.)
        end)
    into :fmtlmax, :fmtdmax
    from _contents
    where find(newfmt, '$') = 0
    ;
  quit;

  %let fmtlmax = &FMTLMAX;
  %let fmtdmax = &FMTDMAX;

  /* Convert lengths */
  /* REVISION 2012-05-13 CAS: Correction for long formats. */
  %if &FMTLMAX = &FMTDMAX or &FMTDMAX = . %then %let fmtdmax = ;
  %if %superq(FMTLMAX) = %str() or &FMTLMAX = . or &FMTLMAX > 32
  %then %let fmtlmax = 8;


  /****************************************************************************
     Output Frequencies
   ****************************************************************************/

  /* Sort if BY specified */
  %local input;
  %let input = &DS;
  %if "&BY" ne "" %then %do;
    proc sort data = &DS out = _temp_;
      by &BY;
    run;
    %let input = _temp_;
  %end;
   
  proc freq data = &INPUT noprint;
  %if "&BY" ne "" %then %do;
    by &BY;
  %end;

  /* Loop through each variable */
  %local i;
  %do i = 1 %to &VARCNT;
    table &&VAR&I / out = _temp_&I missing;
  %end;

  run;

  %if "&BY" ne "" %then %do;
    proc sql;
      drop table _temp_;
    quit;
  %end;

  /* Append all to master */
  %do i = 1 %to &VARCNT;

    /* REVISION 2012-03-12 CAS: Set Number to highest number/decimal lengths */
    data _temp_&I(drop = &&VAR&I percent_calc);
      format 
        Column $32. 
        Text $500. 
        Number &FMTLMAX..&FMTDMAX 
        Format $32. 
        Count comma12. 
        Percent percent8.2
      ;
      set _temp_&I(rename = (percent = percent_calc));
      column = "&&VAR&I";
    %if &&TYPE&I = 1 %then %do;
      text = strip(put(&&VAR&I, &&FORMAT&I));
      number = &&VAR&I;
    %end;
    %else %do;
      text = &&VAR&I;
      number = .;
    %end;
      format = "&&FORMAT&I";
      percent = percent_calc/100;
      attrib _all_ label = '';
    run;

    proc append base = _freqs data = _temp_&I;
    run;

    proc sql;
      drop table _temp_&I;
    quit;

  %end;

  /* Combine data for final output */
  /* REVISION 2012-04-17 CAS: Added a sort for the column and desc percent */
  proc sql;
    create table &LIB..&OUT as
    select distinct
  %if "&BY" ne "" %then %do;
        &BYLISTSQL
      , a.Column
  %end;
  %else %do;
        a.Column
  %end;
      , b.Label label = 'Label'
      , a.Text
      , a.Number
      , a.Format
      , a.Count
      , a.Percent
    from _freqs a
    left join _contents b
    on a.column = b.name
    order by 
  %if "&BY" ne "" %then %do;
        &BYLISTSQL
      , a.Column
  %end;
  %else %do;
        a.Column
  %end;
      , a.percent desc
    ;
  quit;

  proc sql;
    drop table _freqs, _contents;
  quit;


  /****************************************************************************
     Report
   ****************************************************************************/

  %local bynote;
  %if %superq(BY) ne %str() %then %let bynote = , by %upcase(&BY);
  %put NOTE: Frequencies generated for the data set %upcase(&DS)&BYNOTE..;
  %put NOTE: Frequencies output to %upcase(&LIB..&OUT).;

  %if %superq(VARS) ne %str() %then %do;
    %if &EXCLUDE = N
    %then %put NOTE- The following variables were included: %upcase(&VARS);
    %else %put NOTE- The following variables were excluded: %upcase(&VARS);
  %end;

%mend freqs;

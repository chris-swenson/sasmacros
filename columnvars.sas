%macro columnvars(table, columnvar, name=, where=, test=N) 
  / des = "Set vars for tables from vcolumn"
;

  /****************************************************************************
    BEGIN MACRO HEADER
   ****************************************************************************

      Name:       ColumnVars
      Author:     Chris Swenson
      Created:    2018-07-31

      Purpose:    Set macro variables for tables from SASHELP.VColumn

      Arguments:  
        table     - library to set columns for
        columnvar - name of macro variables for tables
        name=     - filter for the column name within the table
        where=    - filter criteria for SASHELP.VColumn
        test=     - whether to test the macro program

      Family:     Macro Variable Generation Macro Program
        ColumnVars  - Create one or more macro variables form the 
                      SASHELP.VCOLUMN table, one variable per column.
        IntoList    - Create a macro variable that is a list of values from a 
                      column in a data set. Optionally define the delimiter and 
                      filter the input data set.
        ObsMac      - Create one or more macro variables from a column in a data
                      set, where the macro variable names consist of the column 
                      name with the appended observation number.
        SetVars     - Create one or more macro variables from the variable names
                      in a data set. The generated macro variable can either be 
                      a list within one macro variable or multiple macro 
                      variables named with the specified prefix and appended 
                      observation number.
        TableVars   - Create one or more macro variables from the SASHELP.VTABLE
                      table, one variable per table.
        VarMac      - Create macro variables from two columns, where one column 
                      names the macro variable and another supplies the value. 
                      Optionally filter the input data set.

      Revisions
      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
      Date        Author  Comments
      ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

      YYYY-MM-DD  III     Please use this format and insert new entries above

   ****************************************************************************
    END MACRO HEADER
   ****************************************************************************/


  /****************************************************************************
     Check Arguments
   ****************************************************************************/

  /* Uppercase arguments */
  %let columnvar = %upcase(&COLUMNVAR);
  %let test = %upcase(&TEST);

  /* Set local variables */
  %local lib tbl;

  /* Scan ds argument for a word following a period, and set the table to that word */
  %let tbl = %upcase(%scan(&TABLE, 2, %str(.)));

  /* If the table is populated, scan the ds argument for a word preceding
     a period, and set the library to that word if available */
  %if "&TBL" ne "" %then %let lib = %upcase(%scan(&TABLE, 1, %str(.)));

  /* If the table is blank, then set the table to the original argument */
  %if "&TBL" = "" %then %let tbl = &TABLE;

  /* Set lib to work if blank */
  %if "&LIB" = "" %then %do;
    %if %sysfunc(libref(user))=0 %then %let lib = USER;
    %else %let lib = WORK;
    %put NOTE: Library argument LIB= set to &LIB..;
  %end;

  /* Check arguments */
  %if "&TABLE" = "" %then %do;
    %put %str(E)RROR: Table argument required.;
    %return;
  %end;
  %if %sysfunc(libref(&LIB)) > 0 %then %do;
    %put %str(E)RROR: Library does not exist.;
    %return;
  %end;
  %if "&COLUMNVAR" = "" %then %do;
    %put %str(E)RROR: Column variable argument required.;
    %return;
  %end;
  %if %index(*Y*N*, *&TEST*) = 0 %then %do;
    %put %str(E)RROR: The test argument is %str(i)nvalid. Please use Y or N.;
    %return;
  %end;


  /****************************************************************************
     Delete Macro Variables
   ****************************************************************************/

  %put ;
  %put NOTE: Deleting macro variables that begin with "&COLUMNVAR".;
  %put ;

  /* Copy VMacro for specified variables */
  proc sql;
    create table _delete_ as
    select * from sashelp.vmacro
    where (
      substr(upcase(name), 1, length("&COLUMNVAR")) = ("&COLUMNVAR")
      or upcase(name) = ("&COLUMNVAR.CNT")
    )
    and name ne "COLUMNVAR"
    ;
  quit;

  /* Note: The next step needs to be separate, as the macro deletion needs to
     access SASHELP.VMACRO. If it is used in the step above, it is locked out
     from deleting records in the table. */
  data _null_;
    set _delete_;
    call execute('%symdel ' || name || ';');
  run;


  /****************************************************************************
     Create Macro Variables
   ****************************************************************************/

  %global &COLUMNVAR.CNT;
  %local nameflag whereflag;
  %let &COLUMNVAR.CNT=0;
  %let nameflag=0;
  %let whereflag=0;

  %put ;
  %put NOTE: Creating macro variables for columns in &TABLE.;
  %if %superq(NAME) ne %str() %then %do;
    %put NOTE- where the column name meets the following criteria: &NAME.;
    %let nameflag=1;
  %end;
  %if %superq(WHERE) ne %str() %then %do;
    %put NOTE- where the following criteria is met: %superq(WHERE).;
    %let whereflag=1;
  %end;
  %put ;

  /* Copy vcolumn */
  proc sql;
    create table _columns_ as
    select * from sashelp.vcolumn
    where libname = "&LIB"
    and memname = "&TBL"
    ;
  quit;

  /* Filter for names */
  %if &NAMEFLAG=1 %then %do;
    data _columns_;
      set _columns_;
      where substr(upcase(name), 1, %length(&NAME)) = %upcase("&NAME");
    run;
  %end;

  /* Set variables */
  data _null_;
    set _columns_ end=end;

  /* Set filter if specified */
  %if &WHEREFLAG=1 %then %do;
    where &WHERE;
  %end;

    /* Declare variables globally then set value */
    call symputx(compress("&COLUMNVAR" || put(_n_, 8.)), name, 'G');

    /* Set count variable */
    if end then call symputx("&COLUMNVAR.CNT", put(_n_, 8.), 'G');
  run;


  /****************************************************************************
     Report Created Macro Variables
   ****************************************************************************/

  /* Output created macro variables */
  proc sql noprint;
    create table _mvars_ as
    select name, value
    from sashelp.vmacro
    where scope = "GLOBAL"
    and (
      substr(upcase(name), 1, length("&COLUMNVAR"))=("&COLUMNVAR")
      or upcase(name)=("&COLUMNVAR.CNT")
    )

    /* Order the variables by the number on the variable */
    order by input(compress(name, '', 'kd'), 8.)
    ;
  quit;

  /* Print varibles to the log */
  data _null_;
    set _mvars_ end=end;
    if _n_=1 then do;
      put "NOTE: The following macro variables were created:";
      put " ";
      put "NOTE- Name " @40 "Value";
      put "NOTE- ---- " @40 "-----";
    end;
    put "NOTE- " name @40 value;
    if end then put "NOTE-";
  run;

  /****************************************************************************/

  /* Obtain option and temporarily turn off */
  %local user_mprint user_notes;
  %let user_mprint=%sysfunc(getoption(mprint));
  %let user_notes=%sysfunc(getoption(notes));
  option nomprint;
  option nonotes;
  option nomlogic nomfile nosymbolgen;

  /* Drop temporary tables */
  %if &TEST=N %then %do;
    proc sql;
      drop table _delete_, _columns_, _mvars_;
    quit;
  %end;

  /* Reset mprint option to original setting */
  option &USER_NOTES;
  option &USER_MPRINT;

%mend columnvars;

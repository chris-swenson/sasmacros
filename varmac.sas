%macro VarMac(ds,namevar,valuevar,where=) / des="Create macro variables from two columns";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       VarMac
        Author:     Chris Swenson
        Created:    2010-06-14

        Purpose:    Create macro variables from two columns in a data set

        Arguments:  ds       - input data set
                    namevar  - variable containing the macro variable names
                    valuevar - variable containing the macro variable values
                    where=   - filter criteria for input data set

        Family:     Macro Variable Generation Macro Program

                    ColumnVars- Create one or more macro variables form the 
                                SASHELP.VCOLUMN table, one variable per column.
                    IntoList  - Create a macro variable that is a list of values from
                                a column in a data set. Optionally define the
                                delimiter and filter the input data set.
                    ObsMac    - Create one or more macro variables from a column in
                                a data set, where the macro variable names consist of
                                the column name with the appended observation number.
                    SetVars   - Create one or more macro variables from the variable
                                names in a data set. The generated macro variable
                                can either be a list within one macro variable or
                                multiple macro variables named with the specified
                                prefix and appended observation number.
                    TableVars - Create one or more macro variables from the
                                SASHELP.VTABLE, one variable per table.
                    VarMac    - Create macro variables from two columns, where one
                                column names the macro variable and another supplies
                                the value. Optionally filter the input data set.

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2012-01-12  CAS     Added the named variable count as a global output.
        2012-03-22  CAS     Added capability to handle empty data sets without
                            generating issues in the log. Corrected how the count
                            variable is handled.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Check Arguments
     ********************************************************************************/

    %if "&DS"="" %then %do;
        %put %str(E)RROR: Missing data set argument.;
        %return;
    %end;
    %if "&NAMEVAR"="" %then %do;
        %put %str(E)RROR: Missing source variable argument.;
        %return;
    %end;
    %if "&VALUEVAR"="" %then %do;
        %put %str(E)RROR: Missing target variable argument.;
        %return;
    %end;


    /********************************************************************************
       Delete Macro Variables
     ********************************************************************************/

    data _null_;
        set &DS;
    %if %superq(where) ne %str() %then %do;
        where &WHERE;
    %end;
        call execute('%symdel ' || &NAMEVAR || ' / nowarn;');
    run;


    /********************************************************************************
       Create Macro Variables
     ********************************************************************************/

    /* REVISION 2012-03-22 CAS: Added default for count variable */
    %global &NAMEVAR.CNT;
    %let &NAMEVAR.CNT=0;

    /* Set variable in data set to macro variable */
    /* REVISION 2012-01-12 CAS: Made count variable global */
    data _null_;
        set &DS end=end;
    %if %superq(where) ne %str() %then %do;
        where &WHERE;
    %end;
        call symputx(&NAMEVAR, &VALUEVAR, 'G');
        call symputx(compress(upcase('namevar') || put(_n_, 8.)), upcase(&NAMEVAR), 'L');
        if end then call symputx("&NAMEVAR.CNT", put(_n_, 8.), 'G');
    run;


    /********************************************************************************
       Report Created Macro Variables
     ********************************************************************************/

    /* Query for count variable */
    /* REVISION 2012-01-12 CAS: Added */
    /* REVISION 2012-03-22 CAS: Fixed issue with count variable not outputting */
    proc sql;
        create table _mvarscnt_ as
        select * from sashelp.vmacro
        where scope="GLOBAL"
          and name="%upcase(&NAMEVAR)CNT"
        ;
    quit;

    /* Select macro variables */
    %if %symexist(NAMEVAR1)=1 %then %do;

        %local nv;
        proc sql;
            create table _mvarsall_ as
            select * from sashelp.vmacro
            where scope="GLOBAL"
              and name in (
        %do nv=1 %to &&&NAMEVAR.CNT;
            "&&NAMEVAR&NV"
        %end;
            )
            order by name
            ;
        quit;

    %end;

    /* REVISION 2012-01-12 CAS: Added append to put count at top */
    proc append base=_mvars_ data=_mvarscnt_;
  %if %symexist(NAMEVAR1)=1 %then %do;
    proc append base=_mvars_ data=_mvarsall_;
  %end;
    run;

    /* Write macro variables to log */
    data _null_;
        set _mvars_ end=end;
        if _n_=1 then do;
            put "NOTE: The following macro variables were created:";
            put " ";
            put "NOTE- Name" @40 "Value";
            put "NOTE- ----" @40 "-----";
        end;
        put "NOTE- " name @40 value;
        if end then put "NOTE-";
    run;

    /* Drop temporary table */
    %local user_notes user_mprint;
    %let user_notes=%sysfunc(getoption(notes));
    %let user_mprint=%sysfunc(getoption(mprint));
    option nomprint nonotes;
    proc sql;
        drop table _mvars_, _mvarscnt_ 
    %if %symexist(NAMEVAR1)=1 %then %do;
        , _mvarsall_
    %end;
        ;
    quit;
    option &USER_NOTES;
    option &USER_MPRINT;

%mend VarMac;

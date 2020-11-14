%macro SetVars(ds,mvar,type=MULTI,vtype=,sepby=BLANK,where=,sortby=O) / des="Set data set variables to macro variables";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       SetVars
        Author:     Chris Swenson
        Created:    2010-10-18

        Purpose:    Create one or more macro variables from the variable names in a
                    data set. The generated macro variable can either be a list
                    within one macro variable or multiple macro variables named with
                    the specified prefix and appended observation number.

        Arguments:  ds      - input data set
                    mvar    - macro variable to generate
                    type=   - either MULTI for multiple macro variables with a number
                              appended or LIST for for one macro variable that contains
                              a list of values
                    vtype=  - variable type to set as macro variables, either C for
                              character or N for numeric
                    sepby=  - identifies the separator between items (see below)
                    where=  - additional filter criteria for a column
                    sortby= - specifies how to sort the variables, either by variable
                              order (O) (default) or variable name (N).

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
        2010-12-29  CAS     Modified the manner in which macro variables are reported.
        2011-05-20  CAS     Completely revised program to use normal DATA and PROC
                            steps instead of the I/O functions, which were causing
                            issues when used repeatedly for some unknown reason.
        2011-05-26  CAS     Added filter for variable type: either character or
                            numeric. Leave blank for both.
        2011-05-26  CAS     Added where option and filter step.
        2012-02-27  CAS     Changed SQL to SASHELP for a distinct list of the name
                            column instead of the whole table. This eliminates issues
                            when generated macro variables are very long.
        2012-03-08  CAS     Added the SEPBY argument to assist with adding different
                            delimiters.
        2012-03-21  CAS     Minor correction on reporting.
        2012-03-22  CAS     Added default to count variable (0).
        2012-04-17  CAS     Added contents table to drop list.
        2012-04-17  CAS     Added a check for issues after applying filter.
        2012-05-04  CAS     Added the sortby= argument for specifying the order of the
                            output variables, either by name or original order.
        2012-05-16  CAS     Changed order method for LIST type on report.
        2012-05-16  CAS     Corrected reporting where some lines were omitted.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Check Arguments
     ********************************************************************************/

    %let mvar=%upcase(&MVAR);
    %let type=%substr(%upcase(&TYPE), 1, 1);

    /* Check arguments */
    %if "&DS"="" %then %do;
        %put %str(E)RROR: Missing data set argument.;
        %return;
    %end;
    %if %sysfunc(exist(&DS))=0 %then %do;
    %if %sysfunc(exist(&DS, VIEW))=0 %then %do;
        %put %str(E)RROR: Data set or view does not exist.;
        %return;
    %end;
    %end;
    %if "&MVAR"="" %then %do;
        %put %str(E)RROR: Missing macro variable name argument.;
        %return;
    %end;
    %if "&TYPE"="" %then %do;
        %put %str(E)RROR: No type specified. Please use MULTI or LIST.;
        %return;
    %end;
    %if %index(*L*M*,*&TYPE*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid type specified. Please use MULTI or LIST.;
        %return;
    %end;
    %if "&VTYPE" ne "" %then %do;
        %let vtype=%substr(%upcase(&VTYPE), 1, 1);
        %if %index(*C*N*,*&VTYPE*)=0 %then %do;
            %put %str(E)RROR: %str(I)nvalid variable type (VTYPE) specified. Please use C or N.;
            %return;
        %end;
    %end;
    /* REVISION 2012-03-08 CAS: Added check */
    %if "&SEPBY"="" %then %do;
        %put %str(E)RROR: No argument specified for SEPBY.;
        %goto sephelp;
    %end;
    /* REVISION 2012-05-04 CAS: Added check for new argument */
    /* Check for argument values in (O N) */
    %let sortby=%substr(%upcase(&SORTBY), 1, 1);
    %if %index(*O*N*,*&SORTBY*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for SORTBY.;
        %put %str(E)RROR- Please use one of the following: O (order) or N (name).;
        %return;
    %end;


    /********************************************************************************
       Determine Separator
     ********************************************************************************/

    /* REVISION 2012-03-08 CAS: Added section */

    %local separator;
    %let sepby=%lowcase(&SEPBY);
    %if %length(&SEPBY)>3 %then %do;
        %let sepby=%substr(&SEPBY, 1, 3);
    %end;

    /* Common: space, comma, and parentheses */
          %if %index(*bla*spa*,*&SEPBY*)>0  %then %let separator=' ';
    %else %if %index(*com*,*&SEPBY*)>0      %then %let separator=', ';
    %else %if %index(*par*,*&SEPBY*)>0      %then %let separator=') (';

    /* Quotes */
    %else %if %index(*q*,*&SEPBY*)>0        %then %let separator="' '";
    %else %if %index(*qc*,*&SEPBY*)>0       %then %let separator="', '";
    %else %if %index(*qq*,*&SEPBY*)>0       %then %let separator='" "';
    %else %if %index(*qqc*,*&SEPBY*)>0      %then %let separator='", "';

    /* Misc */
    %else %if %index(*bra*,*&SEPBY*)>0      %then %let separator='] [';
    %else %if %index(*cur*,*&SEPBY*)>0      %then %let separator='} {';
    %else %if %index(*pip*,*&SEPBY*)>0      %then %let separator=' | ';
    %else %if %index(*dot*per*,*&SEPBY*)>0  %then %let separator='. ';
    %else %if %index(*has*,*&SEPBY*)>0      %then %let separator='#';
    %else %if %index(*ast*sta*,*&SEPBY*)>0  %then %let separator='*';
    %else %if %index(*das*hyp*,*&SEPBY*)>0  %then %let separator='-';
    %else %if %index(*lin*und*,*&SEPBY*)>0  %then %let separator='_';
    %else %if %index(*sla*,*&SEPBY*)>0      %then %let separator='/';
    %else %if %index(*bac*,*&SEPBY*)>0      %then %let separator='\';
    %else %do;
        %put %str(E)RROR: %str(I)nvalid SEPBY argument.;
        %sephelp:
        %put ;
        %put %str(E)RROR- Please use one of the following:;
        %put %str(E)RROR- ASTERISK (*);
        %put %str(E)RROR- BACKSLASH (\);
        %put %str(E)RROR- BLANK ( );
        %put %str(E)RROR- BRACKET ([]);
        %put %str(E)RROR- COMMA (,);
        %put %str(E)RROR- CURLY BRACKET ({});
        %put %str(E)RROR- DOT (. );
        %put %str(E)RROR- DASH (-);
        %put %str(E)RROR- HASH (#);
        %put %str(E)RROR- HYPHEN (-);
        %put %str(E)RROR- LINE (_);
        %put %str(E)RROR- PARENTHESES;
        %put %str(E)RROR- PERIOD (. );
        %put %str(E)RROR- PIPE ( | );
        %put %str(E)RROR- Q (single quotes: ' ');
        %put %str(E)RROR- QC (single quotes and commas: ', ');
        %put %str(E)RROR- QQ (double quotes: " ");
        %put %str(E)RROR- QQC (double quotes and commas: ", ");
        %put %str(E)RROR- SLASH (/);
        %put %str(E)RROR- SPACE ( );
        %put %str(E)RROR- STAR (*);
        %put %str(E)RROR- UNDERSCORE (_);
        %put ;
        %put %str(E)RROR- Note: It is only necessary to specify 3 characters for the above arguments.;
        %put ;
        %return;
    %end;


    /********************************************************************************
       Delete Macro Variables
     ********************************************************************************/

    %put ;
    %put NOTE: Deleting macro variables that begin with "&MVAR".;
    %put ;

    /* Copy VMacro for specified variables */
    /* REVISION 2011-05-10 CAS: Added scope level to filter macro variables for deletion */
    /* REVISION 2012-02-27 CAS: Changed from SELECT * to SELECT DISTINCT NAME */
    proc sql;
        create table _delete_ as
        select distinct name from sashelp.vmacro
        where substr(upcase(name), 1, length("&MVAR"))=("&MVAR")
          and scope='GLOBAL'
        ;
    quit;

    /* Note: The next step needs to be separate, as the macro deletion needs to
       access SASHELP.VMACRO. If it is used in the step above, it is locked out
       from deleting records in the table. */
    data _null_;
        set _delete_;
        call execute('%symdel ' || name || ';');
    run;


    /********************************************************************************
       Create New Macro Variables
     ********************************************************************************/

    /* Output contents */
    proc contents data=&DS out=_contents_
    %if %superq(WHERE)=%str() %then %do;
        (keep=name type varnum)
    %end;
        noprint;
    run;

    /* Sort by variable number */
    proc sort data=_contents_;
    %if &SORTBY=O %then %do;
        by varnum;
    %end;
    %else %if &SORTBY=N %then %do;
        by name;
    %end;
    run;

    /* REVISION 2011-05-26 CAS: Added filter step */
    %if "&VTYPE" ne ""
     or %superq(WHERE) ne %str()
    %then %do;

        data _contents_;
            set _contents_;
            where
        %if &VTYPE=C %then %do;
            type=2
        %end;
        %else %if &VTYPE=N %then %do;
            type=1
        %end;
        %if "&VTYPE" ne "" and %superq(WHERE) ne %str()
        %then %str( and );
        %if %superq(WHERE) ne %str() %then %do;
            &WHERE
        %end;
            ;
        run;

    %end;

    /* REVISION 2012-04-17 CAS: Added additional check for issues */
    %if &SYSERR>3 %then %return;

    /* Declare global variables */
    /* REVISION 2012-03-22 CAS: Defined default for count */
    %global &MVAR.CNT;
    %let &MVAR.CNT=0;

    %if &TYPE=M %then %do;

        data _null_;
            set _contents_ end=end;
            call symputx(compress("&MVAR" || put(_n_, 8.)), name, 'G');
            if end then call symputx("&MVAR.CNT", put(_n_, 8.), 'G');
        run;

    %end;

    %else %if &TYPE=L %then %do;

        %global &MVAR;

        proc sql noprint;
            select name
            into :&MVAR separated by &SEPARATOR
            from _contents_
            ;
        quit;

        /* REVISION 2012-03-22 CAS: Added condition to count */
        %if %symexist(&MVAR) %then %let &MVAR.CNT=1;

        /* Finalize list */
              %if %index(*par*,*&SEPBY*)>0    %then %let &MVAR=%unquote((%superq(&MVAR)));
        %else %if %index(*bra*,*&SEPBY*)>0    %then %let &MVAR=%unquote([%superq(&MVAR)]);
        %else %if %index(*cur*,*&SEPBY*)>0    %then %let &MVAR=%unquote({%superq(&MVAR)});
        %else %if %index(*q*qc*,*&SEPBY*)>0   %then %let &MVAR=%unquote(%str(%')%superq(&MVAR)%str(%'));
        %else %if %index(*qq*qqc*,*&SEPBY*)>0 %then %let &MVAR=%unquote("%superq(&MVAR)");
        %else %let &MVAR=%unquote(%superq(&MVAR));

    %end;


    /********************************************************************************
       Report New Macro Variables
     ********************************************************************************/


    /* Obtain new macro variables */
    /* REVISION 2012-05-16 CAS: Added alternate sort method for list type */
    proc sql noprint;
        create table _mvars_ as
        select name, value
        from sashelp.vmacro
        where scope="GLOBAL"
          and substr(name, 1, length("&MVAR"))=upcase("&MVAR")

    %if &TYPE=M %then %do;
        /* Order the variables by the number on the variable */
        order by input(compress(name, '', 'kd'), 8.), name, value
    %end;
    %else %do;
        order by name, offset
    %end;
        ;
    quit;

    /* Write macro variables to log */
    /* REVISION 2012-03-08 CAS: Split based on type */

    %if &TYPE=M %then %do;

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

    %end;
    /* REVISION 2012-03-08 CAS: Added LIST type reporting */
    /* REVISION 2012-05-16 CAS: Made correction to reporting where some lines were omitted */
    %else %if &TYPE=L %then %do;

        data _null_;
            set _mvars_ end=end;
            by name;
            namelag=lag(name);
            count=countw(value, &SEPARATOR);
            if _n_=1 then do;
                put "NOTE: The following macro variables were created:";
                put "NOTE- The delimiters are not displayed.";
                put " ";
            end;
            if first.name then i=1;
            do i=1 to count;
                word=scan(value, i, &SEPARATOR, 'O');
                if i=1 then do;
                  if name ne namelag then do;
                    put "NOTE- Name  = " Name;
                    put "NOTE- Value = " @15 word;
                  end;
                  else put "NOTE- " @15 word;
                end;
                else put "NOTE- " @15 word;
            end;
            if last.name then put "NOTE- ";
            if end then do;
                put "NOTE: A word within a value may be split across multiple lines.";
                put "NOTE- This is due to the limit on the length of each record in SASHELP.VMACRO.";
                put "NOTE-";
            end;
        run;

    %end;

    /* Drop temporary tables */
    /* REVISION 2012-04-17 CAS: Added another temporary table to drop list */
    %local user_notes user_mprint;
    %let user_notes=%sysfunc(getoption(notes));
    %let user_mprint=%sysfunc(getoption(mprint));
    option nomprint nonotes;
    proc sql;
        drop table _delete_, _mvars_, _contents_;
    quit;
    option &USER_NOTES;
    option &USER_MPRINT;

%mend SetVars;

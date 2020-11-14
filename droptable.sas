%macro DropTable(tables) / pbuff des='Drop table(s)';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       DropTable
        Author:     Chris Swenson
        Created:    2009-10-02

        Purpose:    Drop table(s) if they exist

        Arguments:  tables - one or more tables to drop

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-08-24  CAS     Removed LIBTBL macro in favor of in-macro code.
        2011-12-28  CAS     Updated to use USER library if available.
        2019-12-14  CAS     Added LIB m. var to LOCAL to avoid conflicts.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %if "&tables"="" or "&tables"="()" %then %do;
        %put %str(E)RROR: No tables specified.;
        %return;
    %end;

    %local num ds lib;

    %let num=1;
    %let ds=%scan(&tables, &num, %str( )());
    %let lib=%scan(&ds, 1, %str(.));
    %if &lib=&ds %then %do;;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
    %end;
    %if %sysfunc(libref(&lib)) ne 0 %then %do;
        %put %str(E)RROR: The specified library does not exist.;
        %return;
    %end;

    proc sql;
    %do %while("&ds" ne "");

      %if %sysfunc(exist(&ds)) %then %do;
        drop table &ds;
      %end;
      %else %do;
        %put NOTE: Table %upcase(&ds) does not exist.;
      %end;

    %next:

      %let num=%eval(&num+1);
      %let ds=%scan(&tables, &num, %str( )());
      %let lib=%scan(&ds, 1, %str(.));
      %if &lib=&ds %then %do;;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
      %end;
      %if %sysfunc(libref(&lib)) ne 0 %then %do;
        %put %str(E)RROR: The specified library does not exist.;
        %goto next;
      %end;

    %end;
    quit;

%mend DropTable;

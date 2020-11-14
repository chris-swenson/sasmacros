%macro AddFormatLib(libs) / des="Add a library to the fmtsearch option";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       AddFormatLib
        Author:     Chris Swenson
        Created:    2010-09-29

        Purpose:    Add a library to the format search system option (fmtsearch)

        Arguments:  libs - one or more libraries to add to the format search option

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-08-19  CAS     Revised to scan through argument to match the order
                            specified by the user.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %let libs=%upcase(&libs);

    %if "&libs"="" %then %do;
        %put %str(E)RROR: No arguments specified.;
        %return;
    %end;

    %local count fmtsearch addlibs i current changed;
    %let count=%sysfunc(countw(&libs, %str( )));
    %put NOTE: &COUNT references specified.;

    %let fmtsearch=%upcase(%sysfunc(getoption(fmtsearch)));
    %if "%substr(&FMTSEARCH, 1, 1)"="("
    %then %let fmtsearch=%substr(&FMTSEARCH, 2, %length(%sysfunc(getoption(fmtsearch)))-2);

    /* REVISION 2011-08-19 CAS: Revised to go backwords through list */
    %do i=&COUNT %to 1 %by -1;

        %let current=%scan(&libs, &i, %str( ));

        %if %sysfunc(libref(&current)) ne 0 %then %do;
            %put %str(E)RROR: Specified library &current does not exist.;
            %return;
        %end;

        %let changed=%sysfunc(tranwrd(&fmtsearch, %str( ), %str(*)));

        %if %index(*&CHANGED*,*&CURRENT*)>0
        %then %put NOTE: Specified library &current is already specified on the FMTSEARCH option.;
        %else %let addlibs=&CURRENT &ADDLIBS;

    %end;

    option fmtsearch=(&fmtsearch &addlibs);

    %put NOTE: Format Search Option (fmtsearch) = %sysfunc(getoption(fmtsearch));

%mend AddFormatLib;

%macro AddSASAuto(ref) / des="Add a fileref to the SASAutos option";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       AddSASAuto
        Author:     Chris Swenson
        Created:    2010-10-18

        Purpose:    Add a fileref to the SAS autocall macro option (SASAUTOS)

        Arguments:  ref - one or more filerefs to add to the option

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

    %let ref=%upcase(&ref);

    %if "%superq(ref)"="" %then %do;
        %put %str(E)RROR: No arguments specified.;
        %return;
    %end;

    %local count sasautos addref i current changed;
    %let count=%sysfunc(countw(&ref, %str( )));
    %put NOTE: &COUNT references specified.;

    %let sasautos=%upcase(%sysfunc(getoption(sasautos)));
    %if "%substr(&SASAUTOS, 1, 1)"="("
    %then %let sasautos=%substr(&SASAUTOS, 2, %length(&SASAUTOS)-2);

    %do i=&COUNT %to 1 %by -1;

        %let current=%scan(&ref, &i, %str( ));

        %if %sysfunc(fileref(&current)) ne 0 %then %do;
            %put %str(E)RROR: Specified fileref &current does not exist.;
            %return;
        %end;

        %let changed=%sysfunc(tranwrd(&sasautos, %str( ), %str(*)));

        %if %index(*&CHANGED*,*&CURRENT*)>0
        %then %put NOTE: Specified fileref &current is already specified on the SASAUTOS option.;
        %else %let addref=&current &addref;

    %end;

    option sasautos=(&addref &sasautos);

    %put NOTE: SAS Autocall Option (SASAutos) = %sysfunc(getoption(sasautos));

%mend AddSASAuto;

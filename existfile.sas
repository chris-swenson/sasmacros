%macro ExistFile(file) / des="Check if file exists";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       ExistFile
        Author:     Chris Swenson
        Created:    2009-10-23

        Purpose:    Check if file exists

        Arguments:  file - file to check

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check argument */
    %if %superq(file)=%str() %then %do;
        %let nofile=1;
        %put %str(E)RROR: The file was not specified.;
        %goto exit; /* Restore options and exit */
    %end;

    %local user_mprint;
    %let user_mprint=%sysfunc(getoption(mprint));
    options nomprint;

    /* Check directory */
    %if %sysfunc(fileexist( %substr(%superq(FILE), 1, %eval( %length(%superq(FILE)) - %length( %scan(%superq(FILE), -1, %str(\)) ) )) ))=0
    %then %do;
        %put %str(E)RROR: The specified directory does not exist.;
        %goto exit; /* Restore options and exit */
    %end;

    /* Assume File Exists */
    %global nofile;
    %let nofile=0;

    /* Check that the specified directory exists, if not change nofile */
    %if %sysfunc(fileexist("%superq(FILE)"))=1 %then %put NOTE: The specified file exists.;
    %else %do;
        %let nofile=1;
        %put %str(E)RROR: The specified file does not exist.;
    %end;

    %exit:

    options &user_mprint;

%mend ExistFile;

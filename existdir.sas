%macro ExistDir(dir) / des="Check if directory exists";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       ExistDir
        Author:     Chris Swenson
        Created:    2009-10-23

        Purpose:    Check if directory exists

        Arguments:  dir - directory to check

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-12-02  CAS     Revised program with SUPERQ to reference the directory.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %local user_mprint;
    %let user_mprint=%sysfunc(getoption(mprint));
    options nomprint;

    /* Assume Directory Exists */
    %global nodir;
    %let nodir=0;

    /* Check for argument */
    %if %superq(DIR)=%str() %then %do;
        %let nodir=1;
        %put %str(E)RROR: Please specify a directory.;
        %goto exit; /* Restore options and exit */
    %end;

    /* Check for the backslash and add it if it is missing */
    %if %substr(%superq(DIR),%length(%superq(DIR)),1) ne \ %then %do;
        %let dir=%superq(DIR).\;
        %put NOTE: There was no backslash at the end of the directory. It was added.;
    %end;

    /* Check that the specified directory exists, if not change nodir */
    %if %sysfunc(fileexist("%superq(DIR)"))=1 %then %put NOTE: The specified directory exists.;
    %else %do;
        %let nodir=1;
        %put %str(E)RROR: The specified directory does not exist.;
    %end;

    %exit:

    options &USER_MPRINT;

%mend ExistDir;

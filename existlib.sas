%macro existlib(lib) / des="Check if libname exists";

  /********************************************************************************
    BEGIN MACRO HEADER
   ********************************************************************************

      Name:       existlib
      Author:     Chris Swenson
      Created:    2019-07-01

      Purpose:    Check if libname exists

      Arguments:  lib - libname to check

      Revisions
      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
      Date        Author  Comments
      ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

      YYYY-MM-DD  III     Please use this format and insert new entries above

   ********************************************************************************
    END MACRO HEADER
   ********************************************************************************/

  /* Set current mprint option and turn it off */
  %local user_mprint;
  %let user_mprint=%sysfunc(getoption(mprint));
  options nomprint;

  /* Assume libname does not exist */
  %global nolib;
  %let nolib=1;

  /* Check for argument */
  %if "&LIB"="" %then %do;
    %put %str(E)RROR: Please specify a libname.;
    %goto exit; /* Restore options and exit */
  %end;

  /* Check that the specified directory exists, if not change nolib */
  %if %sysfunc(libref(&LIB))=0 %then %do;
    %let nolib=0;
    %put NOTE: The specified libname exists.;
  %end;
  %else %do;
    %let nolib=1;
    %put %str(E)RROR: The specified libname does not exist.;
  %end;

  %exit:

  options &USER_MPRINT;

%mend existlib;

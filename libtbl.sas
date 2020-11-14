%macro LibTbl(ds) / des='Split library/table into macro vars';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       LibTbl
        Author:     Chris Swenson
        Created:    2009-03-31

        Purpose:    Split library/table into macro variables

        Arguments:  ds - either a library.dataset or dataset

        Output:     lib - library
                    tbl - table/data set

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-12-28  CAS     Set to default to USER library if it is available, then
                            to WORK if not.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Declare the macro variables globally */
    %global lib tbl;

    /* Clear the macro variables */
    %let lib=;
    %let tbl=;

    /* Scan ds argument for a word following a period, and set the table to that word */
    %let tbl=%scan(&DS, 2, %str(.));

    /* If the table is populated, scan the ds argument for a word preceding
       a period, and set the library to that word if available */
    %if "&TBL" ne "" %then %let lib=%scan(&DS, 1, %str(.));

    /* If the table is blank, then set the table to the original argument */
    %if "&TBL" = "" %then %let tbl=&DS;

    /* Set lib to work if blank */
    %if "&LIB" = "" %then %do;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
        %put NOTE: Library argument LIB= set to &LIB..;
    %end;

    /* Write the macros to the log */
    /* The lib macro variable will be blank for ds arguments without a library. */
    %put lib=&LIB tbl=&TBL;

%mend LibTbl;

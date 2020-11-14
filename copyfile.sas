%macro CopyFile(infile,srcdir,tgtdir) / des='Copy a file from source to target directory';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       CopyFile
        Author:     Chris Swenson
        Created:    2011-05-24
        OS:         Windows

        Purpose:    Copy a file from a source directory to a target directory

        Arguments:  infile - filename of file to copy, not including the directory
                    srcdir - source directory of file to copy
                    tgtdir - target directory of file to copy

        CAUTION:    This macro overwrites the target file if it exists. Use caution!

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check that arguments exist */
    %if %superq(INFILE)=%str() %then %do;
        %put %str(E)RROR: No argument specified for INFILE.;
        %return;
    %end;
    %if %superq(SRCDIR)=%str() %then %do;
        %put %str(E)RROR: No argument specified for source directory SRCDIR.;
        %return;
    %end;
    %if %superq(TGTDIR)=%str() %then %do;
        %put %str(E)RROR: No argument specified for target directory TGTDIR.;
        %return;
    %end;

    /* Add backslashes at end */
    %if %substr(&SRCDIR, %length(&SRCDIR), 1) ne \ %then %do;
        %let srcdir=&SRCDIR.\;
        %put NOTE: There was no backslash at the end of the source directory. It was added.;
    %end;
    %if %substr(&TGTDIR, %length(&TGTDIR), 1) ne \ %then %do;
        %let tgtdir=&TGTDIR.\;
        %put NOTE: There was no backslash at the end of the target directory. It was added.;
    %end;

    /* Check that referenced files exist */
    %if %sysfunc(fileexist(&SRCDIR)) ne 1 %then %do;
        %put %str(E)RROR: The source directory SRCDIR does not exist.;
        %return;
    %end;
    %if %sysfunc(fileexist(&SRCDIR.&INFILE)) ne 1 %then %do;
        %put %str(E)RROR: The INFILE does not exist.;
        %return;
    %end;
    %if %sysfunc(fileexist(&TGTDIR)) ne 1 %then %do;
        %put %str(E)RROR: The target directory TGTDIR does not exist.;
        %return;
    %end;

    /* Manage options */
    %let user_xwait=%sysfunc(getoption(xwait));
    %let user_xsync=%sysfunc(getoption(xsync));
    options noxwait xsync;

    /* Copy file */
    %sysexec copy "&SRCDIR.&INFILE" "&TGTDIR";

    /* Restore options */
    options &USER_XWAIT &USER_XSYNC;

    %if %sysfunc(fileexist(&TGTDIR.&INFILE))=1
    %then %put NOTE: The file was successfully copied.;
    %else %do;
        %put %str(W)ARNING: The file was not copied.;
        %put %str(W)ARNING- &SRCDIR.&INFILE;
    %end;

%mend CopyFile;

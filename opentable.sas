%macro OpenTable(table,style=MessageBox,show=NAME,test=N) / des="Open table(s)";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       OpenTable
        Author:     Chris Swenson
        Created:    2010-05-07

        Purpose:    Open specified table(s)

        Arguments:  table  - one or more tables to open, defaulted to last table
                    style= - whether to use the MESSAGEBOX macro or the WINDOW
                             statement supplied by the OpenTable macro when there
                             is no argument specified, the last table exists, and
                             the user has copied a table name. See below for details.
                    show=  - either LABEL or NAME (default) to set what is displayed
                             for the column header
                    test=  - whether to test the macro

        Usage:      The OpenTable macro can be set to a keyboard shortcut:

                    gsubmit '%OpenTable;'

                    The macro will open the last table generated or the copied table.
                    If both exist, it asks the user which to open.

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-07-26  CAS     Added processing on clipboard content in order to avoid
                            issues with the macro execution and to check the validity
                            of the contents as a SAS name.
        2011-12-28  CAS     Updated to use USER or WORK depending on which is in use.
        2012-04-10  CAS     Added an additional step to detect issues with the
                            MessageBox API.
        2012-05-07  CAS     Added steps to resolve macro variables within copied text.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Settings
     ********************************************************************************/

    %put ;

    %let test=%upcase(&TEST);
    %let style=%substr(%upcase(&STYLE), 1, 1);
    %let show=%substr(%upcase(&SHOW), 1, 1);

    /* Check for argument values in (Y N) */
    %let TEST=%upcase(&TEST);
    %if %index(*Y*N*,*&TEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for TEST.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;

    /* Check for argument values in (M W) */
    %let STYLE=%upcase(&STYLE);
    %if %index(*M*W*,*&STYLE*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for STYLE.;
        %put %str(E)RROR- Please use one of the following: M or W.;
        %return;
    %end;

    /* Check for argument values in (L N) */
    %let SHOW=%upcase(&SHOW);
    %if %index(*L*N*,*&SHOW*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for SHOW.;
        %put %str(E)RROR- Please use one of the following: L or N.;
        %return;
    %end;


    /********************************************************************************
       Open a Table
     ********************************************************************************/

    /* If the table is blank, check the clipboard */
    %if "&table"="" %then %do;

        /* Temporarily turn off specific options */
        %if &TEST ne Y %then %do;

            %let user_mprint=%sysfunc(getoption(mprint));
            %let user_notes=%sysfunc(getoption(notes));
            %let user_erlvl=%sysfunc(getoption(%str(e)rrors));

            option nomprint;
            option nonotes;
            option %str(e)rrors=0;

        %end;

        /* Manage scope and set defaults */
        %local lastok lastmodt clip cber cbok asktbl wrong;
        %let last=&syslast;
        %let lastok=%eval(%sysfunc(exist(%superq(last), %str(DATA))) + %sysfunc(exist(%superq(last), %str(VIEW))));
        %let clip=;
        %let cber=0;
        %let cbok=0;


        /****************************************************************************
           Recent Table
         ****************************************************************************/

        /* If the table is blank, check the modified date of the last table */
        %if &lastok=1 %then %do;

            %let lastmodt=%tableinfo(&last, MODTE);

            /* Evaluate modified date of last table */
            %if &lastmodt ne . %then %do;
                %if %eval( %scan(%sysfunc(datetime()), 1, %str(.)) - %sysfunc(inputn(&lastmodt, datetime20.)) ) < 5
                %then %let table=&last;
            %end;

        %end;


        /****************************************************************************
           Clipboard
         ****************************************************************************/

        %if "&table"="" %then %do;

            /* Access clipboard */
            filename _cb_ clipbrd;

                /* Set clipboard value to macro variable */
                /* REVISION 2011-07-26 CAS: Added processing on clipboard content */
                /* REVISION 2012-05-07 CAS: Added ampersand to compress function */
                data _null_;
                    infile _cb_ truncover;
                    input content $50.;
                    content=compress(content, '&_.', 'kad');
                    rc=nvalid(scan(content, -1, '.'));
                    if rc=0 then do;
                        content='';
                        call symputx('clip', content);
                    end;
                    else do;
                        call symputx('clip', content);
                    end;
                run;

                /* Retain (e)rror variable */
                %let cber=&SYSERR;

            /* Clear clipboard filename */
            filename _cb_ clear;

            /* Set library */
            %local lib;
            %if %sysfunc(libref(user))=0 %then %let lib=user;
            %else %let lib=work;

            %let clip=%upcase(%superq(clip));
            %if %sysfunc(compress(%superq(clip), %str(.), %str(k))) ne %str(.) %then %let clip=&LIB..%superq(clip);

            %put NOTE: Copied value: %superq(clip);
            %put NOTE: Last modified: &SYSLAST;

            /* Evaluate the condition of the clipboard material */
            /* REVISION 2012-04-10 CAS: Added additional handling of issues */
            %if (%superq(clip) ne &SYSLAST) and &CBER<4 %then %do;

                %let cbok=%eval(%sysfunc(exist(%superq(clip), %str(DATA))) + %sysfunc(exist(%superq(clip), %str(VIEW))));

                /* If there is a conflict, ask the user */
                %if &cbok=1 and &lastok=1 %then %do;

                    %if &STYLE=M %then %do;

                        %local response;
                        %let response=%MessageBox(
                              Would you like to open the copied table? Otherwise select No to open the last table.
                            , title=OpenTable Question, buttons=YNC, default=1, icon=Q)
                        ;

                        %if "&RESPONSE"="" %then %do;
                            %goto cancel;
                        %end;
                        %else %if "&RESPONSE"="YES" %then %do;
                            %let table=%superq(clip);
                            %put NOTE: Opening table from clipboard.;
                        %end;
                        %else %if "&RESPONSE"="NO" %then %do;
                            %let table=&syslast;
                            %put NOTE: Opening last table.;
                        %end;
                        %else %if "&RESPONSE"="CANCEL" %then %goto cancel;

                    %end;
                    %else %if &STYLE=W %then %do;

                        %let asktbl=;
                        %let wrong=;
                        %loop:
                        %window asktbl
                        #2 @5 "&wrong" color=red
                        #3 @5 "OpenTable: Select a Table: " asktbl 1 color=blue attr=rev_video required=yes " (C=Copied, L=Last, X=Cancel)"
                        #5 @5 "Press ENTER to continue"
                        ;
                        %display asktbl delete;

                        %let asktbl=%upcase(&asktbl);

                        %if %index(*C*L*X*,*&ASKTBL*)=0 %then %do;
                            %let wrong=%str(I)NVALID ENTRY;
                            %goto loop;
                        %end;
                        %if &asktbl=C %then %do;
                            %let table=%superq(clip);
                            %put NOTE: Opening table from clipboard.;
                        %end;
                        %else %if &asktbl=L %then %do;
                            %let table=&syslast;
                            %put NOTE: Opening last table.;
                        %end;
                        %else %if &ASKTBL=X %then %goto cancel;

                    %end;

                %end;

                /* If not, use clipboard or syslast */
                /* REVISION 2012-05-07 CAS: Added unquote function to resolve macro variables */
                %else %if &CBOK=1 and &LASTOK=0 %then %let table=%superq(CLIP);
                %else %let table=&LAST;
                %let table=%unquote(&TABLE);

            %end;
            %else %let table=&last;

        %end;

        %cancel:

        /* Restore user options */
        %if &test ne Y %then %do;
            option %str(e)rrors=&USER_ERLVL;
            option &USER_MPRINT &USER_NOTES;
        %end;

    %end;

    /********************************************************************************/

    /* Manage macros */
    %local num tbl;

    /* Set initial scan */
    %let num=1;
    %let tbl=%scan(&TABLE, &NUM, %str( )%str(,)%str(%()%str(%)));

    /* Loop through each argument until blank */
    %do %while("&TBL" ne "");

        /* Check if table exists */
        %if %eval(%sysfunc(exist(&TBL, %str(DATA))) + %sysfunc(exist(&TBL, %str(VIEW))))=1 %then %do;

            dm "vt %sysfunc(compress(&TBL)) colheading=&SHOW" vt;

        %end;

        /* Otherwise pop-up a message that it does not exist. */
        %else %do;

            dm 'postmessage "The specified table &table does not exist."';

        %end;

        /* Increment scan */
        %let num=%eval(&NUM+1);
        %let tbl=%scan(&TABLE, &NUM, %str( )%str(,)%str(%()%str(%)));

    %end;

    %put ;

%mend OpenTable;

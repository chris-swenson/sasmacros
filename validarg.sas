%macro ValidArg(varlist,type=BLANK,list=,obj=) / des="Write code to validate macro arguments";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       ValidArg
        Author:     Chris Swenson
        Created:    2010-08-19

        Purpose:    Write code to validate macro program arguments, including the
                    following checks (see below). The code is copied to the clipboard
                    for the user to paste within the macro code. This macro should
                    not be referenced within a macro, since by itself it does not
                    complete the check, but generates code that does so.

        Arguments:  varlist - The list of macro arguments to generate checks for,
                              separated by spaces. Note that the specified validation
                              types will be generated for all specified arguments.
                    type=   - The type of check to generate, including the following:
                                - BLANK = Checks for blank arguments
                                - YN = Checks that the argument is either Y or N
                                - LIST = Checks that the argument is one of the
                                  values in the LIST argument
                                - NUM = Checks that all values are numbers
                                - CHAR = Checks that all values are character
                                - EXIST = Checks that the specified object exists
                                  and requires the OBJ= argument
                    list=   - Valid values for the LIST type check, separated by
                              spaces
                    obj=    - Type of object to check for the existence of, including:
                                - DATA = Data set in a library
                                - DIR = Directories
                                - DSVW = Data set or view in a library
                                - FILE = Files (with full path)
                                - LIB  = Library
                                - VIEW = View in a library

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2012-03-23  CAS     Added LIB value to OBJ= argument.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check for blanks */
    %if %superq(VARLIST)=%str() %then %do;
        %put %str(E)RROR: No argument specified for VARLIST.;
        %return;
    %end;
    %if %superq(TYPE)=%str() %then %do;
        %put %str(E)RROR: No argument specified for TYPE.;
        %return;
    %end;

    /* Convert synonym */
    %let type=%upcase(&TYPE);
    %if "&TYPE"="YN" %then %do;
        %let type=LIST;
        %let list=Y N;
    %end;

    /* Check for valid types */
    %if %index(*BLANK*CHAR*EXIST*LIST*NUM*,*&TYPE*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for TYPE.;
        %put %str(E)RROR- Please use BLANK, LIST, YN, NUM, or CHAR.;
        %return;
    %end;

    /* Check for lists when type is LIST */
    %if %index(*LIST*,*&TYPE*)>0 and %superq(LIST)=%str() %then %do;
        %put %str(E)RROR: No argument specified for LIST. This argument is required for the LIST type.;
        %return;
    %end;

    /* Check objects when type is EXIST */
    /* REVISION 2012-03-23 CAS: Added LIB value */
    %if %index(*EXIST*,*&TYPE*)>0 %then %do;

      %if %superq(OBJ)=%str() %then %do;
        %put %str(E)RROR: No argument specified for OBJ. This argument is required for the EXIST type.;
        %return;
      %end;

      /* Check for argument values in (DATA DIR DSVW FILE LIB VIEW) */
      %let OBJ=%upcase(&OBJ);
      %if %index(*DATA*DIR*DSVW*FILE*LIB*VIEW*,*&OBJ*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for OBJ.;
        %put %str(E)RROR- Please use one of the following: DATA, DIR (directory), DSVW (data or view), FILE, or VIEW.;
        %return;
      %end;

    %end;

    /* Set new variables */
    %local num b y l i var list_ind;
    %let num=%sysfunc(countw(&VARLIST));
    %put ;

    /* Associate with the clipboard */
    filename _cb_ clipbrd;

    /* Generate checks */
    data _null_;
        format temp temp0 temp1 temp2 temp3 $250.;
        file _cb_;

    /* Blanks */
    %if %index(*BLANK*,*&TYPE*) %then %do;

        temp='/* Check for blank arguments */';
        put temp;

      %do b=1 %to &NUM;

        %let var=%upcase(%scan(&VARLIST, &B, %str( )));

        temp0='';
        temp1='%if %superq(' || "&VAR" || ')=%str() %then %do;';
        temp2='%put %str(E)RROR: No argument specified for ' || "&VAR" || '.;';
        temp3='';

        put temp1;
        put '    ' temp2;
        put "    %return;";
        put "%end;";

      %end;
    %end;

    /* List or YN */
    %else %if %index(*LIST*YN*,*&TYPE*) %then %do;

        temp='/* Check for argument values in (' || "&LIST" || ') */';
        put temp;

      %do l=1 %to &NUM;

        %let var=%upcase(%scan(&VARLIST, &L, %str( )));
        %let list=%upcase(&LIST);

        /* Generate list for index */
        %let list_ind=%sysfunc(tranwrd(&LIST, %str( ), %str(*)));

        /* Generate list for report */
        %do r=1 %to %sysfunc(countw(&LIST));
            %if &R=1 %then
              %let list_rep=%scan(&LIST, &R, %str( ));
            %else %if %sysfunc(countw(&LIST))=2 %then
              %let list_rep=&LIST_REP or %scan(&LIST, &R, %str( ));
            %else %if &R=%sysfunc(countw(&LIST)) %then
              %let list_rep=&LIST_REP, or %scan(&LIST, &R, %str( ));
            %else
              %let list_rep=&LIST_REP, %scan(&LIST, &R, %str( ));
        %end;

        temp0='%let ' || "&VAR" || '=%upcase(&' || "&VAR" || ');';
        temp1='%if %index(*' || "&LIST_IND" || '*,*&' || "&VAR" || '*)=0 %then %do;';
        temp2='%put %str(E)RROR: %str(I)nvalid argument specified for ' || "&VAR" || '.;';
        temp3='%put %str(E)RROR- Please use one of the following: ' || "&LIST_REP" || '.;';

        put temp0;
        put temp1;
        put '    ' temp2;
        put '    ' temp3;
        put "    %return;";
        put "%end;";

      %end;
    %end;

    /* CHAR */
    %else %if &TYPE=CHAR %then %do;

        temp='/* Check for character values */';
        put temp;

      %local c;

      %do c=1 %to &NUM;

        %let var=%upcase(%scan(&VARLIST, &C, %str( )));

        temp0='';
        temp1='%if %sysfunc(compress(&' || "&VAR" || ', %str(), %str(a))) ne %str() %then %do;';
        temp2='%put %str(E)RROR: %str(I)nvalid argument specified for ' || "&VAR" || '.;';
        temp3='%put %str(E)RROR: Please use character values only.;';

        put temp1;
        put '    ' temp2;
        put '    ' temp3;
        put "    %return;";
        put "%end;";

      %end;

    %end;

    /* NUM */
    %else %if &TYPE=NUM %then %do;

        temp='/* Check for numeric values */';
        put temp;

      %local n;

      %do n=1 %to &NUM;

        %let var=%upcase(%scan(&VARLIST, &N, %str( )));

        temp0='';
        temp1='%if %sysfunc(compress(&' || "&VAR" || ', %str(), %str(d))) ne %str() %then %do;';
        temp2='%put %str(E)RROR: %str(I)nvalid argument specified for ' || "&VAR" || '.;';
        temp3='%put %str(E)RROR: Please use numeric values only.;';

        put temp1;
        put '    ' temp2;
        put '    ' temp3;
        put "    %return;";
        put "%end;";

      %end;

    %end;

    /* EXIST */
    /* REVISION 2012-03-23 CAS: Added LIB check */
    %else %if &TYPE=EXIST %then %do;

        temp='/* Check for existence of the object */';
        put temp;

      %local n;

      %do e=1 %to &NUM;

        %let var=%upcase(%scan(&VARLIST, &E, %str( )));

        temp0='';
      %if &OBJ=DATA %then %do;
        temp1='%if %sysfunc(exist(%superq(' || "&VAR" || '), %str(DATA)))=0 %then %do;';
        temp2='%put %str(E)RROR: The specified data set %superq(' || "&VAR" || ') does not exist.;';
      %end;
      %else %if &OBJ=DIR %then %do;
        temp1='%if %sysfunc(fileexist(%superq(' || "&VAR" || ')))=0 %then %do;';
        temp2='%put %str(E)RROR: The specified directory does not exist.;';
      %end;
      %else %if &OBJ=DSVW %then %do;
        temp1='%if %eval( %sysfunc(exist(%superq(' || "&VAR" || '), %str(DATA))) + %sysfunc(exist(&' || "&VAR" || ', %str(VIEW))) )=0 %then %do;';
        temp2='%put %str(E)RROR: The specified data set or view %superq(' || "&VAR" || ') does not exist.;';
      %end;
      %else %if &OBJ=FILE %then %do;
        temp1='%if %sysfunc(fileexist(%superq(' || "&VAR" || ')))=0 %then %do;';
        temp2='%put %str(E)RROR: The specified file does not exist.;';
      %end;
      %else %if &OBJ=VIEW %then %do;
        temp1='%if %sysfunc(exist(%superq(' || "&VAR" || '), %str(VIEW)))=0 %then %do;';
        temp2='%put %str(E)RROR: The specified view %superq(' || "&VAR" || ') does not exist.;';
      %end;
      %else %if &OBJ=LIB %then %do;
        temp1='%if %sysfunc(libref(%superq(' || "&VAR" || '))) ne 0 %then %do;';
        temp2='%put %str(E)RROR: The specified library %superq(' || "&VAR" || ') does not exist.;';
      %end;
        temp3='';

        put temp1;
        put '    ' temp2;
        put "    %return;";
        put "%end;";

      %end;

    %end;

    run;

    /* Clear clipboard association */
    filename _cb_ clear;

    %put ;
    %put NOTE: The generated code has been copied to the clipboard.;
    %put NOTE- Paste the code in the appropriate area.;

%mend ValidArg;

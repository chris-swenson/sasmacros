%macro CompCon(base,compare,id=VARNUM,out=Contents_differ,lib=,exclude=INFORMAT INFORML,expect=N,max=32767,print=N,test=N)
    / des='Compare contents of data sets';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       CompCon
        Author:     Chris Swenson
        Created:    2009-03-31

        Purpose:    Compare the contents (CompCon) of two data sets that should be
                    the same format.

        Arguments:  base     - base data set
                    compare  - comparison data set
                    id=      - ID to compare the contents with, either NAME or
                               VARNUM, defaulted to VARNUM
                    out=     - output data set name, defaulted to Contents_differ
                    lib=     - output library
                    exclude= - variables to exclude from the analysis, defaulted to
                               INFORMAT INFORML, which usually differ greatly
                    expect=  - Y/N whether differences are expected, which changes
                               the output from an issue to a NOTE
                    max=     - maximum number of records to compare, defaulted to
                               maximum of 32,767
                    print=   - Y/N flag to indicate whether to print the comparison,
                               defaulted to N
                    test=    - Y/N flag to indicate whether to test the macro

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-12-20  CAS     Modified how the LIB library is defaulted, based on the
                            availability of the USER option.
        2012-02-01  CAS     Added additional output.
        2012-02-14  CAS     Revised the output messages.
        2012-03-30  CAS     Added drop for pre-existing output tables.
        2012-03-30  CAS     Added TEST= argument to not drop tables.
        2016-04-20  CAS     Added check on PRINT= argument, as well as tweaked
                            what is printed.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/


    /********************************************************************************
       Settings
     ********************************************************************************/

    /* Testing variables:
        %let base=;
        %let compare=;
        %let max=32767;
    */

    /* Default the lib argument based on whether the USER option is in effect. */
    %if "&LIB"="" %then %do;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
        %put NOTE: Library argument LIB= set to &LIB..;
    %end;

    %let id=%upcase(&ID);

    /* Check arguments */
    %if &BASE= or &COMPARE= %then %do;
        %put %str(E)RROR: The macro call is missing arguments: Base=&BASE | Compare=&COMPARE;
        %return;
    %end;
    %if %eval(%sysfunc(exist(&BASE, %str(DATA))) + %sysfunc(exist(&BASE, %str(VIEW))))=0 %then %do;
        %put %str(E)RROR: The base data set does not exist.;
        %return;
    %end;
    %if %eval(%sysfunc(exist(&COMPARE, %str(DATA))) + %sysfunc(exist(&COMPARE, %str(VIEW))))=0 %then %do;
        %put %str(E)RROR: The compare data set does not exist.;
        %return;
    %end;
    %if %superq(ID)=%str() %then %do;
        %put %str(E)RROR: No ID argument specified.;
        %return;
    %end;
    %else %if %index(*NAME*VARNUM*,*&ID*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid ID argument specified. Please use NAME or VARNUM.;
        %return;
    %end;
    %if %superq(LIB)=%str() %then %do;
        %put %str(E)RROR: No argument specified for LIB.;
        %return;
    %end;
    %let expect=%substr(%upcase(&EXPECT), 1, 1);
    %if %index(*N*Y*,*&EXPECT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid EXPECT argument specified. Please use Y or N.;
        %return;
    %end;
    %let test=%substr(%upcase(&TEST), 1, 1);
    %if %index(*Y*N*,*&TEST*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for TEST.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;
    /* REVISION 2016-4-20 CAS: Added check for PRINT variable */
    %let print=%substr(%upcase(&PRINT), 1, 1);
    %if %index(*Y*N*,*&PRINT*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for PRINT.;
        %put %str(E)RROR- Please use one of the following: Y or N.;
        %return;
    %end;

    /* Modify the exclusion argument */
    %local excludelist;
    %let excludelist=;
    %if "&EXCLUDE" ne "" %then %do;
        %let exclude=%upcase(&EXCLUDE);
        %let exclude=%sysfunc(compbl(&EXCLUDE));
        %let exclude=%sysfunc(tranwrd(&EXCLUDE, %str( ), %str(*)));
        %let excludelist=, %sysfunc(tranwrd(&EXCLUDE, %str(*), %str(, )));
    %end;

    /* Message type */
    /* REVISION 2011-02-25 CAS: Added step for EXPECT processing */
    %local msgtyp;
    %if &EXPECT=N %then %let msgtyp=%str(W)ARNING;
    %else %if &EXPECT=Y %then %let msgtyp=NOTE;

    %put NOTE: Data sets to compare on contents: Base=&BASE | Compare=&COMPARE;

    /* Attempt to drop output tables if they already exist */
    /* REVISION 2012-02-07 CAS: Added section to drop existing output data sets */
    proc sql;
    %if %sysfunc(exist(&LIB..&OUT))=1 %then %do;
        drop table &LIB..&OUT;
    %end;
    %if %sysfunc(exist(&LIB..contents_base))=1 %then %do;
        drop table &LIB..contents_base;
    %end;
    %if %sysfunc(exist(&LIB..contents_compare))=1 %then %do;
        drop table &LIB..contents_compare;
    %end;
    %if %sysfunc(exist(&LIB..contents_in_both))=1 %then %do;
        drop table &LIB..contents_in_both;
    %end;
    %if %sysfunc(exist(&LIB..contents_in_1))=1 %then %do;
        drop table &LIB..contents_in_1;
    %end;
    %if %sysfunc(exist(&LIB..contents_in_2))=1 %then %do;
        drop table &LIB..contents_in_2;
    %end;
    quit;

    %if %sysfunc(exist(&LIB..&OUT))=1
     or %sysfunc(exist(&LIB..&OUT._in_1))=1
     or %sysfunc(exist(&LIB..&OUT._in_2))=1
     or %sysfunc(exist(&LIB..&OUT._differ))=1
     or %sysfunc(exist(&LIB..&OUT))=1
    %then %do;
        %put %str(E)RROR: Unable to drop output tables that already exist.;
        %put %str(E)RROR- Please check to see if they are open and re-run the macro.;
        %return;
    %end;


    /********************************************************************************
       Comparison
     ********************************************************************************/

    /* Data set 1 Contents */
    proc contents data=&BASE out=&LIB..contents_base noprint;
    run;

    data &LIB..contents_base(label="Contents of &BASE");
        set &LIB..contents_base;
        name=upcase(name);
    run;

    proc sort data=&LIB..contents_base;
        by &ID;
    run;

    /* Data set 2 Contents */
    proc contents data=&COMPARE out=&LIB..contents_compare noprint;
    run;

    data &LIB..contents_compare(label="Contents of &COMPARE");
        set &LIB..contents_compare;
        name=upcase(name);
    run;

    proc sort data=&LIB..contents_compare;
        by &ID;
    run;

    /* Comparison of the contents of the base and compare data sets. */
    proc compare
            base=&LIB..contents_base compare=&LIB..contents_compare
            out=&LIB..&OUT(label="Comparison of variables in &BASE and &COMPARE") outbase outcomp outnoequal
    %if &PRINT = N %then %do;
            noprint
    %end;
            maxprint=&MAX;

        /*  These variables will not be compared:
            COMPRESS - Compression will not differ
            CRDATE - Creation date of contents will differ
            ENGINE - Engine may differ
            LIBNAME - Library could differ
            MEMNAME - Memname will differ
            MODATE - Modified date of contents will differ
            NOBS - NOBS may differ and should be checked separately
            NPOS - Position in buffer should not matter
         */

        id &ID;
        var
    %if %index(*&EXCLUDE*,*CHARSET*)=0 %then %do;
            CHARSET
    %end;
    %if %index(*&EXCLUDE*,*COLLATE*)=0 %then %do;
            COLLATE
    %end;
    %if %index(*&EXCLUDE*,*DELOBS*)=0 %then %do;
            DELOBS
    %end;
    %if %index(*&EXCLUDE*,*ENCRYPT*)=0 %then %do;
            ENCRYPT
    %end;
    %if %index(*&EXCLUDE*,*FLAGS*)=0 %then %do;
            FLAGS
    %end;
    %if %index(*&EXCLUDE*,*FORMAT*)=0 %then %do;
            FORMAT
    %end;
    %if %index(*&EXCLUDE*,*FORMATD*)=0 %then %do;
            FORMATD
    %end;
    %if %index(*&EXCLUDE*,*FORMATL*)=0 %then %do;
            FORMATL
    %end;
    %if %index(*&EXCLUDE*,*GENMAX*)=0 %then %do;
            GENMAX
    %end;
    %if %index(*&EXCLUDE*,*GENNEXT*)=0 %then %do;
            GENNEXT
    %end;
    %if %index(*&EXCLUDE*,*GENNUM*)=0 %then %do;
            GENNUM
    %end;
    %if %index(*&EXCLUDE*,*IDXCOUNT*)=0 %then %do;
            IDXCOUNT
    %end;
    %if %index(*&EXCLUDE*,*IDXUSAGE*)=0 %then %do;
            IDXUSAGE
    %end;
    %if %index(*&EXCLUDE*,*INFORMAT*)=0 %then %do;
            INFORMAT
    %end;
    %if %index(*&EXCLUDE*,*INFORMD*)=0 %then %do;
            INFORMD
    %end;
    %if %index(*&EXCLUDE*,*INFORML*)=0 %then %do;
            INFORML
    %end;
    %if %index(*&EXCLUDE*,*JUST*)=0 %then %do;
            JUST
    %end;
    %if %index(*&EXCLUDE*,*LABEL*)=0 %then %do;
            LABEL
    %end;
    %if %index(*&EXCLUDE*,*LENGTH*)=0 %then %do;
            LENGTH
    %end;
    %if %index(*&EXCLUDE*,*MEMLABEL*)=0 %then %do;
            MEMLABEL
    %end;
    %if %index(*&EXCLUDE*,*MEMTYPE*)=0 %then %do;
            MEMTYPE
    %end;
    %if %index(*&EXCLUDE*,*NAME*)=0 %then %do;
            NAME
    %end;
    %if %index(*&EXCLUDE*,*NODUPKEY*)=0 %then %do;
            NODUPKEY
    %end;
    %if %index(*&EXCLUDE*,*NODUPREC*)=0 %then %do;
            NODUPREC
    %end;
    %if %index(*&EXCLUDE*,*POINTOBS*)=0 %then %do;
            POINTOBS
    %end;
    %if %index(*&EXCLUDE*,*PROTECT*)=0 %then %do;
            PROTECT
    %end;
    %if %index(*&EXCLUDE*,*REUSE*)=0 %then %do;
            REUSE
    %end;
    %if %index(*&EXCLUDE*,*SORTED*)=0 %then %do;
            SORTED
    %end;
    %if %index(*&EXCLUDE*,*SORTEDBY*)=0 %then %do;
            SORTEDBY
    %end;
    %if %index(*&EXCLUDE*,*TYPE*)=0 %then %do;
            TYPE
    %end;
    %if %index(*&EXCLUDE*,*TYPEMEM*)=0 %then %do;
            TYPEMEM
    %end;
        ;
    run;


    /********************************************************************************
       Additional Output
     ********************************************************************************/

    /* If there are observations in the table with differences, output message */
    %if %nobs(&LIB..&OUT)>0 %then %do;

        /* Split those in both */
        proc sql;
            create table in_both as
            select a.name
            from &LIB..&OUT a
            full outer join &LIB..&OUT b
            on a.name=b.name
            where a._type_='BASE' and b._type_='COMPARE'
            ;

            create table &LIB..contents_in_both(label="Variables in both &BASE and &COMPARE that differ") as
            select a.*
            from &LIB..&OUT a
            inner join in_both b
            on a.name=b.name
            ;

            drop table in_both;
        quit;

      %if %nobs(&LIB..contents_in_both)=0 %then %do;
        proc sql;
            drop table &LIB..contents_in_both;
        quit;
      %end;

      /* Split those only in 1 or 2 */
      %local a1 b1 a2 b2 i;
      %let a1=BASE; %let b1=COMPARE;
      %let a2=COMPARE; %let b2=BASE;
      %do i=1 %to 2;

        proc sql;
            create table in_&I as
            select a.name
            from &LIB..&OUT a
            where a._type_="&&A&I"
              and a.name not in
                (select b.name from &LIB..&OUT b where b._type_="&&B&I")
            ;

            create table &LIB..contents_in_&I
          %if &I=1 %then %do;
                (label="Variables only in &BASE")
          %end;
          %if &I=2 %then %do;
                (label="Variables only in &COMPARE")
          %end;
            as
            select a.*
            from &LIB..&OUT a
            inner join in_&I b
            on a.name=b.name
            ;

            drop table in_&I;
        quit;

        %if %nobs(&LIB..contents_in_&I)=0 %then %do;
          proc sql;
              drop table &LIB..contents_in_&I;
          quit;
        %end;

      %end;

        /* Note: The following list includes a macro variable reference appended at
           the end without an extra space. This is okay, since the EXCLUDELIST macro
           variable contains the extra comma to extend the list. */
        /* REVISION 2012-02-14 CAS: Revised output messages */
        %put NOTE: The following variables were NOT compared: COMPRESS, CRDATE, %sysfunc(compbl(
             ENGINE)), LABEL, LIBNAME, MEMNAME, MODATE, NOBS, NPOS&EXCLUDELIST%str(.);
        %put ;

        %local type;
        %if &EXPECT=N %then %let type=%str(W)ARNING;
        %else %let type=NOTE;

        %if %sysfunc(exist(&LIB..&OUT)) %then %let syslast=&LIB..&OUT;

        %put &TYPE.: The contents of data sets &BASE and &COMPARE differ!;
        %put &TYPE- Please see data set &OUT.!;

      /* REVISION 2016-4-20 CAS: Revised printing to only output variable name */
      %if %sysfunc(exist(&LIB..contents_in_1)) %then %do;
        %if &PRINT = Y %then %do;
          title "Variables in Base Data Set Only";
          /*proc print data = &LIB..contents_in_1; run;*/
          proc sql;
            select name from &LIB..contents_in_1;
          quit;
          title;
        %end;
        %put &TYPE.: Data set &BASE includes additional variables!;
        %put &TYPE- See &LIB..Contents_in_1.;
      %end;
      %else %put NOTE: Data set &BASE does not include additional variables.;

      %if %sysfunc(exist(&LIB..contents_in_2)) %then %do;
        %if &PRINT = Y %then %do;
          title "Variables in Comparison Data Set Only";
          /*proc print data = &LIB..contents_in_2; run;*/
          proc sql;
            select name from &LIB..contents_in_2;
          quit;
          title;
        %end;
        %put &TYPE.: Data set &COMPARE includes additional variables!;
        %put &TYPE- See &LIB..Contents_in_2.;
      %end;
      %else %put NOTE: Data set &COMPARE does not include additional variables.;

      %if %sysfunc(exist(&LIB..contents_in_both)) %then %do;
        %if &PRINT = Y %then %do;
          title "Variables in Common that Differ";
          /*proc print data = &LIB..contents_in_both; run;*/
          proc sql;
            select name from &LIB..contents_in_both;
          quit;
          title;
        %end;
        %put &TYPE.: Variables in common differ!;
        %put &TYPE- See &LIB..Contents_in_both for details.;
      %end;
      %else %put NOTE: Variables in common do not differ.;

    %end;

    /* Otherwise, output a note and drop the tables made by the macro */
    /* REVISION 2012-03-30 CAS: Added TEST argument */
    %else %do;

        %if &TEST=N %then %do;
            proc sql;
                drop table &LIB..&OUT, &LIB..contents_base, &LIB..contents_compare
                ;
            quit;
        %end;

        /* Note: The following list includes a macro variable reference appended at
           the end without an extra space. This is okay, since the EXCLUDELIST macro
           variable contains the extra comma to extend the list. */
        %put NOTE: The following variables were NOT compared: COMPRESS, CRDATE, %sysfunc(compbl(
             ENGINE)), LABEL, LIBNAME, MEMNAME, MODATE, NOBS, NPOS&EXCLUDELIST%str(.);
        %put ;

        %put NOTE: The data sets &BASE and &COMPARE have the same structure.;

    %end;

%mend CompCon;
%macro LibCount(lib,type=SAS,order=TABLE_NAME,out=LIBCOUNT,log=N,where=) / des='Count obs in library';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       LibCount
        Author:     Chris Swenson
        Created:    2009-04-30

        Purpose:    Count obs in library

        Arguments:  lib    - library to count records
                    type=  - library type (SAS, Oracle, Other)
                    order= - sort order variables for Oracle
                    out=   - name of the output data set, defaulted to Libcount
                    log=   - Y/N to output listing to log
                    where= - filter for which data sets to count in the library

        To Do:      Figure out this process for Oracle and Netezza, then check
                    whether the library is one of these and vary the process based on
                    the system.

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-06-20  CAS     Removed automatic type
        2011-07-26  CAS     Added "other" as a valid type to capture those not 
                            available through more automatic processes.
        2011-12-28  CAS     Set to use USER library if available for blank library.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Manage arguments */
    %if "&LIB"="" %then %do;
        %if %sysfunc(libref(user))=0 %then %let lib=user;
        %else %let lib=work;
        %put NOTE: Library argument LIB= set to &LIB..;
    %end;
    %let lib=%upcase(&lib);

    %if %superq(LOG)=%str() %then %do;
        %put %str(E)RROR: No argument specified for LOG.;
        %return;
    %end;
    %let LOG=%substr(%upcase(&LOG, 1, 1));
    %if %index(*N*Y*,*&LOG*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for LOG. Please use Y or N.;
        %return;
    %end;

    %let &LOG=%substr(%upcase(&LOG), 1, 1);
    %if %index(*N*Y*,*&LOG*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid LOG argument. Please use Y or N.;
        %return;
    %end;

    /* Check for argument values in (SAS ORACLE) */
    %let TYPE=%upcase(&TYPE);
    %if %index(*SAS*ORACLE*OTHER*,*&TYPE*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid argument specified for TYPE.;
        %put %str(E)RROR- Please use one of the following: SAS, ORACLE, or OTHER.;
        %return;
    %end;

    %if &TYPE=SAS %then %do;

        /* Obtain table listing */
        proc sql;
            create table &OUT as
            select memname, nobs
            from sashelp.vtable
            where upcase(libname)="&LIB"
              and upcase(memtype)="DATA"
        %if %superq(WHERE) ne %str() %then %do;
              and &WHERE
        %end;
            order by memname
            ;
        quit;

    %end;

    %else %if &TYPE=ORACLE %then %do;

        /* Obtain table listing */
        proc sql;
            %connect(orahelp);

            create table &OUT as
            select *
            from connection to oracle (
                select table_name as Memname, Num_Rows as NObs
                from sys.all_tables
                where upper(OWNER)=%str(%')&LIB%str(%')
                  and substr(table_name, 1, 3) not in ('SYS')
            %if %superq(WHERE) ne %str() %then %do;
                  and &WHERE
            %end;
            %if %superq(ORDER) ne %str() %then %do;
                order by %sysfunc(tranwrd(&ORDER, %str( ), %str(, )))
            %end;
            );

            disconnect from oracle;
        quit;

    %end;

    /* REVISION 2011-07-26 CAS: Added "other" for those not captured by the more 
       automatic processes above. */
    %else %if &TYPE=OTHER %then %do;

        %if %sysfunc(exist(&OUT)) %then %do;
            proc sql;
                drop table &OUT;
            quit;
        %end;

        %TableVars(&LIB, tbl);

        %local i cur;
        %do i=1 %to &TBLCNT;

            %let cur=&&TBL&I;

            proc sql;
                create table _temp_ as
                select 
                      "&CUR" as Memname length=100 format=$100.
                    , sum(1) as NObs format=16.
                from &LIB..&CUR
                ;
            quit;

            proc append base=&OUT data=_temp_;
            run;

            proc sql;
                drop table _temp_;
            quit;

        %end;

    %end;

    data &OUT;
        set &out end=end;
        format Total 16.;
        retain Total 0;
        Total=sum(Total, nobs, 0);
    %if &LOG=Y %then %do;
        if _n_=1 then do;
            put "NOTE: Data Set Observations";
            put "NOTE- ";
            put "NOTE- Library" @16 "Data Set" @49 "Observations";
        end;
        put "NOTE- &lib" @16 memname @49 nobs;
        if end then do;
            put "NOTE- ";
            put "NOTE- " @16 "Total" @49 Total;
            put "NOTE- ";
        end;
    %end;
    run;

%mend LibCount;

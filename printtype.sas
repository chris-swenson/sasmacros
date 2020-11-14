%macro PrintType(type,lib=,where=) / des="Print objects from SASHELP.VCATALG";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       PrintType
        Author:     Chris Swenson
        Created:    2010-04-02

        Purpose:    Print objects from SASHELP.VCATALG, e.g., FORMAT

        Arguments:  type   - type of object to output
                    lib=   - library to filter on
                    where= - additional filter criteria

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2012-03-21  CAS     Corrected SQL and added WHERE= and LIB= arguments.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %if "&type"="" %then %do;
        %put %str(E)RROR: No type specified.;
        %return;
    %end;

    %let type=%upcase(&type);

    proc sql;
        create table _vcatalg_ as
        select * from sashelp.vcatalg
        where substr(objtype, 1, length("&TYPE"))="%upcase(&TYPE)"
    %if %superq(WHERE) ne %str() %then %do;
          and &WHERE
    %end;
    %if %superq(LIB) ne %str() %then %do;
          and libname="%upcase(&LIB)"
    %end;
        ;
    quit;

    data _null_;
        set _vcatalg_ end=end;
        if _n_=1 then do;
        put @5 "AVAILABLE &type.S";
        put "NOTE-";
        put @5 "Name" @30 "Description";
        put @5 "----" @30 "-----------";
        end;
        put @5 Objname @30 Objdesc;
        if end then do;
            put "NOTE-";
            if "&type"="MACRO" then do;
                put @5 "Note: This list only includes autocall macros that have already been used.";
                put "NOTE-";
            end;
        end;
    run;

    proc sql;
        drop table _vcatalg_;
    quit;

%mend PrintType;

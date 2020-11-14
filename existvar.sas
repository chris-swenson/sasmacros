%macro ExistVar(ds,var,nowarn) / des="Check if variable exists";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       ExistVar
        Author:     Chris Swenson
        Created:    2011-04-18

        Purpose:    Check if a variable exists in a data set

        Arguments:  ds     - data set
                    var    - variable to check
                    nowarn - set to "nowarn" if you want to avoid an issue in the log

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2011-05-24  CAS     Changed handling of missing variable and added an option
                            to suppress issue message.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %if "&NOWARN" ne "" %then %let nowarn=%upcase(&NOWARN);

    %if "&ds"="" %then %do;
        %put %str(E)RROR: No dataset specified.;
        %return;
    %end;
    %if %sysfunc(exist(&DS))=0 %then %do;
        %put %str(E)RROR: The specified data set does not exist.;
        %return;
    %end;
    %if "&var"="" %then %do;
        %put %str(E)RROR: No variable specified.;
        %return;
    %end;

    %let var=%upcase(&var);

    %local dsid rc cnt exist;
    %let exist=0;

    /* Open dataset */
    %let dsid=%sysfunc(open(&DS));

        /* Obtain count of variables */
        %let cnt=%sysfunc(attrn(&DSID, nvars));

        /* For each variable, compare to input */
        %do i=1 %to &CNT;
            %if %upcase(%sysfunc(varname(&DSID, &I)))=&VAR
            %then %do;
                %let exist=1;
                %goto exit;
            %end;
        %end;

        %exit:

    /* Close the dataset */
    %let rc=%sysfunc(close(&DSID));

    /* Check the status and output a message */
    %global novar;
    %if &EXIST=1 %then %do;
        %let novar=0;
        %put NOTE: Variable &VAR found on &DS..;
    %end;
    %else %do;
        %let novar=1;
      %if "&NOWARN"="NOWARN" %then %do;
        %put NOTE: Variable &VAR not found on &DS.!;
      %end;
      %else %do;
        %put %str(W)ARNING: Variable &VAR not found on &DS.!;
      %end;
    %end;

%mend ExistVar;

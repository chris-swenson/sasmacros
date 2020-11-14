%macro Convert(source,type,format,help=N) / des="Convert CHAR/NUM/DATE(TIME) variables";

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       Convert
        Author:     Chris Swenson
        Created:    2010-08-19

        Purpose:    A function for converting data from numeric to character, 
                    character to numeric, date/datetime to character, date to
                    datetime, or datetime to date.

        Arguments:  source - source variable (required)
                    type   - type of source variable (required):
                             C  - Character
                             N  - Numeric
                             D  - Date
                             DT - Datetime
                    format - Format of source variable for character/numeric
                             conversion (required for types C and N)
                    help   - Access help documentation

        Note:       To convert date/datetime variables to character, use the N type
                    to treat the variable as only a number. Specify the informat in
                    the format argument.

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %let help=%upcase(&help);
    %if &help ne N %then %do;

        %put NOTE: Help for CONVERT Macro Program;
        %put ;
        %put NOTE- Arguments:;
        %put NOTE- source - source variable (required);
        %put NOTE- type   - type of source variable (required):;
        %put NOTE- %str(         )C  - Character;
        %put NOTE- %str(         )N  - Numeric;
        %put NOTE- %str(         )D  - Date;
        %put NOTE- %str(         )DT - Datetime;
        %put NOTE- format - Format of source variable for character/numeric;
        %put NOTE- conversion (required for types C and N);
        %put NOTE- help   - Access help documentation;
        %put ;
        %put NOTE- Examples:;
        %put NOTE- Character to numeric: %str(    )target=%nrstr(%convert)(source, C, $10.)%str(;);
        %put NOTE- Numeric to character: %str(    )target=%nrstr(%convert)(source, N, 10.)%str(;);
        %put NOTE- Date to character: %str(       )target=%nrstr(%convert)(date, n, mmddyy10.)%str(;);
        %put NOTE- Datetime to character: %str(   )target=%nrstr(%convert)(datetime, n, datetime20.)%str(;);
        %put NOTE- Date to datetime: %str(        )target=%nrstr(%convert)(date, d)%str(;);
        %put NOTE- Datetime to date: %str(        )target=%nrstr(%convert)(datetime, dt)%str(;);

        %return;

    %end;

    /* Set argument to upper case */
    %let type=%upcase(&type);

    /* Check arguments */
    %if "&source"="" %then %do;
        %put %str(E)RROR: No argument specified for SOURCE.;
        %return;
    %end;
    %if "&type"="" %then %do;
        %put %str(E)RROR: No argument specified for TYPE.;
        %return;
    %end;
    %if %index(*N*C*D*DT*,*&TYPE*)=0 %then %do;
        %put %str(E)RROR: No valid argument speicifed for TYPE. Please use N (Numeric), C (Character), D (Date), or DT (Datetime).;
        %return;
    %end;

    %if %index(*N*C*,*&TYPE*)>0 %then %do;
        %if "&format"="" %then %do;
            %put %str(E)RROR: No argument specified for FORMAT.;
            %return;
        %end;
        %if %substr(&format, %length(&format), 1) ne . %then %do;
            %put %str(E)RROR: No valid argument specified for FORMAT. Please include the period at the end of the format.;
            %return;
        %end;
    %end;

    /* Populate function based on type of data */
    %if &type=C %then %do;
        input(&source, &format.)
    %end;
    %else %if &type=N %then %do;
        compress(put(&source, &format.))
    %end;
    %if &type=D %then %do;
        dhms(&source, 0, 0, 0)
    %end;
    %else %if &type=DT %then %do;
        datepart(&source)
    %end;

%mend Convert;

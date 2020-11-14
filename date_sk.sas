%macro date_sk(input, type);

  /****************************************************************************
    BEGIN MACRO HEADER
   ****************************************************************************

      Name:       date_sk
      Author:     Chris Swenson
      Created:    2018-03-30

      Purpose:    Generate date secondary keys. In other words, convert dates
                  into numeric values that look like formatted dates, in either
                  YYYYMM or YYYYMMDD style.

      Arguments:  input - input date
                  type - format type, either YYMM or YYMMDD

      Revisions
      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
      Date        Author  Comments
      ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

      YYYY-MM-DD  III     Please use this format and insert new entries above

   ****************************************************************************
    END MACRO HEADER
   ****************************************************************************/

  %if "&INPUT" = "" %then %do;
    %put %str(E)RROR: Please specify the input date (1st argument).;
    %return;
  %end;
  %if "&TYPE" = "" %then %do;
    %put %str(E)RROR: Please specify the SK type (2nd argument): YYMM (YYYYMM) or YYMMDD (YYYYMMDD);
    %return;
  %end;
  %else %let type = %upcase(&TYPE);
  %if %index(*YYMM*YYMMDD*,*&TYPE*) = 0 %then %do;
    %put %str(E)RROR: Please specify the SK type: YYMM (YYYYMM) or YYMMDD (YYYYMMDD);
    %return;
  %end;

  %if &TYPE = YYMM %then %do;
    year(&INPUT) * 100 + month(&INPUT)
  %end;
  %else %if &TYPE = YYMMDD %then %do;
    year(&INPUT) * 10000 + month(&INPUT) * 100 + day(&INPUT);
  %end;

%mend date_sk;

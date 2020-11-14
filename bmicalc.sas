%macro BmiCalc(oz,in) / des='Calculate BMI';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       BmiCalc
        Author:     Chris Swenson
        Created:    2012-01-03

        Purpose:    Calculate BMI based on weight in ounces and height in inches.

        Arguments:  oz - weight (in ounces) variable
                    in - height (in inches) variable

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    703*(&OZ/16)/(&IN**2)

%mend BmiCalc;

/*
data test;
    format oz in 4.;
    oz=185*16;
    in=12*5+10;
    bmi=%BmiCalc(oz, in);
run;
*/

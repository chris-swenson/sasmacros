%macro TeaTimer(minutes,style=MessageBox,sound=N) / des='Time tea brewing by putting SAS to sleep';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       TeaTimer
        Author:     Chris Swenson
        Created:    2010-04-01

        Purpose:    Time tea brewing by putting SAS to sleep. Useful when the user
                    cannot install software.

        Arguments:  minutes - 1-10 minutes for brewing tea
                    style=  - either MessageBox (M) to use the MessageBox API or 
                              Window (W) to use a %WINDOW statement
                    sound=  - flag to indicate whether to output sound with
                              notification

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    %let style=%substr(%upcase(&STYLE), 1, 1);
    %let sound=%substr(%upcase(&SOUND), 1, 1);

    %if "&style"="" %then %do;
        %put %str(E)RROR: No STYLE argument specified. Please use MessageBox (M) or Window (W).;
        %return;
    %end;
    %if %index(*M*W*,*&STYLE*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid STYLE argument specified. Please use MessageBox (M) or Window (W).;
        %return;
    %end;
    %if %index(*N*Y*,*&SOUND*)=0 %then %do;
        %put %str(E)RROR: %str(I)nvalid SOUND argument specified. Please use Y or N.;
        %return;
    %end;

    %if %index(*1*2*3*4*5*6*7*8*9*10*,*&minutes*)=0 %then %put %str(E)RROR: %str(I)nvalid minutes value. Please use 1-5.;
    %else %do;

        %if &STYLE=W %then %do;

            /* The following code will work without the MessageBoxA Windows API */
            %local rusure;
            %let rusure=;
            %window rusure
                //  @20 "The tea timer is set for &minutes minute(s)."
                //  @20 "This will put SAS to sleep. Do you wish to continue?"
                //  @20 rusure 1 attr=rev_video required=yes
                //  @20 "Enter Y for Yes or N for No, then hit ENTER to continue.";
            %display rusure delete;

        %end;

        %else %if &STYLE=M %then %do;

            %MessageBox(
                  "The tea timer is set for &MINUTES minute(s)"
                  || break ||
                  "This will put SAS to sleep. Do you wish to continue?"
                , title=TeaTimer: Are you sure?
                , buttons=YN
                , default=2
                , type=DATA
                , icon=E
            );

            %local rusure;
            %let rusure=%substr(&RESPONSE, 1, 1);
            %symdel response;

        %end;

        %if &rusure=6 %then %let rusure=Y;
        %else %if &rusure=7 %then %let rusure=N;

        %if %upcase(&rusure)=Y %then %do;

            data _null_;
                format time time8.;
                time=time()+%eval(&minutes*60);
                sleep=wakeup(time);
            run;

            dm "postmessage 'The tea is done!'";

            %if &SOUND=Y %then %do;
                data _null_;
                    call sound(98*(2**2), .5*160*1);
                    call sound(65*(2**3), 1*160*1);
                run;
            %end;

        %end;

    %end;

%mend TeaTimer;

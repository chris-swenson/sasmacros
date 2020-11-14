%macro Micro / des="The solution to micro-management";

    %local user_mprint response;
    %let user_mprint=%sysfunc(getoption(mprint));
    options nomprint;

    %window microopen
        #1  @20 "Welcome!"
        #3  @20 "What would you like to accomplish?"
        //  @20 response 25 attr=rev_video required=yes
        //  @20 "Enter the appropriate response above, then hit ENTER to continue."
    ;
    %display microopen delete;
    %if %upcase(&RESPONSE) ne WORK %then %do;
        %window microend
            //  @20 "I'm sorry, you are not allowed to %lowcase(&RESPONSE)."
            //  @20 "Currently, you are only allowed to WORK."
            //  @20 "Unfortunately, I am unable to allow you to continue."
            //  @20 "Please contact your supervisor. This incident has been reported."
           ///  @20 "Hit ENTER to continue."
        ;
        %display microend delete;
        %goto exit;
    %end;

    %let msg1=Have you been granted access to the appropriate folders for this project?;
    %let msg2=Are you included on the IRB?;
    %let msg3=Has your code been reviewed?;
    %let msg4=Have you requested permission to run the code?;
    %let msg5=Have the decisions related to your code been finalized?;
    %let msg6=Have you validated your code?;
    %let msg7=Did you run this code using real data?;
    %let msg8=Are you certain about these answers?;

    %let i=1;
    %do %while(%symexist(MSG&I));
        %let response=;
        %window microwin
            //  @20 "&&MSG&I"
            //  @20 response 1 attr=rev_video required=yes
            //  @20 "Enter Y for Yes or N for No, then hit ENTER to continue."
        ;
        %display microwin delete;
        %if %upcase(&RESPONSE)=N %then %goto final;
        %let i=%eval(&I+1);
    %end;

    %window microinfo
        //  @20 "I'm sorry. I was not informed that you were allowed to work."
        //  @20 "Unfortunately, I am unable to allow you to continue."
        //  @20 "Please contact your supervisor. This incident has been reported."
       ///  @20 "Hit ENTER to continue."
    ;
    %display microinfo delete;
    %goto exit;

    %final:
    %window microfinal
        //  @20 "I'm sorry. Your responses to these questions are not satisfactory."
        //  @20 "Unfortunately, I am unable to allow you to continue."
        //  @20 "Please contact your supervisor. This incident has been reported."
       ///  @20 "Hit ENTER to continue."
    ;
    %display microfinal delete;

    %exit:
    options &user_mprint;

%mend Micro;

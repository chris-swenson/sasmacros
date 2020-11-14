%macro lslist(path,subdir=N,subex=,out=lslist,ext=,mindate=,maxdate=,minsize=,maxsize=,debug=N)
  / des='Populate a table with a list of files from a directory';

    /********************************************************************************
      BEGIN MACRO HEADER
     ********************************************************************************

        Name:       DirList
        Author:     Chris Swenson (http://www.cswenson.com/)
        Created:    2014-08-06
        Version:    2014-08-06

        OS:         *nix
        SAS:        9+
        Language:   English

        Purpose:    Obtain a listing of files in a directory, including subdirectories
                    if specified.

        Arguments:  path     - Valid *nix path of directory to examine (use
                               additional *nix pipe options on the file reference).
                    subdir=  - [optional] Flag to include subdirectories in directory
                               processing, defaulted to N. If set to Y then all
                               subdirectories of PATH will be searched. Otherwise,
                               only the path named in PATH will be searched. (Note:
                               the process may run slower if subdirectories are included)
                    subex=   - [optional] subdirectory names to exclude
                    out=     - [optional] Name of output file containing results.
                    ext=     - [optional] Extension to filter output files.
                    mindate= - [optional] Minimum date/time of file to report.
                               Note: The MAXDATE and MINDATE must be SAS date/time
                               constants in one of the following formats:
                               - 'ddMONyy:HH:MM'dt
                               - 'ddMONyy'd
                               - 'HH:MM't
                    maxdate= - [optional] Maximum date/time of file to report.
                    minsize= - [optional] Minimum size of file to report (bytes).
                    maxsize= - [optional] Maximum size of file to report (bytes).
                    debug=   - Y/N whether to debug

        Revisions
        ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
        Date        Author  Comments
        ¯¯¯¯¯¯¯¯¯¯  ¯¯¯¯¯¯  ¯¯¯¯¯¯¯¯
        2014-08-06  CAS     Created macro based on DirList macro.
        2014-09-16  CAS     Added additional path check.
        2015-10-26  CAS     Updated for files with spaces in name.

        YYYY-MM-DD  III     Please use this format and insert new entries above

     ********************************************************************************
      END MACRO HEADER
     ********************************************************************************/

    /* Check arguments */
    %if %superq(PATH) = %str() %then %do;
        %put %str(E)RROR: No PATH specified.;
        %return;
    %end;
    /* REVISION 2014-9-16 CAS: Added additional path check */
    %else %if %sysfunc(fileexist(%superq(PATH))) = 0 %then %do;
      %put %str(E)RROR: The specified path does not exist.;
      %return;
    %end;
    %if &SUBDIR = Y %then %let subdir = R;
    %else %let subdir = ;

    /* Remove the extra slash */
    /* REVISION 2015-10-27 CAS: Converted to data step for easier handling */
    data _null_;
      format path $250.;
      path = "&PATH";
      if substr(path, length(path), 1) = "/" then do;
        path = substr(path, 1, length(path)-1);
        call symput('path', path);
      end;
    run;
    %put PATH = &PATH;

    /* Execute pipe */
    filename ls pipe "ls -l&SUBDIR. &PATH.";

    /* Parse pipe */
    data &OUT;
      /* Set up columns */
      format
        path filename reference $255.
        type_permissions $10.
        count 8.
        owner pgroup $50.
        size comma20.
        month $3.
        day $2.
        year_time $5.
        date mmddyy10.
        time time8.
        datetime datetime20.
      ;
      retain path;

      /* Input file from pipe */
      infile ls length = reclen firstobs = 2;
      input line $varying1024. reclen;
      line = compbl(line);

      /* Identify path */
      if _N_ = 1 then do;
        path = "&PATH";
        flag = 0;
      end;
      else if substr(line, 1, 1) = 'd' then do;
        delete;
      end;
      else do;
        flag = 0;
      end;

      /* Delete extra lines */
      if reclen = 0
      or substr(line, 1, 2) in ('..')
      or substr(line, 1, 5) in ('total')
      then delete;

      /* Start: Process filename records */
      if flag = 0 then do;

        /* REVISION 2015-10-26 CAS: Measuring lines with parts */
      %if "&DEBUG" = "Y" %then %do;
        put line=;
      %end;
        line_length = length(line);
        part_length = 0;

        /* Array for processing parts of line */
        array parts $250 part1-part9;

        /* Process each part of the line */
        do i = 1 to dim(parts);
          parts{i} = trim(scan(line, i, ' '));
          /* Adding 1 to account for space */
          part_length = part_length + length(parts{i}) + 1;
      %if "&DEBUG" = "Y" %then %do;
          _length = length(parts{i}) + 1;
          put parts{i}= i= _length=;
      %end;
        end;
        /* Subtract one for the trailing space */
        part_length = part_length - 1;

        type_permissions = part1;
        count = input(part2, 8.);
        owner = part3;
        pgroup = part4;
        size = input(part5, 8.);
        month = part6;
        day = part7;
        year_time = part8;

        /* REVISION 2015-10-26 CAS: Correcting when filename has spaces */
        filename = scan(line, 9, ' ');
        file_length = length(filename);
        if part_length ne line_length then do;
          filename = substr(line, part_length - file_length + 1, line_length - part_length + file_length);
      %if "&DEBUG" = "Y" %then %do;
          filename = left(filename);
          put filename= part_length= line_length= file_length=;
      %end;
        end;

        /* REVISION 2015-10-26 CAS: Fixing reference variable */
        if find(line, '->') > 0 then reference = scan(line, -1, ' ');
        else reference = '';

        if find(year_time, ':') then do;
          time = input(year_time, time8.);
          date = input(cats(day, month, put(year(today()), 4.)), date9.);
        end;
        else do;
          time = .;
          date = input(cats(day, month, year_time), date9.);
        end;

        if time = . then datetime = dhms(date, 0, 0, 0);
        else datetime = input(put(date, date7.) || ':' || put(time, time5.), datetime13.) ;

    /* Date filters */
    %if %eval(%length(&MAXDATE) + %length(&MINDATE) > 0) %then %do;

      %if %length(&MAXDATE) > 0 %then %do;
        if datetime <= &MAXDATE;
      %end;
      %if %length(&MINDATE) > 0 %then %do;
        if datetime >= &MINDATE;
      %end;

    %end;

    /* Size filter */
    %if %length(&MAXSIZE) > 0 %then %do;
      if size <= &MAXSIZE;
    %end;
    %if %length(&MINSIZE) > 0 %then %do;
      if size >= &MINSIZE;
    %end;

    /* Extension filter */
    %local extcnt e extcur;
    %if %superq(EXT) ne %str() %then %do;

      %let extcnt = %sysfunc(countw(%superq(EXT), %str( )));
      if find(filename, '.') and scan(upcase(filename), -1, '.') in (
     %do e = 1 %to &EXTCNT;
       %let extcur = %scan(%upcase(%superq(EXT)), &E, %str( ));
        "%superq(EXTCUR)"
       %if &E ne &EXTCNT %then %str(, );
     %end;
      );

    %end;

      /* End: Process filename records */
      end;

    /* Subdirectory filter */
    %if %superq(SUBEX) ne %str() %then %do;
      %local subexcnt s subexcur;
      %let subexcnt = %sysfunc(countw(%superq(SUBEX), %str( )));
        if path ne "%superq(PATH)" then do;
        if scan(substr(upcase(path), %length(%superq(PATH))+1, length(compbl(path))-%length(%superq(PATH))), 1, '\')
            in (
      %do s = 1 %to &SUBEXCNT;
        %let subexcur = %scan(%upcase(%superq(SUBEX)), &S, %str( ));
        "%superq(SUBEXCUR)"
        %if &S ne &SUBEXCNT %then %str(, );
      %end;
        ) then delete; end;
    %end;

      drop line flag;
    run;

    proc sort data = &OUT out = &OUT;
        by owner path filename;
    run;

    /* Clear the pipe */
    filename ls clear;

%mend lslist;
%macro SelectMax(ds,by,var,out=) / des='Select record with maximum value';

    /* BEGIN MACRO HEADER: See SelectStat */
    %SelectStat(&DS, &BY, &VAR, out=&OUT, stat=MAX);

%mend SelectMax;

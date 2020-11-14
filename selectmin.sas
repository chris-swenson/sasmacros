%macro SelectMin(ds,by,var,out=) / des='Select record with minimum value';

    /* BEGIN MACRO HEADER: See SelectStat */
    %SelectStat(&DS, &BY, &VAR, out=&OUT, stat=MIN);

%mend SelectMin;

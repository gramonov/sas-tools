/*
 * A simple macro for bulk export of all datasets in library into .csv.
 * In addition, it extracts metadata and dumps labels of empty datasets.
 * Tested on SAS9.0+
 */

/*
 * @library library name.
 * @path a path to export.
 */
%macro bulk_export(library, path);
	* iterator and number of data sets in a library ;
	%local i, dslen;

	ods listing close;
	ods output members = ds;
 	proc datasets mt = data library = &library;
		run;
	quit;
	ods listing;

	* calculate number of data sets ;
	data _null_;
		if 0 then set ds nobs = nobs;
		call symput('dslen', nobs);
	run;

	* store data source names ;
	%do i=1 %to &dslen;
		%local d&i;
	%end;
	
	data _null_;
		set ds;
		call symput ('d' || left(_n_), trim(name));
	run;

	* export each data set ;
	%do i=1 %to &dslen;
		%local obssize;

		proc sql noprint;
			select count(*) into :obssize from &library..&&d&i;
			%put &obssize;
		quit;	

		proc contents data = &library..&&d&i noprint out = td;
		run;	

		%if &obssize = 0 %then 
			%do;
				ods csv body="&path.empties\&&d&i...csv";
				proc print data=td noobs;
					var label;
				run;
				ods csv close;
			%end;

		ods csv body="&path.meta\&&d&i...csv";
		proc print data=td noobs;
		run;
		ods csv close;

		proc export data = &library..&&d&i
       		outfile = "&path.export\&&d&i...csv" 
           	dbms = csv replace;
		run;
	%end;
%mend;

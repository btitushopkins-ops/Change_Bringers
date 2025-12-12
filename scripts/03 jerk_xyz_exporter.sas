/**********************************************************************************************************************/
/* Program name:    03_jerk_transpose_and_exporter.sas                                                                */
/* Programmer:      Wing Ki Liu and Brandon Hopkins                                                                                   */
/* Purpose:         Transpose jerk_x/y/z signals by time_point, merge into XYZ tables, attach ParkinsonsFlag,         */
/*                  and export task-specific CSVs for downstream modeling.                                            */
/* Input:           public.[movement]_dom_2g, public.movement_clean_dom                                               */
/* Output:          Transposed jerk data by task, subset by dominant hand and condition in ("Healthy", "Parkinson's") */
/*                  /tmp/jerk_xyz_[movement]_part1.csv (x), part2.csv (y), part3.csv (z)                              */
/**********************************************************************************************************************/

cas mycas;
caslib _all_ assign;


%let movement= DrinkGlas Entrainment LiftHold TouchNose;
/* %let movement= CrossArms DrinkGlas Entrainment HoldWeight LiftHold PointFinger Relaxed RelaxedTask StretchHold TouchIndex TouchNose; */

%macro transpose_jerk;
  %do i = 1 %to %sysfunc(countw(&movement));
    %let current = %scan(&movement, &i);

    proc transpose data=public.&current._dom_2g out=jerk_x_&current prefix=jerk_x_;
      by id;
      var jerk_x;
      id time_point;
    run;

    proc transpose data=public.&current._dom_2g out=jerk_y_&current prefix=jerk_y_;
      by id;
      var jerk_y;
      id time_point;
    run;

    proc transpose data=public.&current._dom_2g out=jerk_z_&current prefix=jerk_z_;
      by id;
      var jerk_z;
      id time_point;
    run;


    proc cas;
      table.dropTable / caslib="Public" name="jerk_xyz_&current" quiet=true;
    quit; 

    data public.jerk_xyz_&current.0;
      merge jerk_x_&current jerk_y_&current jerk_z_&current;
      by id;
    run;
  %end;
%mend;

%transpose_jerk;

proc sql;
  select count(distinct time_point) as tp_x from public.Entrainment_dom_2g where jerk_x is not missing;
  select count(distinct time_point) as tp_y from public.Entrainment_dom_2g where jerk_y is not missing;
  select count(distinct time_point) as tp_z from public.Entrainment_dom_2g where jerk_z is not missing;
quit;

proc sql;
  select count(distinct id) as id_x from jerk_x_Entrainment;
  select count(distinct id) as id_y from jerk_y_Entrainment;
  select count(distinct id) as id_z from jerk_z_Entrainment;
quit;

data public.id_flags;
  set public.movement_clean_dom(keep=id ParkinsonsFlag);
  by id;
  if first.id;
run;

%macro add_flag;
  %do i = 1 %to %sysfunc(countw(&movement));
    %let current = %scan(&movement, &i);
    proc cas;
      table.dropTable / caslib="Public" name="jerk_xyz_&current." quiet=true;
    quit;

    data public.jerk_xyz_&current.(promote=yes);
      merge public.jerk_xyz_&current.0(in=a)
            public.id_flags(keep=id ParkinsonsFlag);
      by id;
      if a;
    run;
  %end;
%mend;

%add_flag;



%macro output(current);

  /* Part 1: jerk_x + id + ParkinsonsFlag */
  data work.jerk_xyz_&current._part1;
    set public.jerk_xyz_&current.(keep=id jerk_x_: ParkinsonsFlag);
  run;

  /* Part 2: jerk_y + id + ParkinsonsFlag */
  data work.jerk_xyz_&current._part2;
    set public.jerk_xyz_&current.(keep=id jerk_y_: ParkinsonsFlag);
  run;

  /* Part 3: jerk_z + id + ParkinsonsFlag */
  data work.jerk_xyz_&current._part3;
    set public.jerk_xyz_&current.(keep=id jerk_z_: ParkinsonsFlag);
  run;

 %global input_&current._part1 input_&current._part2 input_&current._part3;
  %let input_&current._part1=jerk_xyz_&current._part1;
  %let input_&current._part2=jerk_xyz_&current._part2;
  %let input_&current._part3=jerk_xyz_&current._part3;


%mend;

options mprint;
%output(DrinkGlas);
%output(Entrainment);  
%output(LiftHold);
%output(TouchNose);

%put input_DrinkGlas_part1=&input_DrinkGlas_part1;

cas mycas terminate;
ods listing close;



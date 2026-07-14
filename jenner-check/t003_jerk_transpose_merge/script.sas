/* Transpose + merge core from "03 jerk_xyz_exporter.sas"
   (Wing Ki Liu, Brandon Hopkins).
   Reshapes the long directional-jerk signal to one row per id (jerk_x_1,
   jerk_x_2, ... columns) for each of x/y/z, then merges the three wide tables
   by id. The macro parameterises this per movement; here it is exercised on
   the Entrainment movement. CAS "public." libref redirected to WORK. */

%let current = Entrainment;

proc transpose data=work.&current._dom_2g out=jerk_x_&current prefix=jerk_x_;
  by id;
  var jerk_x;
  id time_point;
run;

proc transpose data=work.&current._dom_2g out=jerk_y_&current prefix=jerk_y_;
  by id;
  var jerk_y;
  id time_point;
run;

proc transpose data=work.&current._dom_2g out=jerk_z_&current prefix=jerk_z_;
  by id;
  var jerk_z;
  id time_point;
run;

data work.jerk_xyz_&current.0;
  merge jerk_x_&current jerk_y_&current jerk_z_&current;
  by id;
run;

/* the author's sanity checks: distinct time points and distinct ids */
proc sql;
  select count(distinct time_point) as tp_x from work.Entrainment_dom_2g where jerk_x is not missing;
quit;

proc sql;
  select count(distinct id) as id_x from jerk_x_Entrainment;
quit;

proc print data=work.jerk_xyz_Entrainment0; run;

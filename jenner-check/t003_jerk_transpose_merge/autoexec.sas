/* cap input rows for the captured run */
options obs=100;

/* Mock stand-in for public.Entrainment_dom_2g: the long-format directional
   jerk signal for one movement, dominant hand only, keyed by id and time_point.
   Two ids x a few time points is enough to exercise the proc transpose
   long->wide reshape (by id, id time_point) and the x/y/z merge below. */
data work.Entrainment_dom_2g;
  infile datalines dsd truncover;
  input id $ time_point jerk_x jerk_y jerk_z ParkinsonsFlag;
datalines;
P01,1,0.04,0.02,0.01,1
P01,2,-0.07,0.03,-0.02,1
P01,3,0.15,-0.05,0.04,1
H02,1,0.01,0.00,0.01,0
H02,2,0.02,-0.01,0.00,0
H02,3,-0.01,0.01,-0.01,0
;
run;

/* proc transpose BY id requires id-sorted input; the upstream _dom_2g tables
   arrive sorted, so sort the mock to match. */
proc sort data=work.Entrainment_dom_2g;
  by id time_point;
run;

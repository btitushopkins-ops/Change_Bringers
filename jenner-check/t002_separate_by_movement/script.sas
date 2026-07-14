/* The %separate macro from "02 data cleaning.sas"
   (Wing Ki Liu, Kartik Sehgal, Brandon Hopkins).
   Splits the cleaned movement table into one dataset per movement by scanning
   the &movement token list with %sysfunc(countw()) / %scan. Macro logic and
   the per-task DATA step subset are preserved; the CAS "public." libref is
   redirected to WORK and the CAS-only dropTable step is not needed standalone.
   The mock movement_clean below stands in for public.movement_clean (the
   cleaned per-observation table whose "task" column names the movement). */

data work.movement_clean;
  infile datalines dsd truncover;
  input id $ task $ wrist $ time_point Combined_Magnitude;
datalines;
P01,TouchNose,LeftWrist,60,1.42
P01,TouchNose,LeftWrist,61,1.51
H02,TouchNose,RightWrist,60,0.39
P01,DrinkGlas,LeftWrist,60,1.10
P01,DrinkGlas,LeftWrist,61,1.22
H02,DrinkGlas,RightWrist,60,0.55
P01,Entrainment,LeftWrist,60,0.98
H02,Entrainment,RightWrist,60,0.31
P01,LiftHold,LeftWrist,60,1.33
H02,LiftHold,RightWrist,60,0.48
P01,Relaxed,LeftWrist,60,0.20
H02,CrossArms,RightWrist,60,0.60
;
run;

/* Split into 11 datasets by movement */
%let movement= CrossArms DrinkGlas Entrainment HoldWeight LiftHold PointFinger Relaxed RelaxedTask StretchHold TouchIndex TouchNose;

%macro separate;
    /* Loop through each word (dataset name) in the &movement variable */
    %do i = 1 %to %sysfunc(countw(&movement));
        /* Get the current movement name (token) */
        %let current_movement = %scan(&movement, &i);
        /* Create a new dataset using the current movement name */
        data work.&current_movement;
            set work.movement_clean;
            if task="&current_movement";
        run;
    %end;
%mend;

/* Execute the macro to run the data steps */
options mprint;
%separate;

/* Confirm the split produced one dataset per movement token */
proc contents data=work.TouchNose; run;
proc print data=work.DrinkGlas; run;

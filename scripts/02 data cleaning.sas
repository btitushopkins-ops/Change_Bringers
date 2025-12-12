/**********************************************************************************************************************/
/* Program name:    02 data cleaning.sas                                                                              */
/* Programmer:      Wing Ki Liu, Kartik Sehgal, Brandon Hopkins                                                       */
/* Purpose:         To clean prepare data for analysis. And to create new analysis variables                          */
/* Input:           public.all_movement_data , public.file_list                                                       */
/* output           TBD                                                                                               */
/**********************************************************************************************************************/
cas mycas;
caslib _all_ assign;
/* ods listing file="/Public/Programs/data cleaning BH.lst";  */

/*Checking spelling on small dataset prior to merge*/
proc freqtab data=public.file_list;
    tables gender handedness appearance_in_kinship app_in_first_grade_kinship effect_of_alcohol_on_tremor/nocum;
run;


data public.clean0;
  merge public.all_movement_data(drop=filename rename=(person=id))
         public.file_list(drop=label resource_type study_id);
  by id;
  if condition = "Parkinson's" then ParkinsonsFlag = 1;
  else ParkinsonsFlag = 0;
run;

/*check the data merged correctly. There should be the same number of records on public.all_movement_data and public.clean0*/
proc contents data=public.all_movement_data order=varnum;
run;

proc contents data=public.clean0 order=varnum;
run;

/* clean#1: checking for blank rows in numeric and character variables*/
proc means data=public.clean0 nmiss n mean std min max;
run;

proc fedsql sessref=mycas;
  select 
    count(*) as total_rows,
    count(task) as non_missing_task,
    count(*) - count(task) as missing_task,
    count(wrist) as non_missing_wrist,
    count(*) - count(wrist) as non_missing_wrist,
    count(gender) as non_missing_gender,
    count(*) - count(gender) as missing_gender,
    count(handedness) as non_missing_handedness,
    count(*) - count(handedness) as missing_handedness,
    count(appearance_in_kinship) as non_missing_appearance_in_kinship,
    count(*) - count(appearance_in_kinship) as missing_appearance_in_kinship,
    count(app_in_first_grade_kinship) as non_missing_app_in_first_grade_kinship,
    count(*) - count(app_in_first_grade_kinship) as missing_app_in_first_grade_kinship,
    count(effect_of_alcohol_on_tremor) as non_missing_effect_of_alcohol_on_tremor,
    count(*) - count(effect_of_alcohol_on_tremor) as missing_effect_of_alcohol_on_tremor
    from public.clean0;
quit;
proc cas;
  table.dropTable / caslib="Public" name="clean_1 " quiet=true;
quit;

/* since there are missing values in app_in_first_grade_kinship variable, so
we replace the blanks by NA */
proc fedsql sessref=mycas;
  create table public.clean_1 as 
  select *,
    case 
      when app_in_first_grade_kinship = ' ' then 'NA'
      else app_in_first_grade_kinship
    end as app_in_first_grade_kinship_clean
  from public.clean0;
quit;

/* checking the missings were replace in new variable app_in_first_grade_kinship_clean*/
proc fedsql sessref=mycas;
  select 
    count(app_in_first_grade_kinship_clean) as non_missing_app_in_first_grade_kinship,
    count(*) - count(app_in_first_grade_kinship_clean) as missing_app_in_first_grade_kinship
    from public.clean_1;
quit;

/*Checking spelling on large dataset excluding the ones that came from file_list*/
proc fedsql sessref=mycas;

    /* Frequency for TASK */
    select
        task,
        count(*) as Frequency
    from public.clean_1 
    group by task
    order by task;

    /* Frequency for wrist */
    select
        wrist,
        count(*) as Frequency
    from public.clean_1 
    group by wrist
    order by wrist;

quit;

/* Creating a variable time_point to track the sequence of the recording 
   of the 10 or 20 second movements */

   /*subsetting for testing */
data public.clean_2;
  set public.clean_1;
  by id task wrist time;

  retain time_point;
  if first.id or first.task or first.wrist then time_point=0;
  time_point+1;

run;


data public.clean_3;
  set public.clean_2;
  by id task wrist time_point;

   /* 1. Magnitude */
     /* Compute Accelerometer Magnitude */
     Accel_Magnitude = sqrt(Accelerometer_X**2 + Accelerometer_Y**2 + Accelerometer_Z**2);

     /* Compute Gyroscope Magnitude */
     Gyro_Magnitude = sqrt(Gyroscope_X**2 + Gyroscope_Y**2 + Gyroscope_Z**2);

     /* Compute Combined Magnitude */
     Combined_Magnitude = sqrt(Accel_Magnitude**2 + Gyro_Magnitude**2);


   /* 4 Jerk */
     if first.task or first.wrist then do;
                                       dt = .;
                                       jerk = .;
                                       end;
     else do;
          dt = time_point - lag(time_point);
          jerk = (Combined_Magnitude - lag(Combined_Magnitude)) / dt;
          end;


   /* 2 step 1 (Signal Magnitude Area) */  /* can not figure out step 2*/
     sma_raw = abs(Accelerometer_X) + abs(Accelerometer_Y) + abs(Accelerometer_Z);


   /* 3. RMS (Root Mean Square) */
     rms = sqrt((Accelerometer_X**2 + Accelerometer_Y**2 + Accelerometer_Z**2) / 3);


   /* 5. Orientation: Pitch & Roll */
     pitch = atan2(Accelerometer_X, sqrt(Accelerometer_Y**2 + Accelerometer_Z**2));
     roll  = atan2(Accelerometer_Y, Accelerometer_Z);
     pitch_deg = pitch * (180 / constant('PI'));
     roll_deg  = roll  * (180 / constant('PI'));

   label
     Accel_Magnitude     = "Accelerometer Vector Magnitude"
     Gyro_Magnitude      = "Gyroscope Vector Magnitude"
     Combined_Magnitude  = "Combined Sensor Magnitude (Accel + Gyro)"
     sma_raw             = "Signal Magnitude Area (Raw Accelerometer)"
     rms                 = "Root Mean Square of Accelerometer Axes"
     dt                  = "Time Delta Between Observations"
     jerk                = "Rate of Change of Combined Magnitude (Jerk)"
     pitch               = "Pitch Angle (Radians)"
     roll                = "Roll Angle (Radians)"
     pitch_deg           = "Pitch Angle (Degrees)"
     roll_deg            = "Roll Angle (Degrees)";

   if (handedness = "left" and wrist = "LeftWrist") or 
      (handedness = "right" and wrist = "RightWrist") then 
      dominant_wrist = 1;
   else dominant_wrist = 0;


run;

data public.clean_4;
  set public.clean_3;
  by id task wrist time_point;

  retain lag_ax lag_ay lag_az;

  /* Reset lag values at the start of each wrist-task sequence */
  if first.task or first.wrist then do;
    lag_ax = .; lag_ay = .; lag_az = .;
  end;

  /* Calculate directional jerk components */
  jerk_x = Accelerometer_X - lag_ax;
  jerk_y = Accelerometer_Y - lag_ay;
  jerk_z = Accelerometer_Z - lag_az;

  /* Update lag values */
  lag_ax = Accelerometer_X;
  lag_ay = Accelerometer_Y;
  lag_az = Accelerometer_Z;

  label
    jerk_x = "Directional Jerk X"
    jerk_y = "Directional Jerk Y"
    jerk_z = "Directional Jerk Z";
run;

proc contents data=public.clean_4 order=varnum; run;


proc cas;
   table.dropTable / caslib="Public" name="movement_clean" quiet=true;
quit;

/* removing the 1st .5 seconds per time series to avoid feeding the vibration notification into the model */
%let cutoff=50; /* sample rate of 100 times recorded in 1 second, so 50 samples in .5 seconds*/

data public.movement_clean(promote=yes);
  set public.clean_4;
    
    if time_point>&cutoff.;
run;

/*checking the creation of variables */
proc means data=public.movement_clean nmiss n min mean max std;
    var Accel_Magnitude Gyro_Magnitude Combined_Magnitude 
         sma_raw rms dt jerk pitch roll pitch_deg
         roll_deg dominant_wrist;
run;

proc means data=public.movement_clean nmiss n;
    var jerk_x jerk_y jerk_z; 
run;

proc contents data=public.movement_clean order=varnum;
run;

proc freqtab data=public.movement_clean;
    tables 	wrist*handedness*dominant_wrist/list;
run;

	

proc cas;
   table.dropTable / caslib="Public" name="movement_clean_2g" quiet=true;
quit;

data public.movement_clean_2g(promote=yes);
  set public.movement_clean;
  if condition in("Healthy", "Parkinson's");
run;

proc contents data=public.movement_clean_2g order=varnum;
run;


/* Split into 11 datasets by movement */
%let movement= CrossArms DrinkGlas Entrainment HoldWeight LiftHold PointFinger Relaxed RelaxedTask StretchHold TouchIndex TouchNose;

%macro separate;
    /* Loop through each word (dataset name) in the &movement variable */
    %do i = 1 %to %sysfunc(countw(&movement));
        /* Get the current movement name (token) */
        %let current_movement = %scan(&movement, &i); 
        proc cas;
          table.dropTable / caslib="Public" name="&current_movement" quiet=true;
        quit;
        /* Create a new dataset using the current movement name */
        data public.&current_movement(promote=yes);
            set public.movement_clean;
            if task="&current_movement";
        run;
    %end;
%mend;

/* Execute the macro to run the data steps */
%separate;

cas mycas terminate;
ods listing close;
/* Feature-engineering DATA steps from "02 data cleaning.sas"
   (Wing Ki Liu, Kartik Sehgal, Brandon Hopkins).
   Logic preserved verbatim; the CAS "public." libref is redirected to WORK so
   the same magnitude / jerk / RMS / orientation computations run standalone. */

data work.clean_3;
  set work.clean_2;
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

data work.clean_4;
  set work.clean_3;
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

proc contents data=work.clean_4 order=varnum; run;

/*checking the creation of variables */
proc means data=work.clean_4 nmiss n min mean max std;
    var Accel_Magnitude Gyro_Magnitude Combined_Magnitude
         sma_raw rms dt jerk pitch roll pitch_deg
         roll_deg dominant_wrist;
run;

proc means data=work.clean_4 nmiss n;
    var jerk_x jerk_y jerk_z;
run;

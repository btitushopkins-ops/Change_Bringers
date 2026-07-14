/* cap input rows for the captured run */
options obs=100;

/* Mock stand-in for the CAS table public.clean_2 (the wrist accel/gyro time
   series). Column shape/types match what "02 data cleaning.sas" reads: id,
   task, wrist, handedness, condition, time_point and the six sensor axes.
   Two ids x two wrists x a short time series is enough to exercise the
   first./lag./retain feature-engineering logic below. */
data work.clean_2;
  infile datalines dsd truncover;
  input id $ task $ wrist $ handedness $ condition $ time_point
        Accelerometer_X Accelerometer_Y Accelerometer_Z
        Gyroscope_X Gyroscope_Y Gyroscope_Z;
datalines;
P01,TouchNose,LeftWrist,left,Parkinson's,1,0.98,0.10,0.05,1.2,0.4,0.3
P01,TouchNose,LeftWrist,left,Parkinson's,2,1.02,0.12,0.07,1.1,0.5,0.2
P01,TouchNose,LeftWrist,left,Parkinson's,3,0.95,0.08,0.04,1.4,0.3,0.4
P01,TouchNose,LeftWrist,left,Parkinson's,4,1.10,0.15,0.09,0.9,0.6,0.1
P01,TouchNose,RightWrist,left,Parkinson's,1,0.50,0.20,0.30,0.7,0.2,0.5
P01,TouchNose,RightWrist,left,Parkinson's,2,0.55,0.22,0.28,0.8,0.3,0.4
P01,TouchNose,RightWrist,left,Parkinson's,3,0.48,0.18,0.33,0.6,0.1,0.6
H02,TouchNose,RightWrist,right,Healthy,1,0.30,0.05,0.02,0.2,0.1,0.1
H02,TouchNose,RightWrist,right,Healthy,2,0.31,0.06,0.03,0.3,0.1,0.2
H02,TouchNose,RightWrist,right,Healthy,3,0.29,0.04,0.02,0.2,0.2,0.1
H02,TouchNose,RightWrist,right,Healthy,4,0.32,0.07,0.04,0.3,0.1,0.1
;
run;

/* The upstream pipeline delivers clean_2 already ordered; sort the mock to the
   same BY key so the first./last. logic in the script sees grouped input. */
proc sort data=work.clean_2;
  by id task wrist time_point;
run;

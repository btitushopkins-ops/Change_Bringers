import pandas as pd
import glob
import os



# Program 1: range(1, 95)
# Program 2: range(95, 189)
# Program 3: range(189, 283)
# Program 4: range(283, 377)
# Program 5: range(377, 470)

data_dir = r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\movement\timeseries"  # Change to your folder path
column_names = ['Time', 'Accelerometer_X', 'Accelerometer_Y', 'Accelerometer_Z', 'Gyroscope_X', 'Gyroscope_Y', 'Gyroscope_Z']
all_data = []

for person_num in range(189, 283):  # 189 to 282
    person_id = f"{person_num:03d}"
    pattern = os.path.join(data_dir, f"{person_id}_*_*.txt")
    file_list = glob.glob(pattern)
    for file_path in file_list:
        base = os.path.basename(file_path)
        parts = base.replace('.txt', '').split('_')
        person = parts[0]
        task = parts[1]
        wrist = parts[2]
        df = pd.read_csv(file_path, names=column_names, header=None, sep=',')
        df['person'] = person
        df['task'] = task
        df['wrist'] = wrist
        df['filename'] = base  # Add filename as a variable
        all_data.append(df)

# Combine all into one DataFrame
final_df = pd.concat(all_data, ignore_index=True)
final_df.to_csv(r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data3.csv", index=False)
import pandas as pd
import os

def concatenate_csv_files_by_name():
    # List your CSV file paths
    csv_files = [
        r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data1.csv",
        r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data2.csv",
        r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data3.csv",
        r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data4.csv",
        r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\movement_data5.csv"
    ]
    
    # Read all CSV files into a list of DataFrames
    dataframes = []
    for file in csv_files:
        if os.path.exists(file):
            df = pd.read_csv(file)
            print(f"Read {file}: {len(df)} rows")
            dataframes.append(df)
        else:
            print(f"Warning: {file} not found")
    
    # Concatenate all DataFrames
    if dataframes:
        combined_df = pd.concat(dataframes, ignore_index=True)

        # Save to new CSV file
        combined_df.to_csv(r"C:\Users\18645\pads-parkinsons-disease-smartwatch-dataset-1.0.0\pads-parkinsons-disease-smartwatch-dataset-1.0.0\preprocessed\all_movement_data.csv", index=False)
        print(f"Combined CSV saved with {len(combined_df)} total rows")
        return combined_df
    else:
        print("No files found to concatenate")
        return None

concatenate_csv_files_by_name()
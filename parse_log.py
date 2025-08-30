import re
import pandas as pd
import argparse

def parse_log(filepath, save_as=None):
    with open(filepath, "r", errors="ignore") as f:
        lines = f.readlines()

    results = []
    raw_file = None
    serials, firmwares, tur_name = [], [], ""

    for line in lines:
        # Capture raw file name
        if ">>>> input raw file for conversion:" in line:
            raw_file = line.split(":")[-1].strip()
            # reset for each new raw file
            serials, firmwares, tur_name = [], [], ""

        # Serial number differences
        if "rec. serial number in RINEX" in line:
            tur_match = re.findall(r"\b\w+TUR\b", line)
            if tur_match:
                tur_name = tur_match[0]
            serials.extend(re.findall(r"\((.*?)\)", line))

        # Firmware version differences
        if "rec. firmware version in RINEX" in line:
            tur_match = re.findall(r"\b\w+TUR\b", line)
            if tur_match:
                tur_name = tur_match[0]
            firmwares.extend(re.findall(r"\((.*?)\)", line))

        # Save result if serial or firmware data is found
        if serials or firmwares:
            results = [r for r in results if not (r["TUR Name"] == tur_name and r["Raw File"] == raw_file)]
            results.append({
                "TUR Name": tur_name,
                "Raw File": raw_file,
                "Serial Numbers": ", ".join(serials) if serials else "-",
                "Firmware Versions": ", ".join(firmwares) if firmwares else "-"
            })

    df = pd.DataFrame(results)

    # Print results with extra spacing, centered
    print("\nResult Table:\n")
    print(df.to_string(index=False, col_space=25, justify="center"))

    # Optional save
    if save_as:
        if save_as.lower() == "csv":
            df.to_csv("output.csv", index=False)
            print("\n✅ Results saved as 'output.csv'.")
        elif save_as.lower() == "excel":
            df.to_excel("output.xlsx", index=False)
            print("\n✅ Results saved as 'output.xlsx'.")

    return df


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Parse log file for TUR serial and firmware differences.")
    parser.add_argument("filepath", help="Input log file path (e.g., test.rtf)")
    parser.add_argument("--save", choices=["csv", "excel"], help="Optional: save results to CSV or Excel")

    args = parser.parse_args()
    parse_log(args.filepath, args.save)



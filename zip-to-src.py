import zipfile
import os
import sys

def convert_zip_to_src(zip_file_path, output_file_path='src.txt'):
    """
    Converts all files in a zip archive into a single text file suitable for OpenAI CustomGPT Knowledge.

    Parameters:
        zip_file_path (str): Path to the input zip file.
        output_file_path (str): Path to the output text file.
    """
    extracted_folder = "extracted_temp"
    
    # Step 1: Extract the zip file
    try:
        with zipfile.ZipFile(zip_file_path, 'r') as zip_ref:
            zip_ref.extractall(extracted_folder)
    except Exception as e:
        print(f"Error extracting zip file: {e}")
        sys.exit(1)

    # Step 2: Combine the contents of all files into a single text file
    combined_content = ""
    for root, _, files in os.walk(extracted_folder):
        for file in files:
            file_path = os.path.join(root, file)
            try:
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                    combined_content += f"\n\n---\nFILE: {file}\n---\n{content}"
            except Exception as e:
                combined_content += f"\n\n---\nFILE: {file}\n---\n[Error reading this file: {e}]"

    # Step 3: Write the combined content to the output file
    try:
        with open(output_file_path, 'w', encoding='utf-8') as output_file:
            output_file.write(combined_content)
        print(f"Success, combined content written to: {output_file_path}")
    except Exception as e:
        print(f"Error writing output file: {e}")
        sys.exit(1)
    finally:
        # Cleanup: Remove the extracted folder
        for root, _, files in os.walk(extracted_folder, topdown=False):
            for file in files:
                os.remove(os.path.join(root, file))
            os.rmdir(root)

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python convert_zip_to_src.py <zip_file_path> [output_file_path]")
    else:
        zip_path = sys.argv[1]
        output_path = sys.argv[2] if len(sys.argv) > 2 else "src.txt"
        convert_zip_to_src(zip_path, output_path)

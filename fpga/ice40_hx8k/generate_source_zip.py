import os
import subprocess
import argparse
import tempfile
import shutil

def main():
    parser = argparse.ArgumentParser(description='Generate source zip')
    parser.add_argument('--output-dir', required=True, help='Output directory for the zip file')
    args = parser.parse_args()
    
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
    out_dir = os.path.abspath(args.output_dir)
    
    zip_path = os.path.join(out_dir, 'Phase4_Source.zip')
    if os.path.exists(zip_path):
        os.remove(zip_path)
        
    with tempfile.TemporaryDirectory() as temp_dir:
        # rsync the working tree
        # Use --exclude to avoid copying big unnecessary folders right away
        subprocess.run(['rsync', '-av', '--exclude=.git', '--exclude=build', '--exclude=.venv', '--exclude=venv', '--exclude=__MACOSX', f'{repo_root}/', f'{temp_dir}/Hardware_Implemented_Neural_Network/'], check=True)
        
        target_dir = os.path.join(temp_dir, 'Hardware_Implemented_Neural_Network')
        
        # also remove files listed in requirement 3
        # .git/, .venv/, venv/, build/, __pycache__/, .DS_Store, __MACOSX/, *.pyc, *.o, *.cf, e~*, tb_mlp_phase4, tb_mlp_phase4_demo, tb_mlp_phase4_linear_reference
        clean_cmd = """
        find . -name '__pycache__' -exec rm -rf {} +
        find . -name '.DS_Store' -delete
        find . -name '*.pyc' -delete
        find . -name '*.o' -delete
        find . -name '*.cf' -delete
        find . -name 'e~*' -delete
        rm -f fpga/ice40_hx8k/tb_mlp_phase4
        rm -f fpga/ice40_hx8k/tb_mlp_phase4_demo
        rm -f fpga/ice40_hx8k/tb_mlp_phase4_linear_reference
        """
        subprocess.run(clean_cmd, shell=True, cwd=target_dir, check=True)
        
        # Zip it
        zip_cmd = f"COPYFILE_DISABLE=1 zip -X -r {zip_path} Hardware_Implemented_Neural_Network"
        subprocess.run(zip_cmd, shell=True, cwd=temp_dir, check=True)
        
    print(f"Source.zip created successfully at: {zip_path}")

if __name__ == '__main__':
    main()

#!/bin/sh

# 1. Setup Directories (DO NOT CHANGE!)
repoDir=$(dirname "$(realpath "$0")")
echo "Working in: $repoDir"
cd $repoDir

# 2. Build the GPU Suffix Array Builder
# Since you're using CUB and custom CUDA kernels, ensure your CMakeLists.txt 
# is configured for the A30 (Compute Capability 8.0).
mkdir -p build
cd build
cmake ..
make -j8 # Utilizing the 8 cores you requested

# 3. Execution
# Note: The flags have changed from your previous assignment. 
# We now use --input/-i and --output/-o based on your C++ code.

INPUT_FASTA="../data/smallIn.fa"
OUTPUT_SA="suffix_array.txt"

echo "Starting GPU Suffix Array Construction..."
echo "Input: $INPUT_FASTA"

# Run the binary (assuming the output binary is named 'sa_builder')
./sa_builder --input $INPUT_FASTA --output $OUTPUT_SA

# ------------------------------------------------------------------
# 4. Verification (Optional)
# ------------------------------------------------------------------
# If you have a script to verify the SA is correctly sorted, 
# you would run it here. Example:
# python3 ../scripts/verify_sa.py --fasta $INPUT_FASTA --sa $OUTPUT_SA

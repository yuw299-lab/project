#!/bin/sh

# 1. Setup Directories (DO NOT CHANGE!)
repoDir=$(dirname "$(realpath "$0")")
echo "Working in: $repoDir"
cd $repoDir

# 2. Build the GPU Suffix Array Builder
mkdir -p build
cd build
cmake ..
make -j8 

# 3. Execution

INPUT_FASTA="../data/chr1_GL383518v1_alt.fa"
OUTPUT_SA="suffix_array.txt"

echo "Starting GPU Suffix Array Construction..."
echo "Input: $INPUT_FASTA"

# Run the binary 
nsys profile --stats=true ./sa_builder --input $INPUT_FASTA --output $OUTPUT_SA

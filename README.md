

# GPU-Accelerated Suffix Array Construction
This project provides a high-performance implementation of Suffix Array (SA) construction for large genomic strings, leveraging the Prefix Doubling algorithm and NVIDIA CUB primitives.

Project Overview
Objective: Efficiently construct suffix arrays for massive genomic datasets (e.g., human chromosomes) using GPU parallelism.

Core Techniques: * Prefix Doubling (Karp-Miller-Rosenberg)

Parallel Radix Sort (cub::DeviceRadixSort)

Parallel Inclusive Scan (cub::DeviceScan)

Features: Includes optional BWT output generation and benchmarking tools.

# To reproduce results


Clone the repo 
```
git clone https://github.com/yuw299-lab/project.git

```

I use the same docker image as assignments to navigate through DSMLP

```
ssh yuw299@dsmlp-login.ucsd.edu /opt/launch-sh/bin/launch.sh -v a30 -c 8 -g 1 -m 8 -i yatisht/ece213-wi26:latest -f ./project/run-commands.sh
```

smallIn.fa is a custom FASTA file to test the correctness by manually checking the output. 
The chr1_GL3835(18 - 20)_alt.fa can be used to measure performance, while chr22.fa.zip can be used to test large input. 

#ifndef SA_GPU_CUH
#define SA_GPU_CUH

#include <cuda_runtime.h>
#include <stdint.h>

struct SuffixPair {
    uint64_t key;
    int index;
};

// --- ONLY declare these for the CUDA compiler ---
#ifdef __CUDACC__
__global__ void initial_rank_kernel(const char* input, int* ranks, int n);
__global__ void build_keys_kernel(int* ranks, int n, int k, SuffixPair* pairs);
__global__ void mark_unique_ranks(SuffixPair* sorted_pairs, int* flags, int n);
__global__ void update_ranks_kernel(SuffixPair* sorted_pairs, int* scanned_flags, int* new_ranks, int n);
__global__ void extract_sa_kernel(SuffixPair* pairs, int* sa, int n);
__global__ void get_bwt_kernel(const char* input, const int* sa, char* bwt, int n);
#endif

// The wrapper function is fine for both C++ and CUDA

void run_gpu_sa_construction(char* d_input, int* d_sa, int n);
#endif

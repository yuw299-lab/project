#include <cub/cub.cuh>
#include <cuda_runtime.h>
#include <stdint.h>

// Structure to hold a key-value pair for CUB Radix Sort
struct SuffixPair {
    uint64_t key;
    int index;
};

__global__ void initial_rank_kernel(const char* input, int* ranks, int n) {
    int stride = blockDim.x * gridDim.x;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += stride) {
        ranks[i] = (unsigned char)input[i];
    }
}

// Kernel: Generate BWT from the final Suffix Array
__global__ void get_bwt_kernel(const char* input, const int* sa, char* bwt, int n) {
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n) {
        int pos = sa[i];
        if (pos == 0) {
            bwt[i] = '$'; // Sentinel for the start of the string
        } else {
            bwt[i] = input[pos - 1];
        }
    }
}


__global__ void build_keys_kernel(int* ranks, int n, int k, uint64_t* keys, int* indices) {
    int stride = blockDim.x * gridDim.x;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += stride) {
        uint64_t high = (uint64_t)ranks[i];
        uint64_t low = (i + k < n) ? (uint64_t)(ranks[i + k] + 1) : 0;
        keys[i] = (high << 32) | low;
        indices[i] = i;
    }
}
// Kernel 2: Parallel flag generation using parallel arrays
__global__ void mark_unique_ranks(uint64_t* sorted_keys, int* flags, int n) {
    int stride = blockDim.x * gridDim.x;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += stride) {
        if (i > 0) {
            flags[i] = (sorted_keys[i] != sorted_keys[i - 1]) ? 1 : 0;
        } else {
            flags[i] = 0; // Rank 0 unique
        }
    }
}

// Kernel 3: Re-assign ranks using parallel arrays

__global__ void update_ranks_kernel(int* sorted_indices, int* scanned_flags, int* new_ranks, int n) {
    int stride = blockDim.x * gridDim.x;
    for (int i = blockIdx.x * blockDim.x + threadIdx.x; i < n; i += stride) {
        int original_idx = sorted_indices[i];
        new_ranks[original_idx] = scanned_flags[i];
    }
}
void run_gpu_sa_construction(char* d_input, int* d_sa, int n) {
    int *d_ranks, *d_flags, *d_indices, *d_indices_out;
    uint64_t *d_keys, *d_keys_out;

    cudaMalloc(&d_ranks, n * sizeof(int));
    cudaMalloc(&d_flags, n * sizeof(int));
    cudaMalloc(&d_keys, n * sizeof(uint64_t));
    cudaMalloc(&d_keys_out, n * sizeof(uint64_t));
    cudaMalloc(&d_indices, n * sizeof(int));
    cudaMalloc(&d_indices_out, n * sizeof(int));

    int threads = 256;
    int blocks = 128;
    

    initial_rank_kernel<<<blocks, threads>>>(d_input, d_ranks, n);

    // 1. Properly initialize CUB scratch buffers
    void *d_temp_sort = NULL, *d_temp_scan = NULL;
    size_t temp_sort_bytes = 0, temp_scan_bytes = 0;

    cub::DeviceRadixSort::SortPairs(NULL, temp_sort_bytes, d_keys, d_keys_out, d_indices, d_indices_out, n);
    cudaMalloc(&d_temp_sort, temp_sort_bytes);
    
    cub::DeviceScan::InclusiveSum(NULL, temp_scan_bytes, d_flags, d_flags, n);
    cudaMalloc(&d_temp_scan, temp_scan_bytes);

    for (int k = 1; k < n; k <<= 1) {
        build_keys_kernel<<<blocks, threads>>>(d_ranks, n, k, d_keys, d_indices);

        cub::DeviceRadixSort::SortPairs(d_temp_sort, temp_sort_bytes, d_keys, d_keys_out, d_indices, d_indices_out, n);

        mark_unique_ranks<<<blocks, threads>>>(d_keys_out, d_flags, n);
        cub::DeviceScan::InclusiveSum(d_temp_scan, temp_scan_bytes, d_flags, d_flags, n);

        update_ranks_kernel<<<blocks, threads>>>(d_indices_out, d_flags, d_ranks, n);
    }

    // 2. Final copy: The SA is currently in d_indices_out
    cudaMemcpy(d_sa, d_indices_out, n * sizeof(int), cudaMemcpyDeviceToDevice);

    // 3. Cleanup everything
    cudaFree(d_temp_sort); cudaFree(d_temp_scan);
    cudaFree(d_ranks); cudaFree(d_flags);
    cudaFree(d_keys); cudaFree(d_keys_out);
    cudaFree(d_indices); cudaFree(d_indices_out);
}

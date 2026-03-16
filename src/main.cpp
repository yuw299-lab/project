#include <iostream>
#include <fstream>
#include <vector>
#include <string>
#include <boost/program_options.hpp>
#include "kseq.h"
#include "zlib.h"
#include "sa_gpu.cuh" 

namespace po = boost::program_options;
KSEQ_INIT(gzFile, gzread)

int main(int argc, char** argv) {
    std::string inputFasta;
    std::string outputFile;

    // 1. Parse Command Line Options
    po::options_description desc("SA Construction Options");
    desc.add_options()
        ("input,i", po::value<std::string>(&inputFasta)->required(), "Input FASTA file")
        ("output,o", po::value<std::string>(&outputFile)->required(), "Output SA .txt file")
        ("help,h", "Produce help message");

    po::variables_map vm;
    po::store(po::command_line_parser(argc, argv).options(desc).run(), vm);
    po::notify(vm);

    // 2. Preprocessing: Read and Concatenate Sequences 
    gzFile fp = gzopen(inputFasta.c_str(), "r");
    if (!fp) {
        std::cerr << "Error: Cannot open " << inputFasta << std::endl;
        return 1;
    }

    kseq_t *seq = kseq_init(fp);
    std::string masterString = "";
    
    // Concatenate all sequences into one large string 
    while (kseq_read(seq) >= 0) {
        masterString += seq->seq.s;
        masterString += "$"; // Sentinel for generalized SA
    }
    kseq_destroy(seq);
    gzclose(fp);

    size_t n = masterString.length();
    std::cout << "Total concatenated length: " << n << " characters." << std::endl;

    // 3. GPU Memory Allocation & Transfer
    int* d_sa;
    char* d_input;
    cudaMalloc(&d_input, n * sizeof(char));
    cudaMalloc(&d_sa, n * sizeof(int));

    cudaMemcpy(d_input, masterString.c_str(), n * sizeof(char), cudaMemcpyHostToDevice);

    // 4. Call Iterative SA Construction on GPU
    run_gpu_sa_construction(d_input, d_sa, n);

    // 5. Transfer Result Back to CPU 
    std::vector<int> h_sa(n);
    cudaMemcpy(h_sa.data(), d_sa, n * sizeof(int), cudaMemcpyDeviceToHost);

    // 6. Write Output to .txt file 
    std::ofstream out(outputFile);
    if (out.is_open()) {
        for (size_t i = 0; i < n; ++i) {
            out << h_sa[i] << "\n";
        }
        out.close();
        std::cout << "Suffix Array written to " << outputFile << std::endl;
    }

    // Cleanup 
    cudaFree(d_input);
    cudaFree(d_sa);

    return 0;
}

cmake_minimum_required(VERSION 3.18)

project(sa-build LANGUAGES CXX CUDA)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CUDA_STANDARD 17)
set(CMAKE_CUDA_STANDARD_REQUIRED ON)

set(FINDGPU_PATH "${CMAKE_CURRENT_SOURCE_DIR}/findgpu.cu")

if(EXISTS ${FINDGPU_PATH})
    try_run(FIND_GPU_RESULT FIND_GPU_COMPILE_RESULT
        ${CMAKE_CURRENT_BINARY_DIR}/
        ${FINDGPU_PATH}
        RUN_OUTPUT_VARIABLE GPU_ARCH_OUTPUT
    )
    if("${FIND_GPU_COMPILE_RESULT}" AND ("${FIND_GPU_RESULT}" EQUAL 0))
        message(STATUS "GPU found: ${GPU_ARCH_OUTPUT}")
        set(CMAKE_CUDA_ARCHITECTURES ${GPU_ARCH_OUTPUT})
    else()
        set(CMAKE_CUDA_ARCHITECTURES 70 75 80 86) # Trimmed for CMake 3.18 compatibility
    endif()
else()
    set(CMAKE_CUDA_ARCHITECTURES 80) # Default for A30
endif()

find_package(Boost COMPONENTS program_options REQUIRED)
find_package(ZLIB REQUIRED)
find_package(CUDAToolkit REQUIRED)

include_directories(${CMAKE_CURRENT_SOURCE_DIR} ${Boost_INCLUDE_DIRS} ${ZLIB_INCLUDE_DIRS})

set_source_files_properties(src/main.cpp PROPERTIES LANGUAGE CUDA)

add_executable(sa_builder 
    src/main.cpp 
    src/sa_gpu.cu
)

target_link_libraries(sa_builder 
    PRIVATE 
    ${Boost_LIBRARIES}
    ${ZLIB_LIBRARIES}
    ${CMAKE_DL_LIBS}
    cudart
)

target_compile_options(sa_builder PRIVATE 
    $<$<COMPILE_LANGUAGE:CXX>:-O3 -Wall -g>
    $<$<COMPILE_LANGUAGE:CUDA>:-O3 -lineinfo --use_fast_math -Xcompiler -Wall>
)

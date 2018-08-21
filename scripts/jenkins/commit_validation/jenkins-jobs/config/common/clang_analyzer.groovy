return {
CC="clang-6.0"
CXX="clang++-6.0"
CCC_CC="clang-6.0"
CCC_CXX="clang++-6.0"
SCAN_BUILD="scan-build-6.0"
PATH="$PATH:/usr/lib/llvm-6.0/bin/"
CMAKE_ARGS="-DCMAKE_C_COMPILER_EXTERNAL_TOOLCHAIN=/usr/local" +
"-DCMAKE_CXX_COMPILER_EXTERNAL_TOOLCHAIN=/usr/local"

// 2017-05-30: Ubuntu16.04 machines only have 4 CPUs - limit parallelism.
PARALLELISM=6
}

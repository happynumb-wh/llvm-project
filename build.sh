#!/bin/bash
# Install path
RISCV_DIR=$1
TOOLCHAIN_DIR=$2
INSTALL_DIR=$3
BUILD_DIR=$4

if [ -z "$RISCV_DIR" ]; then
    echo -e "\033[31m[ERROR]: RISCV_DIR is NULL, exit"
    exit 1
fi

if [ ! -d "$RISCV_DIR" ]; then
    echo -e "\033[31mError: Directory $RISCV_DIR does not exist."
    exit 2
fi

if [ -z "$TOOLCHAIN_DIR" ]; then
    echo -e "\033[31m[ERROR]: TOOLCHAIN_DIR is NULL, exit"
    exit 1
fi

if [ ! -d "$TOOLCHAIN_DIR" ]; then
    echo -e "\033[31mError: Directory $TOOLCHAIN_DIR does not exist."
    exit 2
fi

if [ -z "$INSTALL_DIR" ]; then
    echo -e "\033[31m[ERROR]: INSTALL_DIR is NULL, exit"
    exit 1
fi

if [ -z "$BUILD_DIR" ]; then
    echo -e "\033[31m[ERROR]: BUILD_DIR is NULL, exit"
    exit 1
fi

# TOOLCHAIN_DIR=/data/wanghan/riscv-gnu-toolchain

LLVM_DIR=$PWD

mkdir -p ${BUILD_DIR}

# Sysroot
SYSROOT=${RISCV_DIR}/sysroot
LINUX_TUPLE=riscv64-unknown-linux-gnu
BINUTILS_SRCDIR=${TOOLCHAIN_DIR}/binutils
XLEN=64

# environment
export RISCV=${RISCV_DIR}  # riscv toolchain path
export PATH=${RISCV_DIR}/bin:$PATH  # complier for linux

# We have the following situation:
# - sysroot directory: $(INSTALL_DIR)/sysroot
# - GCC install directory: $(INSTALL_DIR)
# However, LLVM does not allow to set a GCC install prefix
# (-DGCC_INSTALL_PREFIX) if a sysroot (-DDEFAULT_SYSROOT) is set
# (the GCC install prefix will be ignored silently).
# Without a proper sysroot path feature.h won't be found by clang.
# Without a proper GCC install directory libgcc won't be found.
# As a workaround we have to merge both paths:
mkdir -p ${BUILD_DIR}

ln -f -s ${SYSROOT} ${BUILD_DIR}/sysroot
ln -s -f ${RISCV_DIR}/lib/gcc ${SYSROOT}/lib/gcc

command='
cd ${BUILD_DIR} && \
    cmake ${LLVM_DIR}/llvm \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}\
    -DCMAKE_BUILD_TYPE=Debug \
    -DLLVM_TARGETS_TO_BUILD="RISCV" \
    -DLLVM_ENABLE_PROJECTS="clang" \
    -DLLVM_ENABLE_RUNTIMES="compiler-rt;libcxx;libcxxabi;libunwind" \
    -DLLVM_DEFAULT_TARGET_TRIPLE="${LINUX_TUPLE}" \
    -DDEFAULT_SYSROOT="../sysroot" \
    -DLLVM_RUNTIME_TARGETS=${LINUX_TUPLE} \
    -DLLVM_INSTALL_TOOLCHAIN_ONLY=On \
    -DLLVM_BINUTILS_INCDIR=${BINUTILS_SRCDIR}/include \
    -DLLVM_PARALLEL_LINK_JOBS=4 \
    -DBUILD_SHARED_LIBS=OFF && \
    cd ..
'
eval "$command"

make -C ${BUILD_DIR} -j`nproc`
make -C ${BUILD_DIR} install
cp ${BUILD_DIR}/lib/riscv${XLEN}-unknown-linux-gnu/libc++* ${SYSROOT}/lib
cp ${BUILD_DIR}/lib/LLVMgold.so  ${INSTALL_DIR}/lib
cd ${INSTALL_DIR}/bin && ln -s -f clang ${LINUX_TUPLE}-clang && ln -s -f clang++ ${LINUX_TUPLE}-clang++
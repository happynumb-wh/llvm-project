#!/bin/bash
# Install path
RISCV_DIR=/home/wanghan/riscv/riscv64-unknown-linux-gnu-no-llvm
INSTALL_DIR=/home/wanghan/riscv/riscv64-unknown-linux-gnu-no-llvm
TOOLCHAIN_DIR=/home/wanghan/riscv/riscv-gnu-toolchain

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
mkdir -p build

ln -f -s ${SYSROOT} ./build/sysroot
ln -s -f ${RISCV_DIR}/lib/gcc ${SYSROOT}/lib/gcc

command='
cd build && \
    cmake ../llvm \
    -DCMAKE_INSTALL_PREFIX=${INSTALL_DIR}\
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="RISCV" \
    -DLLVM_ENABLE_PROJECTS="clang;lld" \
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

make -C build -j`nproc`
make -C build install
cp build/lib/riscv${XLEN}-unknown-linux-gnu/libc++* ${SYSROOT}/lib
cp build/lib/LLVMgold.so  ${INSTALL_DIR}/lib
cd ${INSTALL_DIR}/bin && ln -s -f clang ${LINUX_TUPLE}-clang && ln -s -f clang++ ${LINUX_TUPLE}-clang++
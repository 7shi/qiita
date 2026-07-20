---
coediting: false
comments_count: 0
created_at: '2025-06-04T03:43:23+09:00'
id: 99d5f80a45bf72b693e9
likes_count: 4
private: false
reactions_count: 0
stocks_count: 1
tags:
- name: ROCm
  versions: []
- name: therock
  versions: []
- name: llama.cpp
  versions: []
title: TheRock で llama.cpp をビルド
updated_at: '2025-06-04T09:54:44+09:00'
url: https://qiita.com/7shi/items/99d5f80a45bf72b693e9
slide: false
---

TheRock（ROCm の開発版）で llama.cpp をビルドしてみました。API に変更があり、llvm-rc がなかったため、多少の修正が必要でした。

# 準備

TheRock をビルドします。PyTorch は不要です。

https://qiita.com/7shi/items/6a68a49629c463bc90f7

リリースフォルダ build/dist/rocm を C:\AMD\rocm にコピーします。（コピー先は特に決まりがあるわけではないため自由、コピーせずに前者を直接参照でも可）

普通のコマンドプロンプト（Visual Studio 開発者プロンプトではない）を開きます。

`HIP_PATH` を無効化（右辺は空欄）して、コピーした TheRock にパスを通します。

```bat
set HIP_PATH=
set PATH=C:\AMD\rocm\bin;C:\AMD\rocm\lib\llvm\bin;%PATH%
```

llama.cpp をクローンします。

```bat
https://github.com/ggml-org/llama.cpp.git
cd llama.cpp
```

TheRock は API に変更があるため、CUDA との対応付けを修正します。

- [ggml/src/ggml-cuda/vendors/hip.h](https://github.com/ggml-org/llama.cpp/blob/master/ggml/src/ggml-cuda/vendors/hip.h)

```diff
--- a/ggml/src/ggml-cuda/vendors/hip.h
+++ b/ggml/src/ggml-cuda/vendors/hip.h
@@ -10,9 +10,9 @@
 #include "rocblas/rocblas.h"
 #endif // __HIP_PLATFORM_AMD__

-#define CUBLAS_COMPUTE_16F HIPBLAS_R_16F
-#define CUBLAS_COMPUTE_32F HIPBLAS_R_32F
-#define CUBLAS_COMPUTE_32F_FAST_16F HIPBLAS_R_32F
+#define CUBLAS_COMPUTE_16F HIPBLAS_COMPUTE_16F
+#define CUBLAS_COMPUTE_32F HIPBLAS_COMPUTE_32F
+#define CUBLAS_COMPUTE_32F_FAST_16F HIPBLAS_COMPUTE_32F_FAST_16F
 #define CUBLAS_GEMM_DEFAULT HIPBLAS_GEMM_DEFAULT
 #define CUBLAS_GEMM_DEFAULT_TENSOR_OP HIPBLAS_GEMM_DEFAULT
 #define CUBLAS_OP_N HIPBLAS_OP_N
@@ -30,7 +30,7 @@
 #define CU_CHECK(fn) {hipError_t err = fn; if(err != hipSuccess) { GGML_ABORT("HipVMM Failure: %s\n", hipGetErrorString(err)); }}
 #define __shfl_sync(mask, var, laneMask, width) __shfl(var, laneMask, width)
 #define __shfl_xor_sync(mask, var, laneMask, width) __shfl_xor(var, laneMask, width)
-#define cublasComputeType_t hipblasDatatype_t //deprecated, new hipblasComputeType_t not in 5.6
+#define cublasComputeType_t hipblasComputeType_t //deprecated, new hipblasComputeType_t not in 5.6
 #define cublasCreate hipblasCreate
 #define cublasDestroy hipblasDestroy
 #define cublasGemmEx hipblasGemmEx
@@ -42,7 +42,7 @@
 #define cublasSgemm hipblasSgemm
 #define cublasStatus_t hipblasStatus_t
 #define cublasOperation_t hipblasOperation_t
-#define cudaDataType_t hipblasDatatype_t //deprecated, new hipblasDatatype not in 5.6
+#define cudaDataType_t hipDataType //deprecated, new hipblasDatatype not in 5.6
 #define cudaDeviceCanAccessPeer hipDeviceCanAccessPeer
 #define cudaDeviceDisablePeerAccess hipDeviceDisablePeerAccess
 #define cudaDeviceEnablePeerAccess hipDeviceEnablePeerAccess
```

:::note info
正式リリースまでに TheRock の API は変更が入る可能性があるため、この修正は llama.cpp には報告していません。
:::

この修正は hipify（CUDA コードを HIP 化するトランスレーター）を参考にしました。

- [rocm/libexec/hipify/hipify-perl](https://github.com/ROCm/HIPIFY/blob/amd-develop/bin/hipify-perl)

```perl:抜粋
    subst("CUBLAS_COMPUTE_16F", "HIPBLAS_COMPUTE_16F", "numeric_literal");
    subst("CUBLAS_COMPUTE_32F", "HIPBLAS_COMPUTE_32F", "numeric_literal");
    subst("CUBLAS_COMPUTE_32F_FAST_16F", "HIPBLAS_COMPUTE_32F_FAST_16F", "numeric_literal");
    subst("cublasComputeType_t", "rocblas_computetype", "type");
    subst("cudaDataType_t", "rocblas_datatype_", "type");
```

## ビルド

llvm-rc が足りないため、CMAKE_RC_COMPILER で HIP SDK のものを指定します。Radeon RX 7600 XT を使用しているため gfx1102 を指定します。

```bat
cmake -S . -B build -G Ninja -DAMDGPU_TARGETS=gfx1102 -DGGML_HIP=ON -DCMAKE_C_COMPILER=clang -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_BUILD_TYPE=Release -DLLAMA_CURL=OFF "-DCMAKE_RC_COMPILER=C:/Program Files/AMD/ROCm/6.2/bin/llvm-rc.exe" -DHIP_PLATFORM=amd
```

```text:ログ
-- The C compiler identification is Clang 19.0.0 with GNU-like command-line
-- The CXX compiler identification is Clang 19.0.0 with GNU-like command-line
-- Detecting C compiler ABI info
-- Detecting C compiler ABI info - done
-- Check for working C compiler: C:/AMD/rocm/lib/llvm/bin/clang.exe - skipped
-- Detecting C compile features
-- Detecting C compile features - done
-- Detecting CXX compiler ABI info
-- Detecting CXX compiler ABI info - done
-- Check for working CXX compiler: C:/AMD/rocm/lib/llvm/bin/clang++.exe - skipped
-- Detecting CXX compile features
-- Detecting CXX compile features - done
-- Found Git: C:/Program Files/Git/cmd/git.exe (found version "2.47.1.windows.1")
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD
-- Performing Test CMAKE_HAVE_LIBC_PTHREAD - Failed
-- Check if compiler accepts -pthread
-- Check if compiler accepts -pthread - no
-- Looking for pthread_create in pthreads
-- Looking for pthread_create in pthreads - not found
-- Looking for pthread_create in pthread
-- Looking for pthread_create in pthread - not found
-- Found Threads: TRUE
-- ccache found, compilation results will be cached. Disable with GGML_CCACHE=OFF.
-- CMAKE_SYSTEM_PROCESSOR: AMD64
-- GGML_SYSTEM_ARCH: x86
-- Including CPU backend
-- Could NOT find OpenMP_C (missing: OpenMP_C_FLAGS OpenMP_C_LIB_NAMES)
-- Could NOT find OpenMP_CXX (missing: OpenMP_CXX_FLAGS OpenMP_CXX_LIB_NAMES)
-- Could NOT find OpenMP (missing: OpenMP_C_FOUND OpenMP_CXX_FOUND)
CMake Warning at ggml/src/ggml-cpu/CMakeLists.txt:63 (message):
  OpenMP not found
Call Stack (most recent call first):
  ggml/src/CMakeLists.txt:310 (ggml_add_cpu_backend_variant_impl)


-- x86 detected
-- Adding CPU backend variant ggml-cpu: -march=native
CMake Warning (dev) at C:/AMD/rocm/lib/cmake/hip/hip-config-amd.cmake:70 (message):
  AMDGPU_TARGETS is deprecated.  Please use GPU_TARGETS instead.
Call Stack (most recent call first):
  C:/AMD/rocm/lib/cmake/hip/hip-config.cmake:151 (include)
  ggml/src/ggml-hip/CMakeLists.txt:39 (find_package)
This warning is for project developers.  Use -Wno-dev to suppress it.

-- Performing Test HIP_CLANG_SUPPORTS_PARALLEL_JOBS
-- Performing Test HIP_CLANG_SUPPORTS_PARALLEL_JOBS - Success
-- HIP and hipBLAS found
-- Including HIP backend
-- Configuring done (4.5s)
-- Generating done (0.2s)
-- Build files have been written to: E:/llama.cpp/build
```

ビルドします。

```bat
cmake --build build
```

これで一応ビルドが通りました。

# 比較

HIP SDK 6.2 でビルドしたものとベンチで比較してみましたが、ほぼ誤差です。

```bat
llama-bench -m Falcon3-3B-Instruct-q4_k_m.gguf
```

:::note info
Falcon3 を使ったのは以前 BitNet と比較した GGUF が手元にあったからで、特に意味はないです。
:::

https://qiita.com/7shi/items/24eb2b2b9e6149cb1d54

## TheRock

ggml_cuda_init: GGML_CUDA_FORCE_MMQ:    no
ggml_cuda_init: GGML_CUDA_FORCE_CUBLAS: no
ggml_cuda_init: found 1 ROCm devices:
  Device 0: AMD Radeon RX 7600 XT, gfx1102 (0x1102), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 1B Q4_K - Medium         |   1.86 GiB |     3.23 B | ROCm       |  99 |           pp512 |      2756.56 ± 67.24 |
| llama 1B Q4_K - Medium         |   1.86 GiB |     3.23 B | ROCm       |  99 |           tg128 |         94.95 ± 0.44 |

build: ea1431b0 (5582)

## HIP SDK 6.2

ggml_cuda_init: GGML_CUDA_FORCE_MMQ:    no
ggml_cuda_init: GGML_CUDA_FORCE_CUBLAS: no
ggml_cuda_init: found 1 ROCm devices:
  Device 0: AMD Radeon RX 7600 XT, gfx1102 (0x1102), VMM: no, Wave Size: 32
| model                          |       size |     params | backend    | ngl |            test |                  t/s |
| ------------------------------ | ---------: | ---------: | ---------- | --: | --------------: | -------------------: |
| llama 1B Q4_K - Medium         |   1.86 GiB |     3.23 B | ROCm       |  99 |           pp512 |      2755.35 ± 54.43 |
| llama 1B Q4_K - Medium         |   1.86 GiB |     3.23 B | ROCm       |  99 |           tg128 |         94.53 ± 0.42 |

build: ea1431b0 (5582)

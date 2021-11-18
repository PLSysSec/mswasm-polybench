WASI_SDK_VERSION:=12.0
WASI_SDK_TAG:=12

CC:=$(MSWASM_LLVM_BUILD)/bin/clang --target=wasm32-wasi --sysroot $(MSWASM_WASI_LIBC)/sysroot \
	-v -D_WASI_EMULATED_PROCESS_CLOCKS # -mllvm -print-before-all -mllvm -debug

POLYBENCH_ROOT:=PolyBenchC-4.2.1

AVAILABLE_BENCHMARKS:= $(patsubst %,$(POLYBENCH_ROOT)/%, \
	linear-algebra/kernels/2mm/2mm.c \
	linear-algebra/kernels/3mm/3mm.c \
	linear-algebra/kernels/atax/atax.c \
	linear-algebra/kernels/bicg/bicg.c \
	linear-algebra/kernels/doitgen/doitgen.c \
	linear-algebra/kernels/mvt/mvt.c \
	linear-algebra/blas/gemm/gemm.c \
	linear-algebra/blas/gemver/gemver.c \
	linear-algebra/blas/gesummv/gesummv.c \
	linear-algebra/blas/symm/symm.c \
	linear-algebra/blas/syr2k/syr2k.c \
	linear-algebra/blas/syrk/syrk.c \
	linear-algebra/blas/trmm/trmm.c \
	linear-algebra/solvers/cholesky/cholesky.c \
	linear-algebra/solvers/durbin/durbin.c \
	linear-algebra/solvers/gramschmidt/gramschmidt.c \
	linear-algebra/solvers/lu/lu.c \
	linear-algebra/solvers/ludcmp/ludcmp.c \
	linear-algebra/solvers/trisolv/trisolv.c \
	datamining/correlation/correlation.c \
	datamining/covariance/covariance.c \
	medley/deriche/deriche.c \
	medley/floyd-warshall/floyd-warshall.c \
	medley/nussinov/nussinov.c \
	stencils/adi/adi.c \
	stencils/fdtd-2d/fdtd-2d.c \
	stencils/heat-3d/heat-3d.c \
	stencils/jacobi-1d/jacobi-1d.c \
	stencils/jacobi-2d/jacobi-2d.c \
	stencils/seidel-2d/seidel-2d.c \
	)

WASI_BINARIES:=$(patsubst %.c,%.wasm,$(AVAILABLE_BENCHMARKS))
NATIVE_BINARIES:=$(patsubst %.c,%.native,$(AVAILABLE_BENCHMARKS))
WASI_TEXT:=$(patsubst %.c,%.wat,$(AVAILABLE_BENCHMARKS))

all: $(POLYBENCH_ROOT) wasi-sdk wasi-binaries

wasi-sdk:
	@echo '[Downloading] WASI SDK'
	@wget 'https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-$(WASI_SDK_TAG)/wasi-sdk-$(WASI_SDK_VERSION)-linux.tar.gz' 2>/dev/null
	@echo '[Extracting] WASI SDK'
	@tar xzf wasi-sdk-$(WASI_SDK_VERSION)-linux.tar.gz
	@rm wasi-sdk-$(WASI_SDK_VERSION)-linux.tar.gz
	@mv wasi-sdk-12.0 $@

wasi-binaries: benchmark-binaries $(WASI_BINARIES) $(NATIVE_BINARIES) $(WASI_TEXT)
	@mv $(WASI_BINARIES) $(NATIVE_BINARIES) $</

benchmark-binaries:
	@echo '[Directory] $@'
	@mkdir -p $@

$(WASI_BINARIES): %.wasm: %.c Makefile
	@echo "[Compiling for WASI] $(shell basename $*)"
	@$(CC) -O3 -I $(POLYBENCH_ROOT)/utilities -I $(shell dirname $<) $(POLYBENCH_ROOT)/utilities/polybench.c $< -DPOLYBENCH_TIME -o $@

$(WASI_TEXT): %.wat: %.wasm Makefile
	@echo "[Generating WASI Text] $(shell basename $*)"
	@$(MSWASM_WABT)/wasm2wat benchmark-binaries/$(shell basename $*).wasm > benchmark-binaries/$(shell basename $*).wat

$(NATIVE_BINARIES): %.native: %.c wasi-sdk Makefile
	@echo "[Compiling Native] $(shell basename $*)"
	@clang -O3 -I $(POLYBENCH_ROOT)/utilities -I $(shell dirname $<) $(POLYBENCH_ROOT)/utilities/polybench.c $< -DPOLYBENCH_TIME -lm -o $@

clean:
	@rm -rf $(WASI_BINARIES) $(NATIVE_BINARIES) benchmark-binaries *~
	@echo "[Cleaned]"

PolyBenchC-4.2.1:
	@echo '[Downloading] PolyBench/C'
	@git clone 'https://github.com/MatthiasJReisinger/PolyBenchC-4.2.1' $(POLYBENCH_ROOT)

nuke: clean
	@rm -rf wasi-sdk* $(POLYBENCH_ROOT)
	@echo "[Nuked]"

FROM ubuntu:jammy

WORKDIR /home

## Dependencies!
RUN apt-get update && apt-get install -y \
	curl \
	wget \
	git \
	python3 \
	gcc \
	g++ \
	make \
	openjdk-17-jdk \
	wabt \
	cmake \
	ninja-build \
	clang \
	time

# mx needs JAVA_HOME set
ENV JAVA_HOME="/usr/lib/jvm/java-17-openjdk-amd64"

# Get mx (for graalwasm)
RUN git clone --depth=1 https://github.com/graalvm/mx.git

# Get Rust
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

# Add Rust, mx to PATH
ENV PATH="/home/mx:/root/.cargo/bin:${PATH}"

# install benchify
RUN cargo install --git https://github.com/jaybosamiya/benchify

# clone mswasm-polybench
RUN git clone --depth=1 https://github.com/PLSysSec/mswasm-polybench

# To regenerate polybench: make MSWASM_LLVM_BUILD=/home/mswasm-llvm/llvm/build MSWASM_WASI_LIBC=/home/mswasm-wasi-libc MSWASM_WABT=/home/mswasm-wabt/mswasm-wabt/build

# clone and build mswasm-wabt
RUN git clone --depth=1 https://github.com/PLSysSec/mswasm-wabt && \
	cd mswasm-wabt && \
	git submodule update --init && \
	cmake -G Ninja -B build . && \
	cd build && \
	ninja

# clone and build rWasm
RUN git clone --branch=mswasm --depth=1 https://github.com/secure-foundations/rWasm && \
	cd rWasm && \
	cargo install --path .

# clone and build mswasm-graal
RUN git clone --depth=1 https://github.com/PLSysSec/mswasm-graal.git && \
	cd mswasm-graal/wasm/ && \
	mx --dy /truffle,/compiler build


# clone and build mswasm-llvm
RUN git clone --depth=1 https://github.com/PLSysSec/mswasm-llvm.git && \
	cd mswasm-llvm/llvm && \
	cmake -G Ninja -B build -DLLVM_ENABLE_PROJECTS="clang;lld;compiler-rt" -DLLVM_TARGETS_TO_BUILD="WebAssembly" . && \
	cd build && \
	ninja

# Get and move libclang_rt.builtins-wasm32
RUN cd mswasm-llvm/llvm/build/lib/clang/11.0.0 && \
	wget https://github.com/WebAssembly/wasi-sdk/releases/download/wasi-sdk-12/libclang_rt.builtins-wasm32-wasi-12.0.tar.gz -O builtins.tar.gz && \
	tar xf builtins.tar.gz && \
	rm builtins.tar.gz

# To use clang: /home/mswasm-llvm/llvm/build/bin/clang --target=wasm32-wasi --sysroot="/home/mswasm-wasi-libc/sysroot" <files>

# clone and build mswasm-wasi-libc
RUN git clone --depth=1 https://github.com/PLSysSec/mswasm-wasi-libc && \
	cd mswasm-wasi-libc && \
	make WASM_CC=/home/mswasm-llvm/llvm/build/bin/clang WASM_AR=/home/mswasm-llvm/llvm/build/bin/llvm-ar WASM_NM=/home/mswasm-llvm/llvm/build/bin/llvm-nm

# Build graal launcher (ms-wasm)
RUN cd mswasm-graal/vm && \
	mx --env wasm-ce build && \
	ln -s $(realpath latest_graalvm_home/bin/wasm) mswasm

# Clone and build graal launcher for wasm
RUN cd mswasm-graal && \
	git fetch --depth=1 origin mswasm/wasm-ref && \
	git branch mswasm/wasm-ref FETCH_HEAD && \
	git checkout mswasm/wasm-ref && \
	cd vm && \
	mx clean && \
	mx --env wasm-ce build && \
	ln -s $(realpath latest_graalvm_home/bin/wasm) wasm && \
	git checkout mswasm/dev

# Link tools
RUN ln -s /home/mswasm-graal/vm/mswasm /usr/bin/mswasm-graal && \
	ln -s /home/mswasm-graal/vm/wasm /usr/bin/wasm-graal && \
	ln -s /home/mswasm-llvm/llvm/build/bin/clang /usr/bin/mswasm-clang && \
	ln -s /home/mswasm-wabt/build/wasm2wat /usr/bin/mswasm2wat

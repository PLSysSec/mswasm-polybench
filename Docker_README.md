## Claims

This artifact is focused on Section 7 - Performance Evaluation. Namely,

> For the AOT compiler, we observe that enforcing spatial safety alone
> (rWasm_𝑆) has a geomean overhead of 21.4% over rWasm_Wasm; additionally
> enforcing temporal safety (rWasm_𝑆𝑇) results in an overhead of 52.2% over
> rWasm_Wasm; and, finally, further enforcing handle integrity (rWasm_𝑆𝑇𝐻)
> increases the end-to-end overhead to 197.5%. For the JIT compiler, enforcing
> spatial and temporal safety results in an overhead comparable to that of the
> AOT compiler: Graal_𝑆𝑇 imposes a 42.3% geomean overhead.

## Installation

We provide a Docker container to create an environment to run these benchmarks at
[ghcr.io/plsyssec/mswasm](https://ghcr.io/plsyssec/mswasm).  To install, install
[Docker](https://www.docker.com) and run

```shell
docker pull ghcr.io/plsyssec/mswasm:latest
```

This will download the container. The container is around 80GB. Once the
container is downloaded, you can run it with commands such as

```shell
docker run -it mswasm:latest
```

You may also use the Docker desktop interface if desired.

### Alternate Method: Installation via Dockerfile
We provide a [Dockerfile](Dockerfile) to create an environment to run these
benchmarks. To install, install [Docker](https://www.docker.com/), and in the
same directory as the Dockerfile, run

```shell
docker build -t mswasm .
```

This will build the container. This will take a reasonable amount of time
(around 45 minutes on our host machine) and require internet for cloning git
repositories. This will take more than 32GB of RAM due to compilation, and the
final image will be around 80GB. Once the container is built, you can run it
with commands such as

```shell
docker run -it mswasm:latest
```

You may also use the Docker desktop interface if desired.

### Sanity Checking

The easiest way to sanity check is to run a small benchmark using
[benchify](https://github.com/jaybosamiya/benchify).


- Install your editor of choice from `apt`, such as vim with `apt-get install
  -y vim`.
- Enter the polybench folder by running `cd mwasm-polybench`.
- Open the `benchify.toml` file.
- Uncomment the `min_runs` and `max_runs`, and as a sanity check set them to a
  low number such as 3.
- Comment out all tests except one by prefixing them with a `#`. For example,
  if I only wanted to run `2mm`, my file would look like

  ```
    [[tests]]
    name = "2mm"
    tag = "wasi"
    file = "benchmark-binaries/2mm.mswasm"
    stdout_is_timing = true

  # [[tests]]
  # name = "3mm"
  # tag = "wasi"
  # file = "benchmark-binaries/3mm.mswasm"
  # stdout_is_timing = true
  #
  # [[tests]]
  # name = "adi"
  # tag = "wasi"
  # file = "benchmark-binaries/adi.mswasm"
  # stdout_is_timing = true
  #
  # [[tests]]
   # name = "atax"
  # tag = "wasi"
  # file = "benchmark-binaries/atax.mswasm"
  # stdout_is_timing = true
  ```

- From within the `mswasm-polybench` folder, run `benchify benchify.toml`.
  Benchify will run the test and report results on stdout as well as generate
  an output directory, `./benchify-results`, containing a csv and the same
  summary as outputted from stdout.

## Evaluation Instructions

To run the benchmark suite from the paper, use the original benchify.toml file
with uncommented warmup, min_run and max_run values. The original file can be
found in the `mswasm-polybench` repo. Running the entire benchmark suite will
take a substantial amount of time. It would be advised to lower the min and max
runs.

It can be run with the same instructions as before: `cd mswasm-polybench`
`benchify benchify.toml` with output generated on stdout and in the
benchify-results folder.

To generate the graphs used in the paper, you can use the
[`generate-graphs.py`](generate-graphs.py) script. If you wish to run
the script from the container, run `git pull` from the `mswasm-polybench` repo
to pull the script, and then run `apt-get update && apt-get install
python3-matplotlib python3-pandas python3-seaborn` to install needed
dependencies. The script can then be run as

```shell
python3 <path to generate-graphs.py> <path to benchify csv data in benchify-results>
```

The script will generate 5 graphs as pdfs in the current working directory.
You can extract these graphs from the container with `docker cp`, such as

```shell
docker container ls # find the name of your container
docker cp <container name>:<path to pdf> <path on local machine to copy to>
```

Alternatively, the python script only requires the benchify csv data, so
it does not need to be run on the container. `docker cp` can be used to
retrieve the benchify csv data, then the python script can be run on
a local machine that has python3 and matplotlib, pandas, and seaborn
installed.

## Additional Artifact Description

The artifact is organized around the following repositories:

- `rWasm`: source code for our AOT compiler from MSWasm bytecode. Consists of
  rWasm with modifications to support compiling from MSWasm bytecode. This is
  available on the `PATH` of the machine: Running `rWasm -w --ms-wasm
  <path/to/mswasm/file>` will create a folder named `generated`. The
  `--ms-wasm-packed-tags`, `--ms-wasm-no-tags`, `--ms-wasm-baggy-bounds` tags
  can optionally be added to enable these Options, run `rwasm –help` for more
  info. `cd`ing into the `generated` folder and running `cargo run --release`
  will run the program.

- `mswasm-graal`: source code for our JIT compiler from MSWasm bytecode.
  Consists of GraalVM with modifications to support MSWasm Bytecode.
  `mswasm-graal` is available on the `PATH` of the container: running
  `mswasm-graal –Builtins=wasi_snapshot_preview1 <path/to/mswasm/file>` will
  run the file. There is also a version of Graal’s implementation of vanilla
  Wasm on the path - running `wasm-graal --Builtins=wasi_snapshot_preview1
  <path/to/wasm/file>` will run the Wasm program.

- `mswasm-llvm`: source code for our compiler from C to MSWasm bytecode.
  Consists of a fork of LLVM (specifically, the CHERI fork of LLVM) with
  modifications to produce MSWasm bytecode. Running
  `/home/mswasm-llvm/llvm/build/bin/clang –target=wasm32-wasi
  --sysroot=”/home/mswasm-wasi-libc/sysroot” <path/to/c/file>` will generate an
  MSWasm program from a basic C program. Due to current limitations of the
  MSWasm prototypes, clang does not correctly compile arbitrary programs. In
  particular, expect errors on most programs that use `stdout`.

- `mswasm-wasi-libc`: source code for supporting compilation of C executables
  to MSWasm bytecode. Consists of WASI-libc with modifications to support
  MSWasm bytecode.

- `mswasm-polybench`: PolybenchC benchmarks, compiled to native x86-64 code,
  Wasm bytecode, and MSWasm bytecode; along with scripts to perform
  benchmarking. Inside of the benchmark-binaries folders, there are `.mswasm`
  MS-WebAssembly binary files to be run by `rWasm` and `mswasm-graal` `.mswat`
  MS-WebAssembly text files to be read by humans `.native` binaries to run as
  native C code `.wasm` WebAssembly binaries to be run by `rWasm` and
  `wasm-graal` `.wat` WebAssembly text files to be read by humans

- `mswasm-wabt`: source code for `mswasm2wat`, a utility for converting MSWasm
  files into a readable text format. Consists of a fork of
  [WABT](https://github.com/WebAssembly/wabt) partially modified to work on
  MSWasm bytecode. `mswasm2wat` is available on the `PATH` and takes an MSWasm
  binary file as input. For more information Wasm text format, see [this
  guide](https://developer.mozilla.org/en-US/docs/WebAssembly/Understanding_the_text_format).


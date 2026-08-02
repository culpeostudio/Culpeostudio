# Install PhiloEngine

**English** · [Deutsch](../de/docs/INSTALLATION.md)

PhiloEngine is available as a self-updating desktop bundle or as a source
checkout. Choose the desktop bundle if you want to use the application. Choose
the source checkout if you plan to inspect, modify, or contribute to the code.

[← README](../README.md) · [Development](DEVELOPMENT.md) · [Troubleshooting](TROUBLESHOOTING.md)

> [!IMPORTANT]
> PhiloEngine is alpha software. Keep backups of important projects and review
> the permissions requested by an assistant before approving them.

> [!NOTE]
> Published packages contain the feature set named in their release notes. A
> development checkout can be ahead of the package you installed.

## Choose an installation path

| | Quick Install | Source checkout |
|---|---|---|
| Best for | Using PhiloEngine | Development and contribution |
| Flutter SDK | Not required | Required |
| Go toolchain | Not required | Required |
| Updates | Managed by the launcher | Safe fast-forward when started with `start.sh` |
| Local model runtimes | Installed into isolated Python environments when needed | Same |

The Quick Install archive already contains the compiled PhiloEngine frontend,
backend, and launcher. Flutter and Go are build tools and are therefore not
required to run that archive.

## Quick Install

### Supported release targets

| Operating system | Architecture | Release target | Quick Install filename ending |
|---|---:|---|---|
| Linux | x86-64 | `linux-x64` | `-linux-x64-quickinstall.tar.gz` |
| Windows | x86-64 | `windows-x64` | `-windows-x64-quickinstall.zip` |
| macOS | Apple Silicon | `macos-arm64` | `-macos-arm64-quickinstall.tar.gz` |

Intel macOS is not part of the automated release matrix. Android, iOS, and
other architectures are not distributed as desktop Quick Install bundles.

### Install the desktop bundle

1. Open the [PhiloEngine releases](https://github.com/kuchenboss/MyPhiloEngine/releases).
2. Download the archive whose name ends in
   `-<release-target>-quickinstall` followed by the archive extension for your
   system. The update archive is not a first-install package.
3. Extract the complete archive into a directory that can remain in place.
4. Start the top-level launcher:
   - Linux and macOS: `myphiloengine`
   - Windows: `myphiloengine.exe`
5. Complete the first-run authentication setup and create your account.

Always launch the top-level `myphiloengine` executable. Do not start binaries
inside `versions/` directly: those directories are managed by the updater.

On Unix-like systems, an archive tool normally preserves the executable bit.
If it does not, restore it before the first launch:

```bash
chmod +x myphiloengine
./myphiloengine
```

### Publisher verification and operating-system warnings

The release workflow does not apply Windows code signing or Apple code
signing/notarization to the desktop bundles. Windows
SmartScreen or macOS Gatekeeper can therefore show an unknown-publisher or
unverified-developer warning even when the archive came from the project.

Download only from the project's official GitHub release page, compare the
asset digest shown by GitHub or the SHA-256 value in the project's published
manifest before running a bundle, and use a per-file operating-system approval
only after checking that origin. Do not disable SmartScreen, Gatekeeper, or
equivalent platform protection system-wide. The launcher's size and SHA-256
checks verify consistency with the downloaded manifest; they do not establish
an independently authenticated publisher identity.

### Automatic updates

At startup, the launcher reads the project's published manifest, selects the
matching operating-system bundle, and verifies its declared size and SHA-256
checksum before activation. Installation is atomic: a failed download does
not replace the working version. If a newly installed bundle cannot start, the
launcher can return to the previous working bundle and avoid retrying the same
broken asset on every launch.

An offline start uses the last installed, verified bundle. Set
`PHILOENGINE_SKIP_UPDATE=1` only when you deliberately want to skip the network
check.

## Local model prerequisites

A graphics card is optional. CPU inference is supported, although it is
usually slower and may require substantial system memory. API-provider chat
does not require a local model runtime.

PhiloEngine prepares llama.cpp, Transformers, and vLLM environments on demand.
These environments are separate from the application bundle and can have
additional system requirements:

- A working Python 3 installation with `venv` and `pip` is required to create
  the isolated runtime environments.
- A current driver is required to use an NVIDIA, AMD, Vulkan, or Apple GPU.
- Some llama.cpp configurations are compiled locally. They require CMake and
  working C and C++ compilers.
- On Linux, a typical native build setup includes CMake and the distribution's
  C/C++ build tools. Vulkan builds can additionally require the Vulkan headers,
  `glslc`, and SPIR-V headers.
- The Engine's built-in privileged repair for GPU build dependencies currently
  supports Debian-based Linux only. It asks for explicit consent before using
  `pkexec` with `apt-get`. Install the required packages manually on other Linux
  distributions, macOS, and Windows.
- On macOS, install the Xcode Command Line Tools and CMake when a local build is
  required.
- On Windows, install a supported C++ build environment and CMake when no
  suitable prebuilt runtime is available.
- vLLM is selected only on compatible dedicated CUDA or ROCm hardware. Runtime
  availability differs by platform and accelerator.

The Engine shows runtime installation and model-start progress. A first local
start may download large Python packages or compile native code, so it can take
considerably longer than subsequent starts.

Model weights also require enough free disk space. The size of a model file is
not the same as its runtime memory requirement; use the Marketplace fit status
and the Engine's proposed context size as guidance.

### Optional ONNX embedding sidecar

Memory uses deterministic local hash embeddings by default. The optional ONNX
embedding backend depends on the Python/ONNX sidecar in the source tree, which
must be installed, started, and configured separately. Quick Install neither
bundles nor starts it. If the sidecar is unavailable, Memory falls back to the
hash backend.

## Build and run from source

### Toolchain

- [Go](https://go.dev/) 1.25 or newer
- [Flutter](https://flutter.dev/) 3.44 or newer with Dart 3.12 or newer
- Python 3 with `venv` and `pip`
- Git
- Native Flutter desktop dependencies for the target operating system

Clone the repository:

```bash
git clone https://github.com/kuchenboss/MyPhiloEngine.git philoengine
cd philoengine
```

### Recommended source start

On Linux, prepare the Textual-based development console once:

```bash
cd backend
python3 -m venv .venv
.venv/bin/python -m pip install textual
cd ..
```

After that, start PhiloEngine from the repository root:

```bash
cd /path/to/philoengine
./start.sh
```

`start.sh` opens the development console and manages backend and frontend in
the intended order. When the checkout is clean and on `main`, it may apply a
safe fast-forward update before starting. It refuses to overwrite local
changes, switch branches, or reconcile diverged history. Set
`PHILOENGINE_SKIP_UPDATE=1` for an intentional offline or development start.

### Manual layer-by-layer start

For diagnostics or source development on a host where `start.sh` is not used,
start the backend from its own directory so its default paths resolve to
`backend/data/`:

```bash
cd backend
go run ./cmd/server
```

In a second terminal, fetch the Flutter packages and start the desktop client:

```bash
cd frontend
flutter pub get
flutter run -d linux
```

Replace `linux` with `windows` or `macos` on the corresponding host. The
backend listens on `127.0.0.1:8080` by default. The desktop client expects that
local endpoint.

For repository layout, build commands, and verification, continue with the
[development guide](DEVELOPMENT.md).

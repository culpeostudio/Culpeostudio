# Contributing to Culpeo Studio

Thank you for your interest in contributing to **Culpeo Studio**.

This document outlines the guidelines and workflow for contributing code, documentation, hardware compatibility reports, and bug fixes to the project.

## Ground Rules

1. **Local-first focus:** Keep local inference, user memory, and project boundaries clear and protected.
2. **Design System:** All Flutter UI work must follow the **CulpeoGrid System** (`SliverGridDelegateWithMaxCrossAxisExtent`, 12px/16px padding, adaptive cell ratios).
3. **Decoupled Architecture:** Business logic, gRPC services (`culpeostudio.*.v1`), and Flutter UI components must remain strictly decoupled.
4. **Verification before PR:** Run `flutter analyze`, `flutter test`, and `go test ./...` before submitting your changes.

## Development Quick Start

```bash
# Clone the repository
git clone https://github.com/culpeostudio/Culpeostudio.git
cd Culpeostudio

# Start backend and frontend development console
./start.sh
```

## How to Submit Changes

1. **Contributor License Agreement (CLA):** All contributors must sign the [Culpeo Studio CLA](https://github.com/culpeostudio/Culpeostudio/blob/main/CLA.md).
2. **Developer Certificate of Origin (DCO):** Sign off your commits using `git commit -s`.
3. **Create a Feature Branch:** `git checkout -b feature/my-cool-feature`
4. **Commit Guidelines:** Write clear, descriptive commit messages.
5. **Open a Pull Request:** Submit your PR against the `main` branch. Provide detailed background on what changed and how it was tested.

## Reporting Security Vulnerabilities

Do **NOT** report security vulnerabilities via public GitHub issues.

Please send an encrypted email or private security report to:
`security@culpeohq.com`

See [SECURITY.md](SECURITY.md) for more details.

## License

By contributing to Culpeo Studio, you agree that your contributions will be licensed under the **GNU AGPL-3.0 License** ([LICENSE](LICENSE)).

# Contributing to Syntrix

Thank you for your interest in contributing to **Syntrix** (*Flutter Package Studio*)! We welcome contributions ranging from new package blueprint templates and audit rules to AI engine enhancements and bug fixes.

---

## 🏗️ Workspace Architecture

Syntrix is organized as a modular Dart workspace:

`
Syntrix/
├── packages/
│   ├── flutter_package_studio_core/    # Core library (DI, Blueprint engines, AI, Audits)
│   └── flutter_package_studio_cli/     # Executable CLI (commands, registry, formatters)
├── doc/                                # Architectural specs and documentation
├── tool/                               # Workspace automation scripts
├── pubspec.yaml                        # Root workspace manifest
└── README.md                           # Main repository documentation
`

---

## 🚀 Getting Started

### 1. Prerequisites

- **Dart SDK**: >=3.5.0 <4.0.0
- **Flutter SDK**: >=3.24.0
- **Git**

### 2. Setup Local Environment

`ash
# Clone your fork
git clone https://github.com/<your-username>/Syntrix.git
cd Syntrix

# Fetch all workspace dependencies
dart pub get
`

### 3. Running the CLI Locally

`ash
# Run CLI directly using Dart
dart packages/flutter_package_studio_cli/bin/fps.dart --help
`

---

## 🧪 Testing Guidelines

Syntrix enforces strict testing contracts. All PRs must pass the test suite before merging.

`ash
# Run all workspace tests
dart test packages/flutter_package_studio_core packages/flutter_package_studio_cli

# Run analysis and linter
dart analyze
`

---

## 📐 Development Workflow

1. **Fork the Repository**: Click 'Fork' on GitHub.
2. **Create a Feature Branch**:
   `ash
   git checkout -b feature/amazing-feature
   # or for bug fixes:
   git checkout -b fix/issue-description
   `
3. **Write Deterministic Code**:
   - Follow Flutter/Dart effective guidelines.
   - Maintain 100% public doc coverage on new core APIs.
   - Always write corresponding unit/integration tests in 	est/.
4. **Run Audit & Lint Verification**:
   `ash
   dart analyze
   dart test
   `
5. **Commit Your Changes**:
   Follow [Conventional Commits](https://www.conventionalcommits.org/):
   `ash
   git commit -m 'feat(templates): add clean architecture blueprint'
   git commit -m 'fix(audit): resolve path traversal false positive'
   `
6. **Push to Your Fork**:
   `ash
   git push origin feature/amazing-feature
   `
7. **Open a Pull Request**: Submit your PR targeting main with a clear description of the changes and test results.

---

## 📜 Code of Conduct

Please note that this project is governed by the [Contributor Covenant Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold this code.

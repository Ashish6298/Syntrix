  <div align="center">

  # ⬢ S Y N T R I X &nbsp;•&nbsp; Enterprise Tools & AI Engineering Studio for Flutter & Dart

  <p align="center">
    <b>A deterministic, plan-first engineering platform to scaffold, audit, document, test, certify, and publish production-grade packages.</b>
  </p>

  ```
    ⚡ Scaffolding Engine   ──►   🛡️ 5-Profile Audit   ──►   🤖 AI Code Center   ──►   📦 pub.dev Release Gate
  ```

  <br/>

  <table>
    <tr>
      <td align="center"><a href="https://dart.dev/"><img src="https://img.shields.io/badge/Dart-3.5%2B-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart SDK"/></a></td>
      <td align="center"><a href="https://flutter.dev/"><img src="https://img.shields.io/badge/Flutter-3.24%2B-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/></a></td>
      <td align="center"><a href="https://dart.dev/tools/pub/workspaces"><img src="https://img.shields.io/badge/Monorepo-Dart_Workspace-1D63ED?style=for-the-badge&logo=dart&logoColor=white" alt="Dart Workspace"/></a></td>
    </tr>
    <tr>
      <td align="center"><a href="#testing--verification"><img src="https://img.shields.io/badge/Test_Suite-400%2B_Passing-00C853?style=for-the-badge&logo=checkmarx&logoColor=white" alt="Tests"/></a></td>
      <td align="center"><a href="#security--engineering-safety"><img src="https://img.shields.io/badge/Privacy-Zero_Telemetry-7F77DD?style=for-the-badge&logo=openaccess&logoColor=white" alt="Zero Telemetry"/></a></td>
      <td align="center"><a href="LICENSE"><img src="https://img.shields.io/badge/License-MIT-F5A623?style=for-the-badge&logo=open-source-initiative&logoColor=white" alt="License"/></a></td>
    </tr>
  </table>

  <br>

  </div>

  ## 🧭 Navigation Matrix

<pre>
# Direct Jump Matrix (Click any section below to navigate)
├── 01. INTRO & BENCHMARK
│   ├── ❯ syntrix --why-syntrix    ──► <a href="#what-is-syntrix"><b>[What is Syntrix?]</b></a>
│   ├── ❯ syntrix --vs-flutter     ──► <a href="#why-syntrix-over-flutter-create"><b>[Why Syntrix over flutter create?]</b></a>
│   └── ❯ syntrix --quickstart     ──► <a href="#quick-start-guide"><b>[Quick Start Guide]</b></a>
│
├── 02. ARCHITECTURE & CORE
│   ├── ❯ syntrix --workspace      ──► <a href="#architecture-at-a-glance"><b>[Architecture at a Glance]</b></a>
│   ├── ❯ syntrix --templates      ──► <a href="#01-template--package-engineering"><b>[01. Template & Package Engineering]</b></a>
│   └── ❯ syntrix --audit-matrix   ──► <a href="#02-deterministic-audit--analysis"><b>[02. Deterministic Audit Engine]</b></a>
│
└── 03. INTELLIGENCE & TOOLING
    ├── ❯ syntrix --ai-tools       ──► <a href="#03-ai-engineering-command-center"><b>[03. AI Engineering Command Center]</b></a>
    ├── ❯ syntrix --docs-gen       ──► <a href="#04-automated-documentation-system"><b>[04. Automated Documentation System]</b></a>
    ├── ❯ syntrix --testing        ──► <a href="#05-testing-quality--release-certification"><b>[05. Testing & Certification]</b></a>
    └── ❯ syntrix --help           ──► <a href="#complete-cli-reference"><b>[Complete CLI Command Reference]</b></a>
</pre>

  <br>

  <a id="what-is-syntrix"></a>
  ## 💡 What is Syntrix?

  > **Syntrix** *(Flutter Package Studio)* is a deterministic, plan-first engineering platform designed to turn ad-hoc Flutter and Dart package development into a verifiable, enterprise-grade production pipeline.

  <br/>

  <table>
    <tr>
      <td width="50%" valign="top">
        <h4>⚡ 01. Plan-First Scaffolding</h4>
        <p>Compose multi-layer, modular package blueprints with strict YAML schema validation, token casing transforms, and atomic dry-run previews before touching disk.</p>
      </td>
      <td width="50%" valign="top">
        <h4>🛡️ 02. Deterministic 5-Profile Audit</h4>
        <p>Continuous health gates across <code>basic</code>, <code>standard</code>, <code>strict</code>, and <code>release</code> profiles to enforce pedantic lints, 100% public doc coverage, and platform matrix sanity.</p>
      </td>
    </tr>
    <tr>
      <td width="50%" valign="top">
        <h4>🤖 03. 13-Tool AI Command Center</h4>
        <p>Integrated Flutter-specialized AI engines for deep AST code reviews, root-cause failure diagnosis, 9-stage workflow plans, and cross-session memory.</p>
      </td>
      <td width="50%" valign="top">
        <h4>📚 04. Automated Docs & Diagrams</h4>
        <p>Auto-generate publication-grade API references, runnable example sandboxes, interactive Mermaid class/flow diagrams, and static web documentation sites.</p>
      </td>
    </tr>
    <tr>
      <td colspan="2" valign="top">
        <h4>🚀 05. Rigorous Release Gates & Hermetic Verification</h4>
        <p>Automated test project generation, performance & memory regression baselines, dependency conflict risk scoring, and mandatory pre-publish certification for <code>pub.dev</code>.</p>
      </td>
    </tr>
  </table>

  <br>

  <a id="why-syntrix-over-flutter-create"></a>
  ## ⚔️ Why Syntrix over `flutter create`?

  > While `flutter create --template=package` provides a bare-bones skeleton, it leaves all heavy engineering, architecture governance, documentation, and release verification to manual effort. Syntrix provides a deterministic, automated lifecycle.

  ```text
  ┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
  │  TRADITIONAL WORKFLOW (`flutter create`):                                                             │
  │                                                                                                        │
  │  flutter create ──► Manual Structure ──► Manual Docs ──► Manual Testing ──► Unverified pub.dev publish│
  │                                                                                  ▲ (High Risk)         │
  ├────────────────────────────────────────────────────────────────────────────────────────────────────────┤
  │  SYNTRIX DETERMINISTIC PIPELINE:                                                                      │
  │                                                                                                        │
  │  syntrix create ──► Blueprint Compose ──► 5-Profile Audit ──► AI Review ──► Certified pub.dev Release │
  │                                                                                  ▲ (Zero Risk)         │
  └────────────────────────────────────────────────────────────────────────────────────────────────────────┘
  ```

  ### 📊 Feature Scorecard & Benchmark

  ```text
  ┌──────────────────────────────┬──────────────────┬──────────────────┬────────────────────────┐
  │ DOMAIN                       │ `flutter create` │ MASON / VGC      │ ⬢ SYNTRIX              │
  ├──────────────────────────────┼──────────────────┼──────────────────┼────────────────────────┤
  │ 📐 Composable Blueprints     │ 🔴 1 / 10        │ 🟡 6 / 10        │ 🟢 10 / 10 (Full)      │
  │ 🛡️ Deterministic 5-Gate QA   │ 🔴 0 / 10        │ 🔴 0 / 10        │ 🟢 10 / 10 (Built-in)  │
  │ 🤖 13-Tool AI Command Center │ 🔴 0 / 10        │ 🔴 0 / 10        │ 🟢 10 / 10 (AST-Aware) │
  │ 📚 Living Docs & Mermaid     │ 🔴 1 / 10        │ 🟡 4 / 10        │ 🟢 10 / 10 (Automated) │
  │ 🚀 Pre-Publish Certification │ 🔴 0 / 10        │ 🔴 0 / 10        │ 🟢 10 / 10 (Zero-Risk) │
  └──────────────────────────────┴──────────────────┴──────────────────┴────────────────────────┘
  ```

  | Feature / Capability | `flutter create` | Mason / VeryGoodCli | **Syntrix (Flutter Package Studio)** |
  | :--- | :---: | :---: | :---: |
  | **Execution Model** | Direct write | Direct write | **✅ Plan-First (Preview before mutation)** |
  | **Audit Engine** | ❌ None | ❌ None | **✅ 5-Profile deterministic audit (`basic` to `release`)** |
  | **AI Command Center** | ❌ None | ❌ None | **✅ 13 AI tools (Review, Debug, Plan, Modify, Memory)** |
  | **Architectural Analysis** | ❌ None | ❌ None | **✅ Circular dependency detection & layer checks** |
  | **Dependency Risk Engine** | ❌ None | ❌ None | **✅ Conflict analysis & upgrade risk scoring** |
  | **Secret & Leak Scanner** | ❌ None | ❌ None | **✅ Hardcoded credential & token exposure checks** |
  | **Documentation Pipeline** | Minimal README | Static template | **✅ Mermaid diagrams, API references, Site builder** |
  | **Testing & Baselines** | 1 sample test | Standard setup | **✅ Automated test projects & regression baselines** |
  | **Release Certification** | ❌ None | ❌ None | **✅ Multi-gate release readiness certification** |
  | **CI/CD Automation** | ❌ None | ❌ None | **✅ Native `--json` output across all commands** |

  <br>

  ## Architecture at a Glance

  Syntrix is built as a modular Dart workspace targeting modern **Dart SDK `>=3.5.0 <4.0.0`** and **Flutter `>=3.24.0`**.

  ```
  Syntrix/
  ├── packages/
  │   ├── flutter_package_studio_core/    # Core architectural library (DI, Engine, AI, Audits)
  │   │   ├── lib/
  │   │   │   ├── src/
  │   │   │   │   ├── ai/                 # AI engineering, planning, review & debugging
  │   │   │   │   ├── catalog/            # Built-in template repository & manifest schemas
  │   │   │   │   ├── compatibility/      # Flutter & Dart SDK matrix compatibility engine
  │   │   │   │   ├── di/                 # IoC container & dependency injection
  │   │   │   │   ├── enterprise/         # Architecture, security & dependency analyzers
  │   │   │   │   ├── logging/            # ANSI truecolor structured logger
  │   │   │   │   ├── release_hardening/  # Audit profiles, quality gates & release certs
  │   │   │   │   ├── repository/         # GitHub & Git workflow integrations
  │   │   │   │   ├── studio_v2/          # V2 Pipeline orchestration & documentation
  │   │   │   │   ├── template/           # Template composition, tokens & customization
  │   │   │   │   ├── validation/         # Path safety, semver & parameter validators
  │   │   │   │   └── wizard/             # Interactive terminal configuration wizard
  │   │   │   └── flutter_package_studio_core.dart
  │   │   ├── test/                       # 400+ comprehensive core unit & integration tests
  │   │   └── pubspec.yaml
  │   │
  │   └── flutter_package_studio_cli/     # Native CLI application (`syntrix` and `fps`)
  │       ├── bin/
  │       │   └── fps.dart                # Executable entry point
  │       ├── lib/
  │       │   ├── src/
  │       │   │   ├── base_command.dart   # Command abstraction with DI injection
  │       │   │   ├── command_registry.dart # Stylized splash, help & dynamic registration
  │       │   │   └── commands/           # 25+ production CLI commands
  │       │   └── flutter_package_studio_cli.dart
  │       ├── test/                       # CLI integration & argument parsing tests
  │       └── pubspec.yaml
  │
  ├── pubspec.yaml                        # Dart workspace manifest
  └── LICENSE                             # MIT License
  ```

  <br>

  ## Core Capabilities

  ### 01. Template & Package Engineering

  Syntrix treats package generation as a verified mathematical pipeline.

  * **Composable Templates**: Combine multiple modular templates (e.g., `core-engine` + `ui-components` + `plugin-ffi`) into a unified workspace.
  * **Schema Validation**: Every template is backed by a strict YAML schema validating required parameters, types, and constraints before touching the disk.
  * **Smart Token Substitution**: Supports casing transformations (`pascalCase`, `camelCase`, `snake_case`, `kebab-case`, `constantCase`).
  * **Path Safety**: Strict sanitization blocks path traversal attacks (`../`) and enforces absolute path normalization.

  ```bash
  # Discover available templates
  syntrix template list

  # Inspect template requirements and options
  syntrix template inspect flutter_enterprise_package

  # Scaffold a new package interactively or via CLI
  syntrix create my_awesome_package --template=flutter_enterprise_package --org=com.myorg
  ```

  ---

  ### 02. Deterministic Audit & Analysis

  Run comprehensive automated quality and compliance checks across your package directory.

  ```
  ┌────────────────────────────────────────────────────────────────────────┐
  │                        SYNTRIX AUDIT MATRIX                            │
  ├──────────────────────┬─────────────────────────────────────────────────┤
  │ Profile: basic       │ Structure, valid pubspec, entrypoint existence │
  │ Profile: standard    │ Basic + License, README, changelog, pedantic lints│
  │ Profile: strict      │ Standard + 100% public API docs, example folder │
  │ Profile: release     │ Strict + Zero warnings, clean git, passing tests│
  └──────────────────────┴─────────────────────────────────────────────────┘
  ```

  * **`syntrix audit` / `syntrix --audit`**: Executes multi-gate rule validation with actionable terminal reports and exit codes.
  * **`syntrix architecture`**: Analyzes imports to detect circular dependencies and layering violations.
  * **`syntrix deps`**: Evaluates outdated dependencies, version locks, and breaking upgrade risks.
  * **`syntrix security`**: Scans package source for hardcoded secrets, private tokens, and unsafe API usages.

  ```bash
  # Run standard audit
  syntrix --audit

  # Run release-level strict audit with JSON report output
  syntrix audit --profile=release --json > audit-report.json
  ```

  ---

  ### 03. AI Engineering Command Center

  Syntrix embeds **13 AI-powered engineering tools** directly into your terminal, designed specifically for Dart and Flutter semantics.

  ```
                          ┌─────────────────────────┐
                          │   SYNTRIX AI ENGINE     │
                          └────────────┬────────────┘
                                        │
        ┌──────────────┬───────────────┼───────────────┬──────────────┐
        ↓              ↓               ↓               ↓              ↓
    syntrix review  syntrix debug   syntrix plan    syntrix modify  syntrix memory
    Code quality &  Root cause &    9-stage task    Safe AST-aware  Session state &
    lint analysis   fix proposal    decomposition   code transforms context cache
  ```

  * **`syntrix review`**: Deep semantic code review against Flutter best practices, performance bottlenecks, and memory leaks.
  * **`syntrix debug`**: Evaluates stack traces, error outputs, and source context to identify root causes with tiered certainty.
  * **`syntrix plan`**: Converts natural language feature requirements into structured 9-stage engineering execution plans.
  * **`syntrix modify`**: Previews and applies safe, AST-grounded code transformations.
  * **`syntrix memory`**: Maintains engineering session context and cross-session knowledge caches.

  ---

  ### 04. Automated Documentation System

  Produce publication-grade documentation automatically without manual drafting.

  * **API Reference Generator**: Parses Dart docstrings and builds searchable reference documents.
  * **Mermaid Diagram Generator**: Reverse-engineers classes, state machines, and dependency graphs into interactive Mermaid syntax.
  * **Code Example Builder**: Validates and formats working runnable examples directly from your test suite.
  * **Static Site Builder**: Assembles markdown, diagrams, and API docs into an exportable static web documentation portal.

  ```bash
  # Generate architecture documentation and Mermaid diagrams
  syntrix docs --architecture --diagrams

  # Build a complete static documentation site
  syntrix docs --site --output=build/docs
  ```

  ---

  ### 05. Testing, Quality & Release Certification

  * **Isolated Test Environments**: Generates hermetic test sandboxes without polluting the main workspace.
  * **Regression Baseline Tracking**: Compares current test execution times and memory allocations against historical baselines.
  * **Release Readiness Gate**: Evaluates package compliance against pub.dev score criteria, changelog consistency, and semantic version bumps before triggering `syntrix publish`.

  ---

  ## Complete CLI Reference

  Syntrix CLI commands are structured into 5 logical categories.

  ```
    ⬢  S Y N T R I X
      Enterprise-grade tools & AI engineering for Flutter & Dart packages

    Usage
      syntrix <command> [arguments]
  ```

  ### Global Options
  | Flag | Abbreviation | Description |
  | :--- | :---: | :--- |
  | `--help` | `-h` | Display usage information and available commands |
  | `--version` | `-V` | Print current Syntrix CLI version |
  | `--verbose` | `-v` | Enable verbose debug logging output |
  | `--audit` | | Fast-action flag to audit package structure in current directory |

  ### 1. Package & Templates
  | Command | Description |
  | :--- | :--- |
  | `syntrix create <name>` | Scaffold a new production-ready Flutter/Dart package |
  | `syntrix template list` | Discover and list installed and remote templates |
  | `syntrix template inspect <id>` | Inspect metadata, inputs, and structure of a template |
  | `syntrix template compose` | Combine multiple templates into a unified blueprint |
  | `syntrix plugin` | Manage Syntrix CLI plugins and extensions |
  | `syntrix registry` | Manage remote template registries for the marketplace |

  ### 2. AI Engineering
  | Command | Description |
  | :--- | :--- |
  | `syntrix ai` | Unified AI command center for review, debug, test, and plan |
  | `syntrix review` | Generate structured AI code review findings for your package |
  | `syntrix debug` | Diagnose defects and exceptions with tiered certainty causes |
  | `syntrix plan` | Convert requests into structured 9-stage implementation plans |
  | `syntrix modify` | Propose, preview, and apply AI-assisted code modifications |
  | `syntrix doc` | Generate grounded documentation or verify doc consistency |
  | `syntrix docs` | Generate API documentation, diagrams, and static site assets |
  | `syntrix memory` | Query and manage persistent engineering session memory |
  | `syntrix project` | Inspect and analyze project workspace context |

  ### 3. Analysis & Audit
  | Command | Description |
  | :--- | :--- |
  | `syntrix audit` | Audit package structure, standards, and compatibility |
  | `syntrix architecture` | Analyze circular dependencies and layering violations |
  | `syntrix deps` | Analyze dependency versions, conflicts, and upgrade risk |
  | `syntrix security` | Scan for hardcoded secret exposures and credential handling risks |
  | `syntrix test` | Analyze coverage gaps and generate candidate test proposals |
  | `syntrix release-readiness`| Evaluate release candidate readiness across all quality gates |

  ### 4. Release & Publishing
  | Command | Description |
  | :--- | :--- |
  | `syntrix release` | Orchestrate semantic versioning, changelogs, and release tags |
  | `syntrix publish` | Validate and publish the package to `pub.dev` or private servers |

  <br>

  ## Quick Start Guide

  ### 1. Installation

  Activate Syntrix globally from your workspace or pub.dev:

  ```bash
  dart pub global activate --source path ./packages/flutter_package_studio_cli
  ```

  Verify installation:

  ```bash
  syntrix --version
  ```

  ### 2. Launch Welcome Hub

  Running `syntrix` without arguments opens the clean interactive dashboard:

  ```text
                  ⬢  S Y N T R I X

      Enterprise tools & AI studio for Flutter and Dart
      ──────────────────────────────────────────────────

      Quick Actions:

      • create    scaffold a new production-ready package
      • --audit   run automated audit checks
      • template  manage templates
      • plugin    manage plugins
      • --help    explore all commands

      ──────────────────────────────────────────────────
      v1.0.0    dart 3.5.0    flutter 3.24.0
  ```

  ### 3. Scaffold Your First Enterprise Package

  Create a new package with the interactive wizard:

  ```bash
  syntrix create my_package
  ```

  Or specify options directly:

  ```bash
  syntrix create my_package --template=flutter_enterprise_package --org=com.syntrix --description="High-performance reactive caching layer for Flutter."
  ```

  ### 4. Run Package Health Audit

  Navigate to package directory:

  ```bash
  cd my_package
  ```

  Run automated package audit:

  ```bash
  syntrix --audit
  ```

  <br>

  ## 🛡️ Security & Engineering Safety

  > Syntrix is engineered with defensive-by-default architecture, strict path sanitization, and a zero-telemetry privacy guarantee.

  <br/>

  <table>
    <tr>
      <td width="50%" valign="top">
        <h4>🔍 Plan-First Dry Run Previews</h4>
        <p>Destructive mutations always require explicit consent. Default operations execute in safe preview mode with zero unprompted disk writes.</p>
      </td>
      <td width="50%" valign="top">
        <h4>🚫 Path Traversal & Injection Guards</h4>
        <p>Strict input sanitization normalizes absolute filepaths and neutralizes relative escaping attempts (e.g. <code>../</code> attacks).</p>
      </td>
    </tr>
    <tr>
      <td width="50%" valign="top">
        <h4>🔒 100% Private & Zero Telemetry</h4>
        <p>Zero telemetry, analytics, or background tracking. Codebases, session memories, and API keys remain 100% local on your machine.</p>
      </td>
      <td width="50%" valign="top">
        <h4>🧪 Hermetic Workspace Execution</h4>
        <p>Testing and audit sandboxes operate in isolated temporary workspaces without altering ambient environment variables or global SDK configs.</p>
      </td>
    </tr>
  </table>

  <br>

  ## 🧪 Testing & Quality Verification

  > Every layer of Syntrix is verified by a deterministic automated test suite covering unit contracts, AST transformers, CLI runners, and AI prompt synthesizers.

  <br/>

  <table>
    <tr>
      <td width="50%" valign="top">
        <h4>📦 <code>flutter_package_studio_core</code> (350+ Tests)</h4>
        <ul>
          <li><b>DI & IoC Container</b>: Transient & singleton dependency resolution</li>
          <li><b>Template Engine</b>: Token substitution & YAML schema validation</li>
          <li><b>Audit Profiles</b>: Multi-gate deterministic compliance engines</li>
          <li><b>AI Subsystems</b>: Grounded AST review, debug & plan generators</li>
        </ul>
      </td>
      <td width="50%" valign="top">
        <h4>💻 <code>flutter_package_studio_cli</code> (50+ Tests)</h4>
        <ul>
          <li><b>Command Runner</b>: Option parsing & custom help formatters</li>
          <li><b>E2E Lifecycle</b>: Scaffolding, dry-run previews & disk mutations</li>
          <li><b>Exit Codes</b>: Deterministic status codes across all gates</li>
          <li><b>JSON Schema</b>: Strict machine-readable output verification</li>
        </ul>
      </td>
    </tr>
  </table>

  ### Run All Workspace Tests

  ```bash
  dart test packages/flutter_package_studio_core packages/flutter_package_studio_cli
  ```

  <br>

  ## 🤝 Contributing to Syntrix

  > Contributions of all shapes and sizes are welcome! Whether you are designing new package templates, writing custom audit rules, or adding specialized AI capabilities.

  <br/>

  <table>
    <tr>
      <td width="50%" valign="top">
        <h4>1. Fork & Branch</h4>
        <p>Fork the repository and create your isolated feature branch:</p>
        <code>git checkout -b feature/amazing-feature</code>
      </td>
      <td width="50%" valign="top">
        <h4>2. Verify All Tests</h4>
        <p>Run the full automated test suite across all workspace packages:</p>
        <code>dart test packages/flutter_package_studio_core packages/flutter_package_studio_cli</code>
      </td>
    </tr>
    <tr>
      <td width="50%" valign="top">
        <h4>3. Commit Clean Changes</h4>
        <p>Follow standard conventional commit messages:</p>
        <code>git commit -m 'feat: add amazing new feature'</code>
      </td>
      <td width="50%" valign="top">
        <h4>4. Open Pull Request</h4>
        <p>Push your branch to GitHub and submit a PR for review:</p>
        <code>git push origin feature/amazing-feature</code>
      </td>
    </tr>
  </table>

  <br>

  ## 📄 License

  ```text
  ┌────────────────────────────────────────────────────────────────────────────────────────┐
  │  LICENSE: MIT                                                                          │
  │  Copyright (c) 2026 Syntrix Authors. Free for personal and commercial usage.           │
  │  See LICENSE file in root directory for full legal text.                               │
  └────────────────────────────────────────────────────────────────────────────────────────┘
  ```

<br/>

<div align="center">

<table style="margin: 0 auto; border: 1px solid rgba(255,255,255,0.1); border-radius: 12px; text-align: center;">
  <tr>
    <td align="center" style="text-align: center; padding: 24px 32px;" width="560">
      <div align="center">
        <a href="https://github.com/Ashish6298">
          <img src="https://github.com/Ashish6298.png" width="80" height="80" style="border-radius: 50%; border: 2px solid #555; display: inline-block;" alt="Ashish Goswami" />
        </a>
      </div>
      <br/>
      <div align="center">
        <b>Crafted with ❤️ by <a href="https://github.com/Ashish6298">Ashish Goswami</a></b>
      </div>
      <br/>
      <div align="center">
        <sub><i>"Deterministic, resilient tools so Flutter developers can focus on creating extraordinary experiences."</i></sub>
      </div>
      <br/>
      <div align="center">
        <a href="https://github.com/Ashish6298" title="GitHub Profile"><img src="https://api.iconify.design/lucide:github.svg?color=%23888888" width="18" height="18" alt="GitHub" /></a>&nbsp;&nbsp;&nbsp;&nbsp;
        <a href="https://github.com/Ashish6298/Syntrix" title="Star Repository"><img src="https://api.iconify.design/lucide:star.svg?color=%23e3b341" width="18" height="18" alt="Star" /></a>&nbsp;&nbsp;&nbsp;&nbsp;
        <a href="https://github.com/Ashish6298/Syntrix/issues" title="Open Issues"><img src="https://api.iconify.design/lucide:circle-dot.svg?color=%23888888" width="18" height="18" alt="Issues" /></a>&nbsp;&nbsp;&nbsp;&nbsp;
        <a href="https://github.com/Ashish6298/Syntrix/pulls" title="Pull Requests"><img src="https://api.iconify.design/lucide:git-pull-request.svg?color=%23888888" width="18" height="18" alt="Pull Requests" /></a>
      </div>
    </td>
  </tr>
</table>

<br/>

<sub>© 2026 <b>Syntrix</b> • Enterprise Package Studio for Dart & Flutter. All rights reserved.</sub>

</div>




# Flutter Package Studio

> **A deterministic, plan-first engineering platform for discovering, composing, customizing, generating, documenting, testing, validating, certifying, and publishing Flutter/Dart packages.**

[![Dart](https://img.shields.io/badge/Dart-3.5%2B-0175C2?logo=dart\&logoColor=white)](https://dart.dev/)
[![Flutter](https://img.shields.io/badge/Flutter-Package%20Engineering-02569B?logo=flutter\&logoColor=white)](https://flutter.dev/)
[![Monorepo](https://img.shields.io/badge/Architecture-Dart%20Workspace-blue)](https://dart.dev/tools/pub/workspaces)
[![Tests](https://img.shields.io/badge/Latest%20reported%20tests-691%20passing-success)](#testing)
[![Status](https://img.shields.io/badge/Project-Active%20Development-orange)](#project-status)

---

## Table of Contents

* [Overview](#overview)
* [What is Flutter Package Studio?](#what-is-flutter-package-studio)
* [Why Flutter Package Studio?](#why-flutter-package-studio)
* [Core Philosophy](#core-philosophy)
* [Architecture at a Glance](#architecture-at-a-glance)
* [Repository Structure](#repository-structure)
* [Workspace](#workspace)
* [Core Package](#core-package)
* [CLI Package](#cli-package)
* [Template Engineering](#template-engineering)
* [Template Discovery](#template-discovery)
* [Template Inspection](#template-inspection)
* [Compatibility Evaluation](#compatibility-evaluation)
* [Template Composition](#template-composition)
* [Template Customization](#template-customization)
* [Documentation System](#documentation-system)
* [API Documentation Generator](#api-documentation-generator)
* [Architecture Documentation](#architecture-documentation)
* [Mermaid Diagram Generator](#mermaid-diagram-generator)
* [Code Example Generator](#code-example-generator)
* [Screenshot Manager](#screenshot-manager)
* [GIF Pipeline](#gif-pipeline)
* [Static Documentation Website](#static-documentation-website)
* [Testing Infrastructure](#testing-infrastructure)
* [Test Project Generator](#test-project-generator)
* [Regression Testing Engine](#regression-testing-engine)
* [Test Quality & Certification](#test-quality--certification)
* [Unified Testing Workflow](#unified-testing-workflow)
* [Plan-First Execution Model](#plan-first-execution-model)
* [Preview and Write Safety](#preview-and-write-safety)
* [Determinism](#determinism)
* [Security and Path Safety](#security-and-path-safety)
* [CLI Overview](#cli-overview)
* [Installation](#installation)
* [Development Setup](#development-setup)
* [Running the CLI](#running-the-cli)
* [Template Commands](#template-commands)
* [Documentation Commands](#documentation-commands)
* [Testing Commands](#testing-commands)
* [JSON Output](#json-output)
* [Reports](#reports)
* [Testing and Verification](#testing-and-verification)
* [Quality Gates](#quality-gates)
* [Error Handling](#error-handling)
* [Dependency Model](#dependency-model)
* [Design Principles](#design-principles)
* [Milestone Progression](#milestone-progression)
* [Current Project State](#current-project-state)
* [Known Limitations](#known-limitations)
* [Future Direction](#future-direction)
* [Contributing](#contributing)
* [License](#license)
* [Repository](#repository)

---

# Overview

**Flutter Package Studio (FPS)** is a package-engineering toolkit implemented as a Dart workspace.

The project is designed to move Flutter/Dart package development away from ad-hoc file manipulation and isolated scripts toward a structured engineering pipeline in which package operations can be:

* discovered,
* inspected,
* planned,
* validated,
* composed,
* customized,
* generated,
* documented,
* tested,
* compared against previous evidence,
* certified,
* and eventually automated through CI/CD.

The current repository is organized as a two-package workspace:

```text
Syntrix/
├── packages/
│   ├── flutter_package_studio_core/
│   └── flutter_package_studio_cli/
│
├── report/
│   ├── PHASE_3.2_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.3_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.4_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.5_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.6_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.7_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_3.8_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_4.1_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_4.10_IMPLEMENTATION_REPORT.txt
│   ├── PHASE_4.11_IMPLEMENTATION_REPORT.txt
│   └── PHASE_4.12_IMPLEMENTATION_REPORT.txt
│
├── pubspec.yaml
└── .gitignore
```

The root `pubspec.yaml` defines a Dart workspace using Dart SDK `>=3.5.0 <4.0.0` and includes both packages.

---

# What is Flutter Package Studio?

Flutter Package Studio is intended to behave as an **engineering system around Flutter/Dart package creation**, rather than simply being a package generator.

Its responsibilities span several layers.

### Package engineering

FPS provides infrastructure for:

* package templates,
* template metadata,
* template discovery,
* version resolution,
* composition,
* customization,
* compatibility checking,
* package generation,
* release-oriented inspection.

### Documentation engineering

The system can build documentation artifacts including:

* README documentation,
* API reference documentation,
* architecture documentation,
* Mermaid diagrams,
* code examples,
* screenshots,
* GIF galleries,
* static documentation websites.

### Test engineering

The testing subsystem extends from creating isolated test projects to:

* test execution,
* test profiling,
* coverage evidence,
* compatibility evidence,
* regression comparison,
* certification,
* unified testing workflows.

### Engineering safety

The project consistently follows several important safety rules:

* preview before mutation,
* explicit write operations,
* path traversal rejection,
* absolute path validation,
* input sanitization,
* deterministic ordering,
* deterministic generated output,
* structured exceptions,
* machine-readable JSON output.

These principles appear repeatedly across the implementation reports.

---

# Why Flutter Package Studio?

Traditional package creation often mixes several unrelated concerns:

```text
Template
   ↓
Manual editing
   ↓
Manual documentation
   ↓
Manual testing
   ↓
Manual compatibility checking
   ↓
Manual release validation
```

FPS is designed around a more structured lifecycle:

```text
                    ┌────────────────────┐
                    │ Template Discovery │
                    └──────────┬─────────┘
                               ↓
                    ┌────────────────────┐
                    │ Template Inspection│
                    └──────────┬─────────┘
                               ↓
                    ┌────────────────────┐
                    │ Compatibility      │
                    │ Evaluation         │
                    └──────────┬─────────┘
                               ↓
                    ┌────────────────────┐
                    │ Composition        │
                    └──────────┬─────────┘
                               ↓
                    ┌────────────────────┐
                    │ Customization      │
                    └──────────┬─────────┘
                               ↓
                    ┌────────────────────┐
                    │ Package Generation │
                    └──────────┬─────────┘
                               ↓
              ┌────────────────┴────────────────┐
              ↓                                 ↓
      Documentation                         Testing
              ↓                                 ↓
      ┌───────────────┐               ┌──────────────────┐
      │ API Docs      │               │ Test Project     │
      │ Architecture  │               │ Test Execution   │
      │ Mermaid       │               │ Regression       │
      │ Examples      │               │ Certification    │
      │ Screenshots   │               │ Unified Workflow │
      │ GIFs          │               └──────────────────┘
      │ Website       │
      └───────────────┘
```

The project therefore treats package development as a **repeatable pipeline** instead of a collection of independent utilities.

---

# Core Philosophy

## 1. Plan first

Operations should be represented as plans before they are materialized.

A typical subsystem follows the pattern:

```text
Input
  ↓
Validation
  ↓
Plan
  ↓
Preview
  ↓
Optional Write / Execute
  ↓
Result
```

This is visible throughout the generated documentation, diagram, example, testing, regression, certification, and workflow subsystems.

---

## 2. Preview before mutation

Preview mode is deliberately safe.

The implementation reports repeatedly verify that:

> default preview mode performs zero disk writes.

Actual filesystem mutation requires an explicit write operation.

This behavior is implemented across documentation and testing subsystems.

---

## 3. Deterministic output

Identical input should produce identical output.

This applies to:

* generated Markdown,
* Mermaid source,
* Dart examples,
* screenshot galleries,
* GIF galleries,
* websites,
* test-project file maps,
* regression reports,
* certification reports,
* unified workflow results.

The phase reports explicitly verify byte-identical output for identical input across these subsystems.

---

## 4. Evidence over assumptions

The testing/certification architecture is explicitly designed not to fabricate evidence.

Certification decisions are based on structured:

* test execution evidence,
* coverage evidence,
* compatibility evidence,
* regression evidence.

This principle is especially important in Phase 4.11 and Phase 4.12.

---

## 5. Controlled side effects

The system separates:

```text
Planning
```

from:

```text
Writing / Execution
```

This makes the CLI safer for automation and allows consumers to inspect what FPS intends to do before allowing filesystem changes or test execution.

---

# Architecture at a Glance

The repository is split into two primary packages.

```text
Syntrix
│
├── flutter_package_studio_core
│   │
│   ├── Foundation
│   ├── Configuration
│   ├── Logging
│   ├── Validation
│   ├── Errors
│   ├── Template system
│   ├── Compatibility
│   ├── Composition
│   ├── Customization
│   ├── Documentation
│   ├── Testing
│   └── Release-oriented infrastructure
│
└── flutter_package_studio_cli
    │
    ├── CLI bootstrap
    ├── Command registry
    ├── Template commands
    ├── Documentation commands
    ├── Testing commands
    ├── Plugin commands
    └── Registry commands
```

The CLI bootstrap creates a dependency container, registers platform/file/terminal utilities, configures logging, loads configuration, registers commands, and finally executes the command registry.

---

# Repository Structure

```text
Syntrix/
│
├── packages/
│   │
│   ├── flutter_package_studio_core/
│   │   ├── doc/
│   │   │   └── api/
│   │   ├── lib/
│   │   │   ├── src/
│   │   │   └── flutter_package_studio_core.dart
│   │   ├── test/
│   │   └── pubspec.yaml
│   │
│   └── flutter_package_studio_cli/
│       ├── bin/
│       │   └── fps.dart
│       ├── doc/
│       │   └── api/
│       ├── lib/
│       ├── test/
│       └── pubspec.yaml
│
├── report/
│   └── implementation reports
│
├── pubspec.yaml
└── .gitignore
```

The core package currently contains `doc/api`, `lib`, `test`, and its package manifest; the CLI contains `bin`, `doc/api`, `lib`, `test`, and its package manifest.

---

# Workspace

The root workspace is:

```yaml
name: flutter_package_studio_workspace
version: 1.0.0

environment:
  sdk: '>=3.5.0 <4.0.0'

workspace:
  - packages/flutter_package_studio_core
  - packages/flutter_package_studio_cli
```

This means dependency resolution and development can be performed from the repository root.

---

# Core Package

## `flutter_package_studio_core`

The core package is the architectural foundation of FPS.

Its declared purpose is to provide:

* dependency injection,
* logging,
* configuration,
* validation,
* utilities,
* error handling,
* and the larger package-engineering subsystems.

It targets Dart `>=3.5.0 <4.0.0`.

Current direct dependencies include:

* `path`
* `yaml`
* `meta`

Development dependencies include:

* `test`
* `mocktail`

The package is workspace-resolved and is not currently published directly.

---

# CLI Package

## `flutter_package_studio_cli`

The CLI provides the user-facing command interface.

Its declared purpose is:

> CLI application for Flutter Package Studio.

It targets the same Dart SDK range:

```text
>=3.5.0 <4.0.0
```

Its primary runtime dependencies are:

* `args`
* `flutter_package_studio_core`

and its development dependencies include:

* `test`
* `mocktail`.

---

# CLI Bootstrap

The executable entry point is:

```text
packages/flutter_package_studio_cli/bin/fps.dart
```

The bootstrap performs five important operations:

1. Creates the dependency container.
2. Registers platform, file, and terminal utilities.
3. Configures the root logger.
4. Loads FPS configuration.
5. Registers the command families.
6. Executes the command registry.

The registered top-level command families currently include:

```text
create
audit
release
docs
publish
template
plugin
registry
```

---

# Template Engineering

Templates are one of the central abstractions of FPS.

A template contains structured metadata describing things such as:

* identity,
* version,
* display name,
* project type,
* category,
* maturity,
* publisher,
* description,
* Dart SDK requirements,
* Flutter SDK requirements,
* supported platforms,
* capabilities,
* tags,
* files,
* directories,
* dependencies.

The CLI can expose this metadata directly through template inspection commands.

---

# Template Discovery

FPS provides a template catalog and discovery layer.

Templates can be queried by:

* project type,
* category,
* name,
* description,
* tags,
* sorting criteria,
* result limit.

Supported project types exposed by the CLI include:

```text
flutter_package
dart_package
plugin
```

Template categories include:

```text
builtin
community
local
```

Sorting supports:

```text
name
version
downloads
rating
recent
```

The template catalog can also return JSON for automation.

Example:

```bash
fps template list
```

Filtered:

```bash
fps template list \
  --project-type flutter_package \
  --category builtin
```

JSON:

```bash
fps template list --json
```

---

# Template Search

Free-text template search is available through:

```bash
fps template search "flutter widget"
```

Search can also be narrowed by project type and limited in size.

JSON output is supported:

```bash
fps template search "package" --json
```

The command searches template metadata including name, description, and tags.

---

# Template Inspection

Detailed information can be requested with:

```bash
fps template info <template-id>
```

A specific version can be inspected:

```bash
fps template info <template-id> --version <version>
```

JSON:

```bash
fps template info <template-id> --json
```

The inspection output includes:

* ID,
* version,
* display name,
* category,
* maturity,
* project type,
* publisher,
* description,
* minimum Dart SDK,
* minimum Flutter SDK,
* platforms,
* capabilities,
* tags,
* file count,
* directories,
* template dependencies.

---

# Compatibility Evaluation

FPS contains a compatibility evaluator capable of assessing templates against an SDK/environment model.

Compatibility dimensions include:

* Dart version,
* Flutter version,
* operating system,
* compatibility policy.

Supported policies include:

```text
permissive
standard
strict
release
```

Example:

```bash
fps template check <template-id>
```

A mocked environment can be supplied:

```bash
fps template check <template-id> \
  --dart-version 3.5.0 \
  --flutter-version 3.22.0 \
  --os linux \
  --policy standard
```

JSON output:

```bash
fps template check <template-id> --json
```

The command returns compatibility status and structured issues containing severity, axis, message, constraint, and actual environment value.

---

# Template Composition

Templates can be composed from:

```text
Base Template
      +
Feature Extensions
      ↓
Composition Plan
```

The CLI supports:

```bash
fps template compose <base-id> [extension-ids...]
```

Composition supports conflict policies:

```text
fail
override
skip
```

and compatibility policies:

```text
permissive
standard
strict
release
```

The composition engine provides:

* layer ordering,
* file count,
* override count,
* skipped-file count,
* conflict information,
* file provenance.

Example:

```bash
fps template compose flutter_package auth_extension
```

JSON:

```bash
fps template compose flutter_package auth_extension --json
```

The implementation uses compatibility-aware resolution and tracks which template contributed each resulting file.

---

# Template Customization

FPS also provides customization planning.

The CLI supports:

```bash
fps template customize <template-id>
```

Customization can specify:

* template version,
* preset,
* custom variables,
* compatibility policy.

Example:

```bash
fps template customize flutter_package \
  --preset production \
  --var enable_auth=true
```

Multiple variables can be supplied:

```bash
fps template customize flutter_package \
  --var enable_auth=true \
  --var enable_logging=true
```

The customization system is designed around producing a plan rather than immediately mutating files.

---

# Documentation System

Milestone 3 significantly expands FPS into a documentation-generation platform.

The documentation pipeline includes:

```text
README
  │
  ├── API Documentation
  ├── Architecture Documentation
  ├── Mermaid Diagrams
  ├── Code Examples
  ├── Screenshots
  ├── GIFs
  └── Static Documentation Website
```

The implementation reports show each subsystem being added independently and then aggregated by the static website generator.

---

# API Documentation Generator

Phase 3.2 introduced the API Documentation Generator.

It can extract public Dart API symbols including:

* classes,
* functions,
* enums,
* typedefs,
* extensions,
* methods,
* properties.

The extractor also captures:

* names,
* kinds,
* signatures,
* documentation comments,
* deprecation information,
* parameters,
* nested members.

Private symbols beginning with `_` are excluded.

The resulting API documentation is rendered as deterministic Markdown.

CLI:

```bash
fps template api-docs <template-id>
```

Options include:

```text
--version
--output
--write
--json
```

The subsystem deliberately defers complete Dart AST resolution for complex cross-library references to native `dartdoc` integration.

---

# Architecture Documentation

Phase 3.3 introduced architecture documentation.

The architecture model represents:

### Layers

Examples include:

```text
cli
core
documentation
```

### Components

The canonical architecture registry contains components such as:

```text
TemplateDiscoveryService
TemplateResolver
CompositionEngine
CustomizationEngine
QualityEngine
HookEngine
CertificationEngine
TestingFramework
MigrationEngine
ReadmeGenerator
ApiDocGenerator
```

### Architectural decisions

The system also represents architectural decision records.

Generated documentation is Markdown and can contain text-based Mermaid diagrams.

CLI:

```bash
fps template architecture
```

with:

```text
--output
--write
--json
```

---

# Mermaid Diagram Generator

Phase 3.4 introduced deterministic Mermaid generation.

Supported diagram types include:

```text
flowchartTD
flowchartLR
sequenceDiagram
```

The subsystem provides:

* nodes,
* edges,
* diagram options,
* plans,
* results,
* validation.

Validation includes:

* node ID syntax,
* duplicate node detection,
* missing edge target detection.

CLI:

```bash
fps template mermaid
```

Supported options include:

```text
--type flowchart
--type sequence
--output
--write
--json
```

Node labels are sanitized and generated diagrams are deterministic.

---

# Code Example Generator

Phase 3.5 introduced automatic Dart/Flutter example generation.

Supported example categories include:

```text
basicUsage
initialization
configuration
fullExample
```

A generated example can contain:

* imports,
* setup,
* usage,
* explanatory comments,
* complete minimal Flutter usage.

CLI:

```bash
fps template examples <template-id>
```

Example types can be selected through:

```text
--type basic
--type init
--type config
--type full
```

Additional options include:

```text
--version
--output
--write
--json
```

The generated Dart source is deterministic and sanitized.

---

# Screenshot Manager

Phase 3.6 introduced screenshot management.

Supported screenshot categories:

```text
overview
feature
usage
workflow
platform
custom
```

Each screenshot can be represented with metadata including:

* ID,
* title,
* path,
* category,
* description.

Supported formats include:

```text
.png
.jpg
.jpeg
.svg
.webp
```

Validation prevents:

* absolute paths,
* path traversal,
* duplicate IDs,
* unsupported formats.

The manager produces deterministic Markdown galleries.

CLI:

```bash
fps template screenshots <template-id>
```

with support for:

```text
--version
--category
--output
--write
--json
```

---

# GIF Pipeline

Phase 3.7 introduced GIF documentation management.

Supported categories:

```text
demo
feature
workflow
onboarding
custom
```

GIF metadata includes:

* ID,
* title,
* path,
* category,
* description.

Supported formats include:

```text
.gif
.webp
```

Validation includes:

* relative path enforcement,
* path traversal prevention,
* duplicate ID prevention,
* format validation.

CLI:

```bash
fps template gifs <template-id>
```

with:

```text
--version
--category
--output
--write
--json
```

---

# Static Documentation Website

Phase 3.8 connects the documentation subsystems into a single static documentation portal.

The website generator consumes output from:

```text
ReadmeGenerator
ApiDocGenerator
ArchitectureDocGenerator
CodeExampleGenerator
ScreenshotManager
GifManager
```

and combines those artifacts into a static HTML/Markdown documentation bundle.

CLI:

```bash
fps template website <template-id>
```

Supported options:

```text
--version
--output
--write
--json
```

The website subsystem also follows deterministic page and navigation ordering.

---

# Testing Infrastructure

Milestone 4 extends FPS from documentation into a complete testing engineering pipeline.

The testing architecture is progressively layered:

```text
Test Project Generation
          ↓
Test Execution
          ↓
Coverage / Compatibility Evidence
          ↓
Regression Analysis
          ↓
Certification
          ↓
Unified Workflow
```

Phase 4.12 explicitly orchestrates the preceding testing components in dependency order.

---

# Test Project Generator

Phase 4.1 introduced isolated test-project generation.

The generator creates a controlled representation of a test project without unexpectedly modifying the original package or host workspace.

The generated project can contain:

```text
pubspec.yaml
analysis_options.yaml
test/<package>_test.dart
```

The subsystem contains:

* `TestProjectConfig`
* `TestProjectOptions`
* `TestProjectPlan`
* `TestProjectResult`
* `TestProjectValidator`
* `TestProjectGenerator`

Validation covers:

* package names,
* target relative paths,
* path traversal.

CLI:

```bash
fps template test-project <template-id>
```

with:

```text
--version
--output
--write
--json
```

Unit/widget test generation and execution are explicitly identified as later functionality in the Phase 4.1 report.

---

# Regression Testing Engine

Phase 4.10 introduced regression analysis.

The engine compares current testing evidence against:

* defined regression expectations,
* or a supplied baseline.

It models:

* regression status,
* severity,
* regression cases,
* options,
* plans,
* results,
* baseline comparison metrics.

CLI:

```bash
fps template regression <template-id>
```

Supported profiles:

```text
unit
widget
integration
all
```

Additional options include:

```text
--version
--profile
--baseline
--output
--write
--json
```

The engine is deliberately separated from execution: actual execution occurs only through the controlled Test Runner abstraction when explicitly requested.

Phase 4.10 reports that CI/CD orchestration was deferred to Phase 4.11/4.12-era infrastructure and later milestone work.

---

# Test Quality & Certification

Phase 4.11 introduced the Test Quality & Certification Gate subsystem.

It evaluates structured evidence against explicit quality profiles.

Supported profiles:

```text
standard
strict
custom
```

Certification decisions include:

```text
certified
conditionally-certified
failed
blocked
not-certified
insufficient-evidence
```

The certification engine evaluates:

* test execution,
* coverage,
* compatibility,
* regression evidence.

CLI:

```bash
fps template test-certify <template-id>
```

Options:

```text
--version
--profile
--config
--output
--write
--json
```

An important design rule is that certification must be based on evidence and must not fabricate missing evidence.

---

# Unified Testing Workflow

Phase 4.12 introduces the unified testing workflow.

Instead of requiring users or automation to coordinate every testing subsystem independently, the workflow orchestrates the lifecycle in a defined order.

Conceptually:

```text
Planning
   ↓
Validation
   ↓
Test Project
   ↓
Testing
   ↓
Analysis
   ↓
Regression
   ↓
Certification
   ↓
Reporting
```

The workflow models:

* stage status,
* workflow profiles,
* workflow stages,
* options,
* plans,
* results.

CLI:

```bash
fps template test-workflow <template-id>
```

Supported profiles:

```text
plan
test
full
regression
certify
all
```

Execution is explicitly controlled through:

```text
--execute
```

Other options:

```text
--version
--profile
--execute
--output
--write
--json
```

Phase 4.12 reports that the complete suite reached **691 passing tests**, with 683 regression tests plus 8 new unified-workflow tests.

---

# Plan-First Execution Model

A recurring architecture pattern throughout FPS is:

```text
Request
  ↓
Validate
  ↓
Build immutable plan
  ↓
Preview
  ↓
Optional execution
  ↓
Produce structured result
```

This pattern exists across:

* API documentation,
* architecture documentation,
* Mermaid,
* examples,
* screenshots,
* GIFs,
* websites,
* test projects,
* regression,
* certification,
* unified testing.

The benefit is that automation can inspect an operation before allowing it to mutate the filesystem or execute tests.

---

# Preview and Write Safety

A particularly important characteristic of FPS is the distinction between:

```text
Preview
```

and:

```text
Write
```

For example:

```bash
fps template mermaid
```

is designed to preview the generated result.

Explicit writing requires:

```bash
--write
```

This pattern is repeatedly verified in the implementation reports.

The reports state that preview mode performs zero disk writes, while filesystem mutation is only performed when `--write` is explicitly provided.

---

# Determinism

Determinism is a first-class engineering requirement.

The project repeatedly verifies that identical inputs produce byte-identical outputs.

Deterministic ordering is applied to things such as:

* API symbols,
* architecture components,
* architecture decisions,
* Mermaid nodes,
* Mermaid edges,
* imports,
* code blocks,
* screenshot items,
* GIF items,
* website navigation,
* website pages,
* test-project files,
* regression cases,
* certification gates,
* workflow stages.

This makes generated artifacts easier to:

* diff,
* cache,
* review,
* test,
* reproduce,
* validate in CI.

---

# Security and Path Safety

Security is not treated as an isolated feature.

Validation is distributed throughout the architecture.

Common protections include:

### Path traversal prevention

Inputs containing:

```text
..
```

are rejected in sensitive path contexts.

### Absolute path rejection

Operations intended to work inside controlled output roots reject unexpected absolute paths.

### Sanitization

User/content-derived text is passed through sanitization mechanisms such as `ReadmeSanitizer`.

### Secret redaction

The reports repeatedly mention redaction of:

* secret tokens,
* sensitive path information,
* other potentially unsafe content.

### Private API filtering

API documentation excludes symbols beginning with `_`.

### Mermaid validation

Invalid Mermaid node identifiers are rejected.

These protections are explicitly verified in the corresponding phase reports.

---

# CLI Overview

The CLI currently registers these command families:

```text
fps create
fps audit
fps release
fps docs
fps publish
fps template
fps plugin
fps registry
```

The CLI entry point registers all of these before dispatching the user's arguments.

The `template` command family contains a substantial portion of the package-engineering functionality.

---

# Installation

## Prerequisites

The repository requires a Dart SDK compatible with:

```text
>= 3.5.0 < 4.0.0
```

This requirement is defined at the workspace level and in both packages.

You should have:

* Git
* Dart SDK 3.5+
* a compatible Flutter SDK if working with Flutter packages
* a terminal
* an editor such as VS Code or IntelliJ/Android Studio

---

# Clone the Repository

```bash
git clone https://github.com/Ashish6298/Syntrix.git
cd Syntrix
```

---

# Resolve Workspace Dependencies

From the repository root:

```bash
dart pub get
```

Because the root is a Dart workspace, both packages participate in workspace dependency resolution.

---

# Analyze the Workspace

```bash
dart analyze packages/flutter_package_studio_core packages/flutter_package_studio_cli
```

A clean verification state should report:

```text
No issues found!
```

The implementation reports repeatedly use this command as a primary verification gate.

---

# Format the Workspace

```bash
dart format --output=none --set-exit-if-changed \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli
```

This checks whether formatting changes are required without modifying files.

---

# Documentation Analysis

The project uses:

```bash
dart doc --dry-run packages/flutter_package_studio_core
dart doc --dry-run packages/flutter_package_studio_cli
```

The reported verification state for the documented phases is:

```text
0 warnings
0 errors
```

---

# Testing

Run the full workspace suite:

```bash
dart test \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli \
  --concurrency=1
```

The latest available Phase 4.12 implementation report records:

```text
691 / 691 tests passed
```

with:

```text
683 regression tests
8 Phase 4.12 tests
```

---

# Running the CLI

From the CLI package:

```bash
dart run packages/flutter_package_studio_cli/bin/fps.dart
```

Depending on local Dart executable configuration, the CLI can also be exposed through the package executable configuration.

The executable entry point is:

```text
packages/flutter_package_studio_cli/bin/fps.dart
```

and initializes the complete FPS dependency/configuration/command environment before dispatching commands.

---

# Template Commands

## List templates

```bash
fps template list
```

## Filter templates

```bash
fps template list --project-type flutter_package
```

```bash
fps template list --category builtin
```

## JSON output

```bash
fps template list --json
```

---

## Search templates

```bash
fps template search "flutter package"
```

```bash
fps template search "widget" --json
```

---

## Inspect a template

```bash
fps template info <template-id>
```

```bash
fps template info <template-id> --version 1.0.0
```

```bash
fps template info <template-id> --json
```

---

## Check compatibility

```bash
fps template check <template-id>
```

Example:

```bash
fps template check <template-id> \
  --dart-version 3.5.0 \
  --flutter-version 3.22.0 \
  --os linux \
  --policy standard
```

---

## Compose templates

```bash
fps template compose <base-id> <extension-id>
```

Override conflicts:

```bash
fps template compose <base-id> <extension-id> \
  --conflict-policy override
```

Skip conflicting files:

```bash
fps template compose <base-id> <extension-id> \
  --conflict-policy skip
```

---

## Customize templates

```bash
fps template customize <template-id>
```

With preset:

```bash
fps template customize <template-id> \
  --preset production
```

With variables:

```bash
fps template customize <template-id> \
  --var enable_auth=true \
  --var enable_logging=true
```

---

# Documentation Commands

## API documentation

```bash
fps template api-docs <template-id>
```

Write:

```bash
fps template api-docs <template-id> --write
```

JSON:

```bash
fps template api-docs <template-id> --json
```

---

## Architecture documentation

```bash
fps template architecture
```

Write:

```bash
fps template architecture --write
```

---

## Mermaid diagrams

```bash
fps template mermaid
```

Flowchart:

```bash
fps template mermaid --type flowchart
```

Sequence diagram:

```bash
fps template mermaid --type sequence
```

---

## Code examples

```bash
fps template examples <template-id>
```

Basic:

```bash
fps template examples <template-id> --type basic
```

Initialization:

```bash
fps template examples <template-id> --type init
```

Configuration:

```bash
fps template examples <template-id> --type config
```

Complete example:

```bash
fps template examples <template-id> --type full
```

---

## Screenshots

```bash
fps template screenshots <template-id>
```

Category:

```bash
fps template screenshots <template-id> \
  --category feature
```

---

## GIFs

```bash
fps template gifs <template-id>
```

Category:

```bash
fps template gifs <template-id> \
  --category demo
```

---

## Static documentation website

```bash
fps template website <template-id>
```

Write:

```bash
fps template website <template-id> --write
```

---

# Testing Commands

## Test project

```bash
fps template test-project <template-id>
```

Write:

```bash
fps template test-project <template-id> --write
```

---

## Regression testing

```bash
fps template regression <template-id>
```

Unit profile:

```bash
fps template regression <template-id> \
  --profile unit
```

Widget profile:

```bash
fps template regression <template-id> \
  --profile widget
```

Integration profile:

```bash
fps template regression <template-id> \
  --profile integration
```

All profiles:

```bash
fps template regression <template-id> \
  --profile all
```

---

## Certification

```bash
fps template test-certify <template-id>
```

Standard:

```bash
fps template test-certify <template-id> \
  --profile standard
```

Strict:

```bash
fps template test-certify <template-id> \
  --profile strict
```

Custom:

```bash
fps template test-certify <template-id> \
  --profile custom
```

---

## Unified testing workflow

Plan:

```bash
fps template test-workflow <template-id> \
  --profile plan
```

Testing:

```bash
fps template test-workflow <template-id> \
  --profile test
```

Regression:

```bash
fps template test-workflow <template-id> \
  --profile regression
```

Certification:

```bash
fps template test-workflow <template-id> \
  --profile certify
```

Full workflow:

```bash
fps template test-workflow <template-id> \
  --profile full
```

All stages:

```bash
fps template test-workflow <template-id> \
  --profile all
```

Actual execution is explicitly controlled with:

```bash
--execute
```

For example:

```bash
fps template test-workflow <template-id> \
  --profile full \
  --execute
```

---

# JSON Output

A major strength of the CLI architecture is machine-readable output.

Many commands support:

```text
--json
```

This makes FPS suitable for:

* automation,
* scripts,
* CI systems,
* dashboards,
* external tooling,
* IDE integrations,
* machine validation.

Examples:

```bash
fps template list --json
```

```bash
fps template info <template-id> --json
```

```bash
fps template check <template-id> --json
```

```bash
fps template compose <template-id> --json
```

```bash
fps template api-docs <template-id> --json
```

```bash
fps template test-workflow <template-id> --json
```

The implementation reports explicitly verify JSON result output for the newly introduced commands.

---

# Reports

The repository maintains phase implementation reports under:

```text
report/
```

These reports are valuable because they record:

* phase objective,
* implementation summary,
* files created,
* files modified,
* verification commands,
* test counts,
* security verification,
* determinism verification,
* side-effect verification,
* known limitations,
* final assessment.

Current visible reports include:

```text
PHASE_3.2_IMPLEMENTATION_REPORT.txt
PHASE_3.3_IMPLEMENTATION_REPORT.txt
PHASE_3.4_IMPLEMENTATION_REPORT.txt
PHASE_3.5_IMPLEMENTATION_REPORT.txt
PHASE_3.6_IMPLEMENTATION_REPORT.txt
PHASE_3.7_IMPLEMENTATION_REPORT.txt
PHASE_3.8_IMPLEMENTATION_REPORT.txt

PHASE_4.1_IMPLEMENTATION_REPORT.txt
PHASE_4.10_IMPLEMENTATION_REPORT.txt
PHASE_4.11_IMPLEMENTATION_REPORT.txt
PHASE_4.12_IMPLEMENTATION_REPORT.txt
```

The repository's report directory currently exposes these implementation records.

---

# Testing and Verification

The project uses multiple verification gates.

## Gate 1 — Static analysis

```bash
dart analyze \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli
```

Expected:

```text
0 errors
0 warnings
0 lints
```

---

## Gate 2 — Formatting

```bash
dart format --output=none --set-exit-if-changed \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli
```

---

## Gate 3 — Documentation analysis

```bash
dart doc --dry-run packages/flutter_package_studio_core
dart doc --dry-run packages/flutter_package_studio_cli
```

---

## Gate 4 — Full test suite

```bash
dart test \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli \
  --concurrency=1
```

---

# Reported Test Progression

The implementation reports demonstrate continuous regression testing as features were added.

| Phase      | Reported Total Tests |
| ---------- | -------------------: |
| Phase 3.2  |                  550 |
| Phase 3.3  |                  555 |
| Phase 3.4  |                  564 |
| Phase 3.5  |                  571 |
| Phase 3.6  |                  581 |
| Phase 3.7  |                  591 |
| Phase 3.8  |                  598 |
| Phase 4.1  |                  608 |
| Phase 4.10 |                  675 |
| Phase 4.11 |                  683 |
| Phase 4.12 |              **691** |

These figures are taken from the corresponding implementation reports and demonstrate that each phase preserved the preceding regression suite while adding new coverage.

---

# Quality Gates

Each phase report follows a consistent quality-gate structure.

```text
Static Analysis
       ↓
Formatting
       ↓
Documentation Analysis
       ↓
Full Regression Test Suite
       ↓
Security Verification
       ↓
Side-Effect Verification
       ↓
Determinism Verification
       ↓
Final Assessment
```

A typical successful phase concludes with:

```text
All verification gates passed: YES
Existing functionality preserved: YES
Unresolved blockers: NONE
```

This pattern appears throughout the available implementation reports.

---

# Error Handling

FPS uses a structured exception hierarchy rooted in:

```text
PackageStudioException
```

Each major subsystem extends that hierarchy with a dedicated exception.

Examples include:

```text
ApiDocGenerationException
ArchitectureDocGenerationException
MermaidGenerationException
CodeExampleGenerationException
ScreenshotManagementException
GifPipelineException
StaticWebsiteGenerationException
TestProjectGenerationException
RegressionTestingException
TestCertificationException
UnifiedTestingWorkflowException
```

This keeps subsystem failures distinguishable while preserving a common error model.

The phase reports document these extensions as each subsystem was introduced.

---

# Dependency Model

The dependency direction is intentionally simple:

```text
CLI
 │
 ▼
Core
```

The CLI depends on:

```text
flutter_package_studio_core
```

The core package does not depend on the CLI.

The CLI package declares the core package as a local workspace dependency.

This allows the core library to be reused independently of the command-line interface.

---

# Design Principles

## Determinism

Same input → same output.

---

## Explicit mutation

Preview is safe.

Writing requires explicit intent.

---

## Layered architecture

Domain logic lives in core.

Command parsing and user interaction live in CLI.

---

## Immutable planning

Plans/results are modeled as immutable data structures wherever practical.

---

## Structured output

Results can be rendered for:

* humans,
* Markdown,
* JSON,
* static websites.

---

## Evidence-based quality

Testing and certification operate on actual evidence.

---

## Regression preservation

Every implementation phase is expected to preserve the existing test suite.

---

## Security by validation

Inputs are validated before sensitive operations.

---

## Separation of responsibilities

Documentation, testing, compatibility, composition, customization, and certification remain distinct subsystems rather than one giant orchestration layer.

---

# Milestone Progression

The repository's implementation reports establish a clear architectural progression.

## Milestone 1

The project foundation.

The later reports identify this baseline as:

```text
Phases 1.1–1.8
```

---

## Milestone 2

The reports identify this baseline as:

```text
Phases 2.1–2.12
```

This represents the package/template engineering foundation on which later documentation and testing capabilities were built.

---

# Milestone 3 — Documentation Engineering

Milestone 3 progresses through:

```text
3.1
3.2 — API Documentation Generator
3.3 — Architecture Documentation Generator
3.4 — Mermaid Diagram Generator
3.5 — Code Example Generator
3.6 — Screenshot Manager
3.7 — GIF Pipeline
3.8 — Static Documentation Website
```

The available Phase 3 reports show each stage extending the previous regression baseline.

---

# Milestone 4 — Testing Infrastructure

The visible Phase 4 reports document:

```text
4.1 — Test Project Generator
4.10 — Regression Testing Engine
4.11 — Test Quality & Certification
4.12 — Unified Testing Workflow
```

Phase 4.12 explicitly describes itself as completing the Milestone 4 Testing Infrastructure & Automation layer.

---

# Current Project State

Based on the latest implementation report currently present in the repository, Phase 4.12 is:

```text
COMPLETE
```

The latest reported verification state is:

```text
Static analysis       → PASS
Formatting            → PASS
Documentation         → PASS
Full test suite       → 691/691 PASS
Security checks       → PASS
Determinism checks    → PASS
Preview safety        → PASS
Existing functionality→ PRESERVED
Blockers              → NONE
```

The Phase 4.12 report explicitly states that the project is ready for Phase 4.13.

---

# Known Limitations

The implementation reports also intentionally document deferred functionality.

## API documentation

Full Dart AST resolution for complex cross-library references is deferred to native `dartdoc` integration.

## Testing

Phase 4.1 established the isolated test-project foundation, while unit/widget test generation and execution were deferred to subsequent testing phases.

## CI/CD

The Phase 4.10 report identifies CI/CD pipeline orchestration as deferred functionality, while Phase 4.12 identifies Phase 4.13/Milestone 5 as the area for CI/CD Pipeline Orchestration.

These limitations should not be interpreted as failures; they represent deliberately staged architectural boundaries.

---

# Future Direction

The next logical architectural layer is CI/CD orchestration.

The existing architecture already provides most of the ingredients required:

```text
Template
   ↓
Compatibility
   ↓
Composition
   ↓
Customization
   ↓
Generation
   ↓
Documentation
   ↓
Test Project
   ↓
Testing
   ↓
Regression
   ↓
Certification
   ↓
Unified Workflow
   ↓
CI/CD Orchestration
```

This makes the system suitable for eventually supporting automated package validation pipelines in which every generated package can be:

1. discovered,
2. composed,
3. customized,
4. generated,
5. documented,
6. tested,
7. regression-checked,
8. certified,
9. and published through a controlled automation pipeline.

---

# Contributing

Before contributing, understand the architecture first.

New functionality should generally:

1. Belong to the correct package.
2. Have a clearly defined domain responsibility.
3. Prefer immutable models for plans/results.
4. Validate user-controlled paths and identifiers.
5. Avoid unexpected filesystem mutation.
6. Support deterministic output.
7. Provide structured JSON output where appropriate.
8. Add unit tests.
9. Add CLI integration tests when CLI behavior changes.
10. Preserve all existing regression tests.
11. Run static analysis.
12. Run formatting checks.
13. Run documentation analysis.
14. Record meaningful implementation/test evidence.

For larger changes, follow the project's existing phase-oriented development style.

---

# Recommended Verification Workflow for Contributors

After making a change:

```bash
dart pub get
```

Then:

```bash
dart analyze \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli
```

Then:

```bash
dart format --output=none --set-exit-if-changed \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli
```

Then:

```bash
dart doc --dry-run packages/flutter_package_studio_core
dart doc --dry-run packages/flutter_package_studio_cli
```

Finally:

```bash
dart test \
  packages/flutter_package_studio_core \
  packages/flutter_package_studio_cli \
  --concurrency=1
```

A feature should not be considered complete merely because its local unit tests pass. The repository's established engineering process treats the full monorepo regression suite as a verification gate.

---

# Project Characteristics

Flutter Package Studio can be summarized as:

| Characteristic              | Approach                                                                  |
| --------------------------- | ------------------------------------------------------------------------- |
| Language                    | Dart                                                                      |
| Workspace                   | Dart workspace / monorepo                                                 |
| Primary domain              | Flutter/Dart package engineering                                          |
| Core package                | `flutter_package_studio_core`                                             |
| CLI package                 | `flutter_package_studio_cli`                                              |
| CLI executable              | `fps`                                                                     |
| SDK baseline                | Dart `>=3.5.0 <4.0.0`                                                     |
| Architecture                | Core + CLI                                                                |
| Planning model              | Plan-first                                                                |
| Preview model               | Zero-mutation by default                                                  |
| Output model                | Deterministic                                                             |
| Serialization               | JSON supported across major subsystems                                    |
| Documentation               | README/API/Architecture/Mermaid/Examples/Screenshots/GIF/Website          |
| Testing                     | Test projects + execution + regression + certification + unified workflow |
| Security                    | Validation, sanitization, path safety, secret redaction                   |
| Current reported test state | 691/691 passing                                                           |
| Next documented direction   | CI/CD orchestration                                                       |

The package SDK and dependency information comes directly from the current workspace/package manifests, while the testing and milestone information is derived from the implementation reports.

---

# Architecture Summary

At the highest level:

```text
                         FLUTTER PACKAGE STUDIO
                                  │
                    ┌─────────────┴─────────────┐
                    │                           │
                 CORE                         CLI
                    │                           │
        ┌───────────┼───────────┐       ┌───────┴────────┐
        │           │           │       │                │
     Templates   Docs       Testing   Commands       Automation
        │           │           │
        │           │           │
   ┌────┴────┐   ┌──┴────────┐  ├── Test Projects
   │          │   │           │  ├── Regression
Discovery  Compose │ API       │  ├── Certification
Compatibility Customize      │  └── Unified Workflow
                    │         │
                    ├── Architecture
                    ├── Mermaid
                    ├── Examples
                    ├── Screenshots
                    ├── GIFs
                    └── Website
```

The architecture is intentionally incremental: each subsystem is independently testable, while higher-level orchestration combines their outputs.

---

# Documentation Philosophy

FPS does not treat documentation as a final README-writing step.

Instead:

```text
Package Metadata
       ↓
API
       ↓
Architecture
       ↓
Diagrams
       ↓
Examples
       ↓
Visual Assets
       ↓
Website
```

This creates a documentation pipeline capable of producing consistent package documentation from structured source information.

---

# Testing Philosophy

Testing follows the same engineering philosophy:

```text
Generate isolated environment
          ↓
Execute controlled tests
          ↓
Collect evidence
          ↓
Compare against baseline
          ↓
Evaluate quality gates
          ↓
Certify
          ↓
Generate report
```

This is substantially more rigorous than simply running `dart test`.

The Phase 4 architecture explicitly separates planning, execution, regression analysis, certification, and workflow orchestration.

---

# What Makes FPS Different?

Flutter Package Studio is essentially trying to turn package engineering into a **reproducible engineering pipeline**.

Instead of:

```text
"Create some files and hope everything works."
```

the system aims for:

```text
Discover
   ↓
Inspect
   ↓
Validate
   ↓
Plan
   ↓
Preview
   ↓
Generate
   ↓
Document
   ↓
Test
   ↓
Compare
   ↓
Certify
   ↓
Automate
```

That distinction is the central architectural idea behind the repository.

---

# Repository Links

* **Repository:** https://github.com/Ashish6298/Syntrix
* **Implementation Reports:** https://github.com/Ashish6298/Syntrix/tree/main/report
* **Core Package:** https://github.com/Ashish6298/Syntrix/tree/main/packages/flutter_package_studio_core
* **CLI Package:** https://github.com/Ashish6298/Syntrix/tree/main/packages/flutter_package_studio_cli

---

# License

See the repository's licensing information for the authoritative license terms.

---

# Final Status

**Flutter Package Studio is an evolving Dart-based package engineering platform with a strong emphasis on deterministic generation, preview-safe operations, structured documentation, evidence-based testing, regression analysis, certification, and unified workflow orchestration.**

The latest available Phase 4.12 report records the Milestone 4 testing infrastructure as complete with:

```text
691 / 691 tests passing
0 analysis errors
0 analysis warnings
0 documentation-analysis errors
0 documentation-analysis warnings
No unresolved blockers
Existing functionality preserved
```

The documented next architectural step is **CI/CD Pipeline Orchestration**, building on top of the existing template, documentation, testing, regression, certification, and unified workflow foundations.

---

## Project Development Model

Flutter Package Studio is developed as a sequence of controlled implementation phases rather than as an unstructured collection of feature commits.

Each phase is expected to establish:

```text
Objective
   ↓
Implementation
   ↓
Tests
   ↓
Regression Verification
   ↓
Security Verification
   ↓
Determinism Verification
   ↓
Final Report
```

This development model is reflected directly in the implementation reports maintained in the repository.

---

**Built with Dart for the Flutter package ecosystem.**

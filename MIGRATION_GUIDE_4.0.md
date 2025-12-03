# Migration Guide: Version 3.x to 4.0

This guide describes breaking changes and how to migrate from Peekie 3.x (formerly DBXCResultParser) to version 4.0.

## Overview

Version 4.0 represents a major refactoring of the library with significant breaking changes:
- Complete package rename from `DBXCResultParser` to `Peekie`
- Restructured data models with new hierarchy
- Migration from Foundation's `Process` to `swift-subprocess`
- Improved API design with better separation of concerns
- Added logging support with `swift-log`

## Package Name Changes

### Before (3.x)
```swift
.package(url: "https://github.com/dodobrands/DBXCResultParser.git", from: "3.1.3")

dependencies: [
    "DBXCResultParser",
    "DBXCResultParser-TextFormatter",
    "DBXCResultParserTestHelpers"
]
```

### After (4.0)
```swift
.package(url: "https://github.com/dodobrands/Peekie.git", from: "4.0.0")

dependencies: [
    "PeekieSDK",
    "PeekieTestHelpers"
]
```

### Import Changes
```swift
// Old
import DBXCResultParser
import DBXCResultParser_TextFormatter

// New
import PeekieSDK
```

## Core Model Changes

### Report Model

The main model was renamed from `DBXCReportModel` to `Report` with significant structural changes.

#### Before (3.x)
```swift
let report: DBXCReportModel
report.modules           // Set<DBXCReportModel.Module>
report.warningCount      // Int?
report.totalCoverage     // Double?
```

#### After (4.0)
```swift
let report: Report
report.modules           // Set<Report.Module>
report.coverage          // Double? (renamed from totalCoverage)
report.warnings          // [Report.Module.Suite.Issue] (new, replaces warningCount)
```

### Module Structure Changes

Version 4.0 introduces a new `Suite` level between `Module` and test organization.

#### Before (3.x)
```swift
struct Module {
    let name: String
    var files: Set<File>        // Test organization by file
    let coverage: Coverage?
}
```

#### After (4.0)
```swift
struct Module {
    let name: String
    var suites: Set<Suite>      // NEW: Test organization by suite
    var files: Set<File>        // Still present but for warnings only
    let coverage: Coverage?
    var warnings: [Suite.Issue] // NEW: Access to all warnings of module
}
```

### Test Organization

The hierarchy changed from `Module → File → RepeatableTest` to `Module → Suite → RepeatableTest`.

#### Before (3.x)
```swift
// Access tests through files
for module in report.modules {
    for file in module.files {
        for test in file.repeatableTests {
            print(test.name)
        }
    }
}
```

#### After (4.0)
```swift
// Access tests through suites
for module in report.modules {
    for suite in module.suites {
        for test in suite.repeatableTests {
            print(test.name)
        }
    }
}
```

### Suite (New in 4.0)

A new `Suite` type was introduced to better represent test organization:

```swift
struct Suite {
    let name: String
    let nodeIdentifierURL: String  // URL identifier from xcresult
    var repeatableTests: Set<RepeatableTest>
    var warnings: [Issue]          // Warnings associated with this suite
}
```

### Test Structure Changes

#### Before (3.x)
```swift
struct Test {
    let status: Status
    let duration: Measurement<UnitDuration>
    let message: String?  // Single message field
}
```

#### After (4.0)
```swift
struct Test {
    let name: String                              // NEW
    let status: Status
    let duration: Measurement<UnitDuration>
    let path: [PathNode]                          // NEW: Test execution path
    let failureMessage: String?                   // NEW: Separate failure message
    let skipMessage: String?                      // NEW: Separate skip message

    var message: String? {                        // Computed property
        // Returns appropriate message based on status
    }
}
```

#### PathNode (New in 4.0)

Tests now include execution path information:

```swift
struct PathNode {
    let name: String
    let type: NodeType              // device, arguments, repetition
    let result: Test.Status?
    let duration: Measurement<UnitDuration>?
    let message: String?
}
```

### Coverage Changes

#### Before (3.x)
```swift
// Module-level coverage
struct Coverage {
    let name: String               // Module name included
    let coveredLines: Int
    let totalLines: Int
    let coverage: Double
}
```

#### After (4.0)
```swift
// Report-level coverage (simpler)
extension Report {
    let coverage: Double?          // Direct percentage, no name
}

// Module-level coverage
struct Coverage {
    let coveredLines: Int          // No name field
    let totalLines: Int
    let coverage: Double
}

// File-level coverage (NEW)
extension Report.Module.File {
    struct Coverage {
        let coveredLines: Int
        let totalLines: Int
        let coverage: Double
    }
}
```

### Warnings/Issues

#### Before (3.x)
```swift
let report: DBXCReportModel
let warningCount: Int? = report.warningCount  // Only count available
```

#### After (4.0)
```swift
let report: Report
let warnings: [Report.Module.Suite.Issue] = report.warnings  // Full issue details

struct Issue {
    let type: IssueType            // .buildWarning
    let message: String
}
```

## Shell/Subprocess Changes

The shell execution API changed significantly.

#### Before (3.x)
```swift
public class DBShell {
    @discardableResult
    public static func execute(_ command: String) throws -> String
}

// Usage
let output = try DBShell.execute("xcrun xcresulttool ...")
```

#### After (4.0)
```swift
public class Shell {
    @discardableResult
    public static func execute(
        _ executable: String,
        arguments: [String] = []
    ) async throws -> String
}

// Usage - now async and separated executable/arguments
let output = try await Shell.execute("xcrun", arguments: ["xcresulttool", "..."])
```

**Key Changes:**
- Now uses `async/await`
- Migrated from `Process` to `swift-subprocess`
- Separated executable and arguments (better security)
- Added logging support
- Better error handling with `ShellError.processFailed`

## Formatter Changes

The formatter API was significantly redesigned.

#### Before (3.x)
```swift
public class DBXCTextFormatter {
    public func format(
        _ report: DBXCReportModel,
        include: [DBXCReportModel.Module.File.RepeatableTest.Test.Status] = .allCases,
        format: Format = .list,
        locale: Locale? = nil
    ) -> String
}

enum Format {
    case list
    case count
}
```

#### After (4.0)
```swift
public class ListFormatter {
    public func format(
        _ report: Report,
        include: [Report.Module.Suite.RepeatableTest.Test.Status] = ...,
        includeDeviceDetails: Bool = false  // NEW parameter
    ) -> String
}

// Separate formatter for different output format
public class SonarFormatter { ... }
```

**Key Changes:**
- Split into multiple formatters (`ListFormatter`, `SonarFormatter`)
- Removed `format` parameter (use different formatter classes instead)
- Removed `locale` parameter
- Added `includeDeviceDetails` parameter
- Added logging support
- Removed `count` format - use dedicated formatter or custom implementation

## New Features in 4.0

### 1. Merged Tests

```swift
let repeatableTest: Report.Module.Suite.RepeatableTest
let mergedTests = repeatableTest.mergedTests(filterDevice: false)
// Returns [Test] with repetitions merged
```

### 2. Better Test Metadata

Tests now include execution path information:

```swift
let test: Report.Module.Suite.RepeatableTest.Test
print(test.path)  // [PathNode] - shows device, arguments, repetition info
print(test.failureMessage)
print(test.skipMessage)
```

### 3. Warnings API

```swift
let report: Report
let allWarnings = report.warnings

for module in report.modules {
    let moduleWarnings = module.warnings
}

for suite in module.suites {
    let suiteWarnings = suite.warnings
}
```

### 4. File Coverage

```swift
let file: Report.Module.File
if let coverage = file.coverage {
    print("File coverage: \(coverage.coverage)")
}
```

## Platform Requirements

- **3.x**: macOS 10.15+, Swift 5.8+
- **4.0**: macOS 13+, Swift 6.2+

## Step-by-Step Migration

1. **Update Package Dependencies**
   - Change package name references from `DBXCResultParser` to `Peekie`
   - Update version to `4.0.0` or later

2. **Update Imports**
   ```swift
   // Replace
   import DBXCResultParser
   import DBXCResultParser_TextFormatter

   // With
   import PeekieSDK
   ```

3. **Update Model References**
   - Replace `DBXCReportModel` with `Report`
   - Update type paths (e.g., `DBXCReportModel.Module.File.RepeatableTest.Test` → `Report.Module.Suite.RepeatableTest.Test`)

4. **Restructure Test Access**
   - Change from `module.files` to `module.suites`
   - Tests are now organized by suite, not file

5. **Update Shell Calls**
   - Change synchronous `DBShell.execute(command)` to async `Shell.execute(executable, arguments: [...])`
   - Add `async`/`await` to calling code

6. **Update Formatter Usage**
   - Replace `DBXCTextFormatter` with `ListFormatter`
   - Remove `format` parameter usage
   - Use appropriate formatter class for your needs

7. **Handle Warnings**
   - Replace `warningCount` checks with `warnings.count`
   - Access full warning details via `report.warnings`

8. **Update Coverage Access**
   - Change `report.totalCoverage` to `report.coverage`
   - Module coverage structure simplified (no `name` field)

## Removed Features

### Removed in 4.0:
- ❌ `DBXCReportModel.warningCount: Int?` - use `report.warnings.count` instead
- ❌ `DBXCTextFormatter.format` parameter `.count` - implement custom counting or use separate formatter
- ❌ Locale support in formatters - removed for simplicity
- ❌ Separate text formatter library - merged into `PeekieSDK`
- ❌ Synchronous shell execution - now async only
- ❌ File-based test organization as primary structure - replaced with suite-based

## Renamed

| Old (3.x) | New (4.0) |
|-----------|-----------|
| `DBXCReportModel` | `Report` |
| `DBShell` | `Shell` |
| `DBXCTextFormatter` | `ListFormatter` |
| `DBXCResultParserTestHelpers` | `PeekieTestHelpers` |
| `report.totalCoverage` | `report.coverage` |
| `module.files.repeatableTests` | `module.suites.repeatableTests` |

## Testing Helpers

Test helper package was renamed but API remains mostly compatible:

#### Before (3.x)
```swift
.product(name: "DBXCResultParserTestHelpers", package: "DBXCResultParser")
```

#### After (4.0)
```swift
.product(name: "PeekieTestHelpers", package: "Peekie")
```

## Command Line Tool

The executable name changed:

- **3.x**: `DBXCResultParser-TextFormatterExec`
- **4.0**: `peekie`

Usage:
```bash
# Old
swift run DBXCResultParser-TextFormatterExec list path/to/tests.xcresult

# New
swift run peekie list path/to/tests.xcresult
```

## Need Help?

If you encounter issues during migration:
1. Check the [README](README.md) for updated usage examples
2. Review test files in the repository for working examples
3. Open an issue on GitHub with your migration question

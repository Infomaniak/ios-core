# AGENTS.md

## Code Style

- When wrapping constants in an enum type, the type name should end in `Constants`. Example: `KDriveFileSharingConstants`.

## Testing

- Write all new tests with Swift Testing (`import Testing`, `@Suite`, `@Test`, and `#expect`).
- Do not add new XCTest test cases. Existing XCTest suites may remain until they are modified or migrated.

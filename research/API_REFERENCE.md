# Apple Container Framework API Reference

## Overview

The Apple Container Framework provides APIs through two main packages:
1. **container** - CLI tool and services
2. **containerization** - Swift package with programmatic APIs

## Swift Package Integration

### Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/apple/containerization", from: "0.9.1")
]
```

### Import Modules

```swift
import Containerization           // Core container management
import ContainerizationOCI        // OCI image support
import ContainerizationIO         // I/O operations
import ContainerizationOS         // OS-level abstractions
import ContainerizationExtras     // Additional utilities
import ContainerizationArchive    // Archive handling
```

## Core Classes and Protocols

### Container Management

#### LinuxContainer

Main class for container lifecycle management.

```swift
public class LinuxContainer: Identifiable, Sendable {
    // Properties
    public let id: String
    public let name: String?
    public var state: ContainerState
    public let config: ContainerConfiguration
    public let vm: VZVirtualMachine

    // Lifecycle Methods
    public func create() async throws
    public func start() async throws
    public func stop(timeout: TimeInterval = 10) async throws
    public func kill(signal: Int32 = SIGTERM) async throws
    public func delete() async throws
    public func wait() async throws -> Int32

    // Process Execution
    public func exec(
        command: [String],
        environment: [String: String]? = nil,
        workingDirectory: String? = nil,
        user: String? = nil
    ) async throws -> LinuxProcess

    // State Management
    public func inspect() async throws -> ContainerInspection
    public func stats() async throws -> ContainerStats
}
```

#### ContainerConfiguration

Configuration for creating containers.

```swift
public struct ContainerConfiguration: Codable, Sendable {
    public var image: String
    public var command: [String]?
    public var entrypoint: [String]?
    public var workingDir: String?
    public var environment: [String: String]
    public var hostname: String?
    public var user: String?
    public var labels: [String: String]
    public var mounts: [Mount]
    public var networks: [String]
    public var resources: ResourceLimits
    public var restartPolicy: RestartPolicy
    public var stopTimeout: TimeInterval

    // Builder pattern
    public func withImage(_ image: String) -> Self
    public func withCommand(_ command: [String]) -> Self
    public func withEnvironment(_ env: [String: String]) -> Self
    public func withMount(_ mount: Mount) -> Self
    public func withNetwork(_ network: String) -> Self
    public func withResources(_ resources: ResourceLimits) -> Self
}
```

#### ResourceLimits

Resource constraints for containers.

```swift
public struct ResourceLimits: Codable, Sendable {
    public var cpuCount: Int?
    public var cpuPercent: Double?
    public var memoryLimitBytes: UInt64?
    public var memorySwapLimitBytes: UInt64?
    public var diskSizeBytes: UInt64?
    public var pidsLimit: Int?

    public init(
        cpus: Int? = nil,
        memory: UInt64? = nil,
        disk: UInt64? = nil
    )
}
```

### Process Management

#### LinuxProcess

Represents a process running in a container.

```swift
public class LinuxProcess: Identifiable {
    public let id: String
    public let pid: Int32
    public let command: [String]

    // I/O Streams
    public var stdin: AsyncStream<Data>?
    public var stdout: AsyncStream<Data> { get }
    public var stderr: AsyncStream<Data> { get }

    // Process Control
    public func kill(signal: Int32 = SIGTERM) async throws
    public func wait() async throws -> Int32
    public func resize(rows: UInt16, cols: UInt16) async throws

    // Status
    public func isRunning() async -> Bool
    public func exitCode() async -> Int32?
}
```

#### ProcessConfiguration

Configuration for process execution.

```swift
public struct ProcessConfiguration: Sendable {
    public var command: [String]
    public var args: [String]
    public var env: [String: String]
    public var cwd: String?
    public var user: String?
    public var group: String?
    public var tty: Bool
    public var stdin: Bool
    public var stdout: Bool
    public var stderr: Bool
}
```

### Virtual Machine Management

#### VZVirtualMachineManager

Manages the underlying virtualization.

```swift
public class VZVirtualMachineManager {
    // VM Lifecycle
    public func createVM(config: VZVirtualMachineConfiguration) throws -> VZVirtualMachine
    public func startVM(_ vm: VZVirtualMachine) async throws
    public func stopVM(_ vm: VZVirtualMachine) async throws
    public func pauseVM(_ vm: VZVirtualMachine) throws
    public func resumeVM(_ vm: VZVirtualMachine) throws

    // VM State
    public func state(_ vm: VZVirtualMachine) -> VZVirtualMachine.State
    public func canStart(_ vm: VZVirtualMachine) -> Bool
    public func canPause(_ vm: VZVirtualMachine) -> Bool
    public func canResume(_ vm: VZVirtualMachine) -> Bool
}
```

#### Kernel

Linux kernel management.

```swift
public struct Kernel: Identifiable {
    public let id: String
    public let version: String
    public let path: URL
    public let initrdPath: URL?
    public let commandLine: String
    public let architecture: String

    // Kernel Operations
    public static func list() async throws -> [Kernel]
    public static func download(version: String) async throws -> Kernel
    public static func setDefault(_ kernel: Kernel) async throws
    public static func delete(_ kernel: Kernel) async throws
}
```

### Networking

#### Network Protocol

```swift
public protocol Network {
    var id: String { get }
    var name: String { get }
    var type: NetworkType { get }
    var subnet: String { get }
    var gateway: String? { get }
    var dns: [String] { get }

    func connect(container: LinuxContainer) async throws
    func disconnect(container: LinuxContainer) async throws
    func inspect() async throws -> NetworkInspection
}
```

#### VmnetNetwork

Virtual network implementation.

```swift
public class VmnetNetwork: Network {
    // Network Management
    public static func create(
        name: String,
        subnet: String = "192.168.64.0/24",
        nat: Bool = true
    ) async throws -> VmnetNetwork

    public func delete() async throws
    public func list() async throws -> [VmnetNetwork]

    // Container Connections
    public func attachContainer(_ container: LinuxContainer) async throws
    public func detachContainer(_ container: LinuxContainer) async throws

    // DNS Configuration
    public func setDNS(servers: [String]) async throws
    public func addHost(hostname: String, ip: String) async throws
}
```

### File Systems

#### Mount

Volume and bind mount configuration.

```swift
public struct Mount: Codable, Sendable {
    public enum MountType {
        case bind
        case volume
        case tmpfs
    }

    public var type: MountType
    public var source: String
    public var target: String
    public var readonly: Bool
    public var options: [String]

    // Convenience initializers
    public static func bind(
        source: String,
        target: String,
        readonly: Bool = false
    ) -> Mount

    public static func volume(
        name: String,
        target: String,
        readonly: Bool = false
    ) -> Mount

    public static func tmpfs(
        target: String,
        size: UInt64? = nil
    ) -> Mount
}
```

#### VirtioFS

High-performance file sharing.

```swift
public class VirtioFS {
    public let tag: String
    public let path: URL
    public let readonly: Bool

    public init(
        tag: String,
        path: URL,
        readonly: Bool = false
    )

    // Mount in guest
    public func mountCommand() -> String {
        "mount -t virtiofs \(tag) /mnt/\(tag)"
    }
}
```

### Image Management

#### ImageReference

OCI image reference.

```swift
public struct ImageReference: Codable, Sendable {
    public let registry: String?
    public let namespace: String?
    public let repository: String
    public let tag: String?
    public let digest: String?

    // Parsing
    public init(from string: String) throws

    // String representation
    public var fullName: String { get }
    public var shortName: String { get }
}
```

#### ImageManager

Image operations.

```swift
public class ImageManager {
    // Image Operations
    public func pull(
        _ reference: String,
        platform: Platform? = nil,
        progress: Progress? = nil
    ) async throws -> Image

    public func push(
        _ image: Image,
        to reference: String,
        progress: Progress? = nil
    ) async throws

    public func list() async throws -> [Image]

    public func inspect(_ reference: String) async throws -> ImageInspection

    public func remove(_ reference: String) async throws

    // Building
    public func build(
        dockerfile: URL,
        context: URL,
        tag: String,
        platform: Platform? = nil,
        buildArgs: [String: String]? = nil,
        progress: Progress? = nil
    ) async throws -> Image
}
```

### Client Library

#### ContainerClient

High-level client for container operations.

```swift
public class ContainerClient {
    public init() async throws

    // Service Management
    public func start() async throws
    public func stop() async throws
    public func healthCheck() async throws -> Bool

    // Container Operations
    public func createContainer(
        _ config: ContainerConfiguration
    ) async throws -> LinuxContainer

    public func listContainers(
        all: Bool = false
    ) async throws -> [LinuxContainer]

    public func getContainer(
        _ id: String
    ) async throws -> LinuxContainer?

    // Image Operations
    public var images: ImageManager { get }

    // Network Operations
    public func createNetwork(
        name: String,
        driver: String = "vmnet"
    ) async throws -> Network

    public func listNetworks() async throws -> [Network]
}
```

## Error Handling

### ContainerizationError

```swift
public enum ContainerizationError: Error {
    case containerNotFound(String)
    case imageNotFound(String)
    case networkNotFound(String)
    case invalidConfiguration(String)
    case vmError(String)
    case ioError(String)
    case networkError(String)
    case buildError(String)
    case authenticationRequired
    case permissionDenied
    case unsupportedOperation(String)
}
```

## XPC Communication

### XPCClient

Inter-process communication client.

```swift
public class XPCClient {
    public init(serviceName: String)

    public func send<T: Codable>(
        _ message: T,
        reply: @escaping (Result<Data, Error>) -> Void
    )

    public func sendAsync<T: Codable, R: Codable>(
        _ message: T
    ) async throws -> R

    public func invalidate()
}
```

### XPCMessage

Message protocol for XPC.

```swift
public protocol XPCMessage: Codable {
    associatedtype Reply: Codable
    static var messageType: String { get }
}
```

## Guest Communication

### Vminitd API

Guest init daemon gRPC interface.

```swift
// Key vminitd methods exposed via gRPC:
public protocol VminitdService {
    // Process management
    func spawn(request: SpawnRequest) async throws -> SpawnResponse
    func kill(pid: Int32, signal: Int32) async throws
    func wait(pid: Int32) async throws -> ExitStatus

    // File operations
    func readFile(path: String) async throws -> Data
    func writeFile(path: String, data: Data) async throws
    func createDirectory(path: String) async throws
    func removeFile(path: String) async throws
    func listDirectory(path: String) async throws -> [FileInfo]

    // System operations
    func mount(source: String, target: String, fstype: String) async throws
    func unmount(target: String) async throws
    func setHostname(hostname: String) async throws
    func configureNetwork(config: NetworkConfig) async throws
}
```

## Usage Examples

### Creating and Running a Container

```swift
import Containerization

let client = try await ContainerClient()

// Pull image
let image = try await client.images.pull("alpine:latest")

// Create container configuration
let config = ContainerConfiguration()
    .withImage("alpine:latest")
    .withCommand(["sh", "-c", "echo Hello World"])
    .withEnvironment(["USER": "container"])
    .withMount(.bind(source: "/tmp/host", target: "/data"))
    .withResources(ResourceLimits(cpus: 2, memory: 1_073_741_824))

// Create and start container
let container = try await client.createContainer(config)
try await container.start()

// Wait for completion
let exitCode = try await container.wait()
print("Container exited with code: \(exitCode)")

// Clean up
try await container.delete()
```

### Executing Commands in Running Container

```swift
// Get running container
guard let container = try await client.getContainer("my-container") else {
    throw ContainerizationError.containerNotFound("my-container")
}

// Execute command
let process = try await container.exec(
    command: ["ls", "-la", "/"],
    environment: ["TERM": "xterm-256color"],
    user: "root"
)

// Read output
for await data in process.stdout {
    print(String(data: data, encoding: .utf8) ?? "")
}

// Wait for completion
let exitCode = try await process.wait()
```

### Building an Image

```swift
let imageManager = client.images

let image = try await imageManager.build(
    dockerfile: URL(fileURLWithPath: "./Dockerfile"),
    context: URL(fileURLWithPath: "."),
    tag: "myapp:latest",
    platform: .init(os: .linux, arch: .arm64),
    buildArgs: [
        "VERSION": "1.0.0",
        "BUILD_DATE": Date().ISO8601Format()
    ]
)

print("Built image: \(image.reference)")
```

### Network Management

```swift
// Create network
let network = try await client.createNetwork(
    name: "mynetwork",
    driver: "vmnet"
)

// Create container on network
let config = ContainerConfiguration()
    .withImage("nginx:latest")
    .withNetwork(network.name)

let container = try await client.createContainer(config)
try await container.start()

// Connect another container
let db = try await client.getContainer("database")
try await network.connect(container: db!)
```

## Swift vs Objective-C Usage

The framework is written in Swift and optimized for Swift usage. While it can be called from Objective-C, Swift is strongly recommended for:

- Better async/await support
- Type safety with generics
- Protocol-oriented design benefits
- Cleaner error handling
- Modern concurrency features

### Swift-Only Features

- AsyncSequence for streaming I/O
- Structured concurrency with TaskGroup
- Actors for thread-safe state management
- Result builders for configuration
- Property wrappers for state observation

## Thread Safety

All public APIs are thread-safe and can be called from any queue. The framework uses:

- Actors for state isolation
- Sendable conformance for safe sharing
- AsyncSequence for concurrent streaming
- MainActor for UI updates

## Performance Considerations

- **Container startup**: Sub-second (typically 200-500ms)
- **Image pulls**: Network-bound, no parallel layer downloads yet
- **File sharing**: Near-native with VirtioFS
- **Memory overhead**: ~100MB per container VM
- **CPU overhead**: < 1% when idle

## Limitations

Current API limitations in v0.5.0:

- No volume management APIs
- No container stats streaming
- No health check support
- No service discovery
- Limited network configuration
- No cluster management
- No compose/stack APIs

## API Stability

**Warning**: APIs may change between minor versions until 1.0.0. Pin to exact versions:

```swift
.package(url: "https://github.com/apple/containerization", exact: "0.9.1")
```
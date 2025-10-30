# Apple Container Framework - Comprehensive API Documentation

## Overview

The Apple Container Framework is a sophisticated containerization solution for macOS that enables running Linux containers as lightweight virtual machines on Apple silicon. The framework consists of two main repositories:

1. **container** - CLI tool and container management services
2. **containerization** - Core Swift package providing containerization APIs

**Platform Requirements:**
- Apple silicon Macs
- macOS 26+
- Swift-based implementation

**Key Technologies:**
- Apple Virtualization.framework
- vmnet framework
- XPC (Cross-Process Communication)
- OCI (Open Container Initiative) standards

---

## Architecture Components

### Core Services
- **container-apiserver**: Launch agent managing container and network resources
- **container-core-images**: XPC helper for image management and local content store
- **container-network-vmnet**: XPC helper for virtual networking
- **container-runtime-linux**: Runtime helper for individual container management

---

## 1. Container Lifecycle Management APIs

### 1.1 Container Protocol

The core protocol that all container implementations must conform to.

```swift
import Containerization

protocol Container {
    /// ID for the container
    var id: String { get }

    /// The amount of CPUs assigned to the container
    var cpus: Int { get }

    /// The memory in bytes assigned to the container
    var memoryInBytes: UInt64 { get }

    /// The network interfaces assigned to the container
    var interfaces: [any Interface] { get }
}
```

### 1.2 LinuxContainer Class

The primary class for managing Linux container lifecycle inside a virtual machine.

```swift
import Containerization

class LinuxContainer: Container {
    // MARK: - Properties

    /// Container identifier
    var id: String

    /// Root filesystem mount
    var rootfs: Mount

    /// Container configuration
    var config: Configuration

    /// Number of CPUs
    var cpus: Int

    /// Memory allocation in bytes
    var memoryInBytes: UInt64

    /// Network interfaces
    var interfaces: [any Interface]

    // MARK: - Initialization

    /// Initialize a Linux container
    /// - Parameters:
    ///   - id: Container identifier
    ///   - rootfs: Root filesystem mount
    ///   - vmm: Virtual machine manager
    ///   - logger: Optional logger
    ///   - configuration: Configuration closure
    init(
        _ id: String,
        rootfs: Mount,
        vmm: VirtualMachineManager,
        logger: Logger? = nil,
        configuration: (inout Configuration) throws -> Void
    ) throws

    // MARK: - Lifecycle Methods

    /// Create the container
    func create() async throws

    /// Start the container
    func start() async throws

    /// Stop the container gracefully
    func stop() async throws

    /// Pause the container
    func pause() async throws

    /// Resume a paused container
    func resume() async throws

    /// Kill the container with a signal
    /// - Parameter signal: Signal number (e.g., SIGTERM, SIGKILL)
    func kill(_ signal: Int32) async throws

    /// Wait for container to exit
    /// - Parameter timeoutInSeconds: Optional timeout
    /// - Returns: Exit status
    func wait(timeoutInSeconds: Int64? = nil) async throws -> ExitStatus

    // MARK: - Process Management

    /// Execute a process in the container
    /// - Parameters:
    ///   - id: Process identifier
    ///   - configuration: Process configuration closure
    /// - Returns: LinuxProcess instance
    func exec(
        _ id: String,
        configuration: (inout Configuration.Process) throws -> Void
    ) async throws -> LinuxProcess

    /// Execute a process with explicit configuration
    func exec(
        _ id: String,
        configuration: Configuration.Process
    ) async throws -> LinuxProcess

    // MARK: - I/O Operations

    /// Close standard input
    func closeStdin() async throws

    /// Resize terminal
    /// - Parameter to: New terminal size
    func resize(to: Terminal.Size) async throws

    // MARK: - Networking

    /// Dial a vsock port
    /// - Parameter port: Port number
    /// - Returns: File handle for connection
    func dialVsock(port: UInt32) async throws -> FileHandle

    /// Relay Unix socket
    /// - Parameter socket: Unix socket configuration
    func relayUnixSocket(socket: UnixSocketConfiguration) async throws

    // MARK: - Statistics

    /// Get container statistics
    /// - Returns: Container statistics
    func statistics() async throws -> ContainerStatistics
}
```

### 1.3 Configuration Types

```swift
extension LinuxContainer {
    struct Configuration {
        // Configuration properties
        // (Implementation details vary based on needs)
    }

    struct Process {
        // Process-specific configuration
    }
}
```

### 1.4 ContainerManager

High-level API for creating and managing containers.

```swift
import Containerization

struct ContainerManager {
    // MARK: - Properties

    /// Image store for managing container images
    var imageStore: ImageStore

    /// Network provider for container networking
    var network: Network?

    // MARK: - Initialization

    /// Initialize with kernel and initfs
    init(
        kernel: Kernel,
        initfs: Mount,
        imageStore: ImageStore,
        network: Network? = nil
    )

    /// Initialize with kernel, initfs, and root directory
    init(
        kernel: Kernel,
        initfs: Mount,
        root: URL? = nil,
        network: Network? = nil
    )

    /// Initialize with kernel and initfs reference
    init(
        kernel: Kernel,
        initfsReference: String,
        imageStore: ImageStore,
        network: Network? = nil
    )

    /// Initialize with kernel, initfs reference, and root
    init(
        kernel: Kernel,
        initfsReference: String,
        root: URL? = nil,
        network: Network? = nil
    )

    /// Initialize with virtual machine manager
    init(
        vmm: any VirtualMachineManager,
        network: Network? = nil
    )

    // MARK: - Container Operations

    /// Create a container from an image reference
    func create(
        _ id: String,
        reference: String,
        rootfsSizeInBytes: UInt64 = 8.gib(),
        configuration: (inout LinuxContainer.Configuration) throws -> Void
    ) async throws -> LinuxContainer

    /// Create a container from an image
    func create(
        _ id: String,
        image: Image,
        rootfsSizeInBytes: UInt64 = 8.gib(),
        configuration: (inout LinuxContainer.Configuration) throws -> Void
    ) async throws -> LinuxContainer

    /// Create a container with explicit rootfs
    func create(
        _ id: String,
        image: Image,
        rootfs: Mount,
        configuration: (inout LinuxContainer.Configuration) throws -> Void
    ) async throws -> LinuxContainer

    /// Get an existing container
    func get(_ id: String, image: Image) async throws -> LinuxContainer

    /// Delete a container
    func delete(_ id: String) async throws
}
```

---

## 2. Process Management APIs

### 2.1 LinuxProcess

Represents and controls a Linux process within a container.

```swift
import Containerization

class LinuxProcess {
    // MARK: - Properties

    /// Process identifier
    var id: String

    /// Container owning this process (optional)
    var owningContainer: String?

    /// Process ID (-1 if not started)
    var pid: Int32

    // MARK: - Lifecycle Methods

    /// Start the process
    func start() async throws

    /// Kill the process with a signal
    /// - Parameter signal: Signal number
    func kill(_ signal: Int32) async throws

    /// Wait for process to exit
    /// - Parameter timeoutInSeconds: Optional timeout
    /// - Returns: Exit status
    func wait(timeoutInSeconds: Int64? = nil) async throws -> ExitStatus

    /// Delete the process and clean up resources
    func delete() async throws

    // MARK: - I/O Operations

    /// Close standard input
    func closeStdin() async throws

    /// Resize PTY (pseudo-terminal)
    /// - Parameter to: New terminal size
    func resize(to: Terminal.Size) async throws
}
```

### 2.2 ExitStatus

```swift
import Containerization

struct ExitStatus: Sendable {
    /// The exit code of the process
    var exitCode: Int32

    /// Timestamp when the process exited
    var exitedAt: Date

    // MARK: - Initialization

    /// Initialize with exit code (current timestamp)
    init(exitCode: Int32)

    /// Initialize with exit code and timestamp
    init(exitCode: Int32, exitedAt: Date)
}
```

---

## 3. Virtual Machine Management APIs

### 3.1 VirtualMachineManager Protocol

```swift
import Containerization

protocol VirtualMachineManager {
    // Protocol requirements for VM management
}
```

### 3.2 VZVirtualMachineManager

Implementation using Apple's Virtualization framework (macOS only).

```swift
import Containerization

struct VZVirtualMachineManager: VirtualMachineManager {
    // MARK: - Initialization

    /// Initialize virtual machine manager
    /// - Parameters:
    ///   - kernel: Kernel configuration
    ///   - initialFilesystem: Initial filesystem mount
    ///   - bootlog: Optional boot log path
    ///   - logger: Optional logger
    init(
        kernel: Kernel,
        initialFilesystem: Mount,
        bootlog: URL?,
        logger: Logger?
    )

    // MARK: - VM Operations

    /// Create a virtual machine instance from a container
    /// - Parameter container: Linux container configuration
    /// - Returns: Virtual machine instance
    func create(container: LinuxContainer) async throws -> VZVirtualMachineInstance
}
```

### 3.3 Kernel Configuration

```swift
import Containerization

struct Kernel {
    // MARK: - Properties

    /// Path to kernel binary
    var path: URL

    /// System platform
    var platform: SystemPlatform

    /// Kernel and init command line
    var commandLine: CommandLine

    /// Kernel command line arguments
    var kernelArgs: [String]

    /// Init process arguments
    var initArgs: [String]

    // MARK: - Initialization

    init(
        path: URL,
        platform: SystemPlatform,
        commandline: CommandLine = CommandLine(debug: false, panic: 0)
    )
}

extension Kernel {
    struct CommandLine {
        // MARK: - Static Properties

        /// Default kernel arguments
        static var kernelDefaults: [String]

        // MARK: - Initialization

        /// Initialize with optional arguments
        init(
            kernelArgs: [String] = kernelDefaults,
            initArgs: [String] = []
        )

        /// Initialize with debug and panic settings
        init(
            debug: Bool,
            panic: Int,
            initArgs: [String] = []
        )

        // MARK: - Methods

        /// Add debug flag to kernel commandline
        mutating func addDebug()

        /// Add panic level to kernel commandline
        /// - Parameter level: Panic level
        mutating func addPanic(level: Int)
    }
}
```

---

## 4. Networking APIs

### 4.1 Interface Protocol

```swift
import Containerization

protocol Interface: Sendable {
    /// The interface IPv4 address and subnet prefix length, as a CIDR address
    /// Example: "192.168.64.3/24"
    var address: String { get }

    /// The IP address for the default route, or nil for no default route
    var gateway: String? { get }

    /// The interface MAC address, or nil to auto-configure
    var macAddress: String? { get }
}
```

### 4.2 NATInterface

```swift
import Containerization

struct NATInterface: Interface {
    // MARK: - Properties

    var address: String
    var gateway: String?
    var macAddress: String?

    // MARK: - Initialization

    init(
        address: String,
        gateway: String?,
        macAddress: String? = nil
    )
}
```

### 4.3 Network Protocol

```swift
import Containerization

protocol Network {
    /// Allocate a network interface for a container
    func create(_ id: String) async throws -> any Interface

    /// Release a network interface
    func release(_ id: String) async throws
}
```

### 4.4 VmnetNetwork

Network implementation using macOS vmnet framework.

```swift
import Containerization

struct VmnetNetwork: Network {
    // MARK: - Properties

    /// Network subnet
    var subnet: CIDRAddress

    /// Gateway IP address
    var gateway: IPv4Address

    // MARK: - Initialization

    /// Initialize with optional subnet
    /// - Parameter subnet: CIDR subnet (optional)
    init(subnet: String? = nil) throws

    // MARK: - Network Operations

    func create(_ id: String) async throws -> any Interface
    func release(_ id: String) async throws
}
```

### 4.5 DNS Configuration

```swift
import Containerization

struct DNS: Sendable {
    // MARK: - Static Properties

    /// Default nameservers
    static var defaultNameservers: [String] // ["1.1.1.1"]

    // MARK: - Properties

    /// Nameserver IP addresses
    var nameservers: [String]

    /// DNS domain
    var domain: String?

    /// DNS search domains
    var searchDomains: [String]

    /// DNS options
    var options: [String]

    /// Generated resolv.conf content
    var resolvConf: String { get }

    // MARK: - Initialization

    init(
        nameservers: [String] = defaultNameservers,
        domain: String? = nil,
        searchDomains: [String] = [],
        options: [String] = []
    )
}
```

### 4.6 Hosts Configuration

```swift
import Containerization

struct Hosts: Sendable {
    // MARK: - Properties

    /// Hosts file entries
    var entries: [Entry]

    /// Optional comment for the hosts file
    var comment: String?

    /// Generated hosts file content
    var hostsFile: String { get }

    // MARK: - Static Properties

    /// Default hosts configuration with localhost and IPv6 entries
    static var `default`: Hosts

    // MARK: - Initialization

    init(entries: [Entry], comment: String? = nil)
}

extension Hosts {
    struct Entry: Sendable {
        // MARK: - Properties

        /// IP address
        var ipAddress: String

        /// Hostnames
        var hostnames: [String]

        /// Optional comment
        var comment: String?

        /// Rendered hosts file line
        var rendered: String { get }

        // MARK: - Initialization

        init(
            ipAddress: String,
            hostnames: [String],
            comment: String? = nil
        )

        // MARK: - Static Helpers

        static func localHostIPV4(comment: String? = nil) -> Entry
        static func localHostIPV6(comment: String? = nil) -> Entry
        static func ipv6LocalNet(comment: String? = nil) -> Entry
        static func ipv6MulticastPrefix(comment: String? = nil) -> Entry
        static func ipv6AllNodes(comment: String? = nil) -> Entry
        static func ipv6AllRouters(comment: String? = nil) -> Entry
    }
}
```

### 4.7 VsockConnectionStream

For virtual socket connections between host and guest.

```swift
import Containerization

class VsockConnectionStream {
    // MARK: - Properties

    /// Async stream of incoming connections
    var connections: AsyncStream<FileHandle>

    /// Vsock port number
    var port: UInt32

    // MARK: - Initialization

    init(port: UInt32)

    // MARK: - Methods

    /// Terminate the connection stream
    func finish()
}
```

---

## 5. Filesystem APIs

### 5.1 Mount

```swift
import Containerization

struct Mount: Sendable {
    // MARK: - Properties

    /// Mount type (e.g., "bind", "tmpfs")
    var type: String

    /// Source path
    var source: String

    /// Destination path in container
    var destination: String

    /// Mount options
    var options: [String]

    /// Runtime-specific options
    var runtimeOptions: RuntimeOptions

    // MARK: - Static Factory Methods

    /// Create a block device mount
    static func block(
        format: String,
        source: URL,
        destination: String,
        options: [String] = [],
        runtimeOptions: RuntimeOptions = .virtioblk([])
    ) -> Mount

    /// Create a shared directory mount
    static func share(
        source: URL,
        destination: String,
        options: [String] = [],
        runtimeOptions: RuntimeOptions = .virtiofs([])
    ) -> Mount

    /// Create a generic mount
    static func any(
        type: String,
        source: String,
        destination: String,
        options: [String] = []
    ) -> Mount

    // MARK: - macOS-Specific Methods

    /// Clone the mount to a new location
    func clone(to: URL) throws -> Mount
}

extension Mount {
    enum RuntimeOptions: Sendable {
        /// Virtio block device options
        case virtioblk([String])

        /// Virtio filesystem options
        case virtiofs([String])

        /// Any runtime options
        case any
    }
}
```

### 5.2 EXT4 Filesystem

```swift
import ContainerizationEXT4

enum EXT4 {
    // MARK: - Static Properties

    static var SuperBlockMagic: UInt16
    static var MaxFileSize: UInt64
    static var RootInode: InodeNumber
    static var LostAndFoundInode: InodeNumber

    // MARK: - Error Types

    enum Error: Swift.Error {
        case notFound
        case couldNotReadSuperBlock
        case invalidSuperBlock
        case couldNotReadInode
        // Additional error cases...
    }
}

// Usage Examples:

// Reading an existing ext4 filesystem
let blockDevice = URL(filePath: "/dev/sdb")
let ext4 = try Ext4(blockDevice: blockDevice)
print("Block size: \(ext4.blockSize)")

// Formatting a new ext4 filesystem
let devicePath = URL(filePath: "/dev/sdc")
let formatter = try EXT4.Formatter(devicePath, blockSize: 4096)
try formatter.close()
```

---

## 6. OCI (Open Container Initiative) APIs

### 6.1 OCI Reference

For parsing and manipulating container image references.

```swift
import ContainerizationOCI

class Reference {
    // MARK: - Properties

    /// Registry domain (e.g., "docker.io")
    var domain: String?

    /// Resolved domain with defaults applied
    var resolvedDomain: String?

    /// Image path (e.g., "library/nginx")
    var path: String

    /// Image tag (e.g., "latest")
    var tag: String?

    /// Image digest (e.g., "sha256:abc123...")
    var digest: String?

    /// Full image name
    var name: String

    /// String representation
    var description: String

    // MARK: - Initialization

    init(
        path: String,
        domain: String? = nil,
        tag: String? = nil,
        digest: String? = nil
    )

    // MARK: - Static Methods

    /// Parse a reference string
    /// - Parameter s: Reference string (e.g., "nginx:latest")
    /// - Returns: Parsed reference
    static func parse(_ s: String) throws -> Reference

    /// Create reference with name
    static func withName(_ name: String) throws -> Reference

    /// Resolve domain with defaults
    static func resolveDomain(domain: String) -> String

    // MARK: - Instance Methods

    /// Create a new reference with specified tag
    func withTag(_ tag: String) throws -> Reference

    /// Create a new reference with specified digest
    func withDigest(_ digest: String) throws -> Reference

    /// Normalize the reference
    func normalize() throws
}
```

### 6.2 OCI Image Configuration

```swift
import ContainerizationOCI

struct Image: Codable, Sendable {
    /// Image creation timestamp
    var created: Date?

    /// Image maintainer
    var author: String?

    /// CPU architecture
    var architecture: String

    /// Operating system
    var os: String

    /// OS version
    var osVersion: String?

    /// OS features
    var osFeatures: [String]?

    /// CPU variant
    var variant: String?

    /// Image configuration
    var config: ImageConfig

    /// Layer content references
    var rootfs: Rootfs

    /// Layer history
    var history: [History]?
}

struct ImageConfig: Codable, Sendable {
    /// User/UID to run container process
    var user: String?

    /// Environment variables
    var env: [String]?

    /// Container start command arguments
    var entrypoint: [String]?

    /// Default arguments for entrypoint
    var cmd: [String]?

    /// Container's working directory
    var workingDir: String?

    /// Container metadata
    var labels: [String: String]?

    /// System call signal to exit container
    var stopSignal: String?
}

struct Rootfs: Codable, Sendable {
    /// Rootfs type (typically "layers")
    var type: String

    /// Layer content hash array
    var diffIDs: [String]
}

struct History: Codable, Sendable {
    /// Layer creation timestamp
    var created: Date?

    /// Layer creation command
    var createdBy: String?

    /// Build point author
    var author: String?

    /// Custom layer message
    var comment: String?

    /// Indicates filesystem diff creation
    var emptyLayer: Bool?
}
```

### 6.3 OCI Runtime Specification

```swift
import ContainerizationOCI

struct Spec: Codable, Sendable {
    /// OCI version
    var version: String

    /// Lifecycle hooks
    var hooks: Hook?

    /// Process configuration
    var process: Process?

    /// Container hostname
    var hostname: String?

    /// Container domain name
    var domainname: String?

    /// Filesystem mounts
    var mounts: [Mount]?

    /// Container annotations
    var annotations: [String: String]?

    /// Root filesystem
    var root: Root?

    /// Linux-specific configuration
    var linux: Linux?
}

struct Process: Codable, Sendable {
    /// Current working directory
    var cwd: String

    /// Environment variables
    var env: [String]?

    /// Command arguments
    var args: [String]?

    /// User configuration
    var user: User?

    /// Capabilities
    var capabilities: LinuxCapabilities?

    /// Terminal flag
    var terminal: Bool?
}

struct Linux: Codable, Sendable {
    /// Linux namespaces
    var namespaces: [LinuxNamespace]?

    /// Resource limits
    var resources: LinuxResources?

    /// Cgroups path
    var cgroupsPath: String?

    /// Device configurations
    var devices: [LinuxDevice]?

    /// Seccomp configuration
    var seccomp: LinuxSeccomp?
}

enum LinuxNamespaceType: String, Codable, Sendable {
    case pid
    case network
    case mount
    case ipc
    case uts
    case user
    case cgroup
}
```

---

## 7. Guest Communication APIs (Vminitd)

Vminitd is a lightweight init system running inside the VM with a gRPC-like API.

```swift
import Containerization

struct Vminitd {
    // MARK: - Static Properties

    /// Default vsock port
    static var port: UInt32 // 1024

    /// Default PATH environment variable
    static var defaultPath: String

    // MARK: - Initialization

    init(client: XPCClient)
    init(connection: FileHandle, group: EventLoopGroup)

    // MARK: - Connection Management

    /// Close connection to guest agent
    func close() async throws

    // MARK: - Guest Setup

    /// Perform standard guest setup for container runtime
    func standardSetup() async throws

    // MARK: - File Operations

    /// Write file in guest environment
    /// - Parameters:
    ///   - path: File path
    ///   - data: File data
    ///   - flags: File flags
    ///   - mode: File permissions
    func writeFile(
        path: String,
        data: Data,
        flags: Int32,
        mode: UInt32
    ) async throws

    /// Create directory in sandbox
    /// - Parameters:
    ///   - path: Directory path
    ///   - all: Create parent directories
    ///   - perms: Directory permissions
    func mkdir(
        path: String,
        all: Bool,
        perms: UInt32
    ) async throws

    // MARK: - Mount Operations

    /// Mount filesystem in sandbox
    func mount(_ mount: Mount) async throws

    /// Unmount filesystem
    /// - Parameters:
    ///   - path: Mount path
    ///   - flags: Unmount flags
    func umount(path: String, flags: Int32) async throws

    // MARK: - Process Management

    /// Create a new process
    func createProcess(
        id: String,
        containerID: String,
        config: ProcessConfiguration
    ) async throws

    /// Start a process
    func startProcess(id: String, containerID: String) async throws

    /// Send signal to process
    func signalProcess(
        id: String,
        containerID: String,
        signal: Int32
    ) async throws

    /// Resize process terminal
    func resizeProcess(
        id: String,
        containerID: String,
        size: Terminal.Size
    ) async throws

    /// Wait for process to exit
    func waitProcess(
        id: String,
        containerID: String,
        timeout: Duration?
    ) async throws -> ExitStatus

    /// Delete a process
    func deleteProcess(id: String, containerID: String) async throws

    /// Close process stdin
    func closeProcessStdin(id: String, containerID: String) async throws

    // MARK: - Network Operations

    /// Bring up network interface
    func up(name: String, mtu: UInt32?) async throws

    /// Bring down network interface
    func down(name: String) async throws

    /// Add IP address to interface
    func addressAdd(name: String, address: String) async throws

    // MARK: - Environment Management

    /// Get environment variable
    func getenv(key: String) async throws -> String

    /// Set environment variable
    func setenv(key: String, value: String) async throws

    // MARK: - System Operations

    /// Set up emulator in guest
    func setupEmulator(
        path: String,
        flags: [String]
    ) async throws

    /// Set guest time
    func setTime(sec: Int64, usec: Int64) async throws

    /// Set sysctls
    func sysctl(settings: [String: String]) async throws
}
```

---

## 8. XPC Communication APIs

### 8.1 XPCClient

For communicating with XPC services.

```swift
import ContainerXPC

class XPCClient: Sendable {
    // MARK: - Initialization

    /// Initialize with service name
    init(service: String, queue: DispatchQueue? = nil)

    /// Initialize with XPC connection
    init(
        connection: xpc_connection_t,
        label: String,
        queue: DispatchQueue? = nil
    )

    // MARK: - Methods

    /// Close the XPC connection
    func close()

    /// Get remote process ID
    func remotePid() -> pid_t

    /// Send message to service
    /// - Parameters:
    ///   - message: XPC message to send
    ///   - responseTimeout: Optional timeout
    /// - Returns: Response message
    func send(
        _ message: XPCMessage,
        responseTimeout: Duration? = nil
    ) async throws -> XPCMessage
}
```

### 8.2 XPCMessage

```swift
import ContainerXPC

struct XPCMessage: Sendable {
    // MARK: - Static Properties

    /// Key for route in message
    static var routeKey: String

    /// Key for error in message
    static var errorKey: String

    // MARK: - Properties

    /// Underlying XPC object
    var underlying: xpc_object_t

    /// Whether this is an error message
    var isErrorType: Bool

    // MARK: - Initialization

    init(object: xpc_object_t)
    init(route: String)

    // MARK: - Reply Methods

    /// Create a reply message
    func reply() -> XPCMessage

    // MARK: - Error Handling

    /// Get error description
    func errorKeyDescription() -> String

    /// Throw error if present
    func error() throws

    /// Set error in message
    func set(error: Error)

    // MARK: - Data Access

    /// Get data for key
    func data(key: String) throws -> Data

    /// Get data without copying
    func dataNoCopy(key: String) throws -> Data

    // MARK: - Value Setters

    func set(key: String, value: Data)
    func set(key: String, value: String)
    func set(key: String, value: Bool)
    func set(key: String, value: UInt64)
    func set(key: String, value: Int64)
    func set(key: String, value: Date)
    func set(key: String, value: FileHandle)
    func set(key: String, value: [FileHandle])
    func set(key: String, value: xpc_endpoint_t)
}
```

### 8.3 SandboxClient

High-level client for sandbox operations.

```swift
import ContainerClient

struct SandboxClient {
    // MARK: - Static Methods

    /// Create a sandbox client
    static func create(
        id: String,
        runtime: String
    ) async throws -> SandboxClient

    /// Get mach service label
    static func machServiceLabel(
        runtime: String,
        id: String
    ) -> String

    // MARK: - Instance Methods

    /// Bootstrap the sandbox
    func bootstrap(stdio: [FileHandle?]) async throws

    /// Get sandbox state
    func state() async throws -> SandboxSnapshot

    /// Create a process in sandbox
    func createProcess(
        _ id: String,
        config: ProcessConfiguration,
        stdio: [FileHandle?]
    ) async throws

    /// Start a process
    func startProcess(_ id: String) async throws

    /// Stop the sandbox
    func stop(options: ContainerStopOptions) async throws

    /// Kill a process
    func kill(_ id: String, signal: Int64) async throws

    /// Resize terminal
    func resize(_ id: String, size: Terminal.Size) async throws

    /// Wait for process to exit
    func wait(_ id: String) async throws -> ExitStatus

    /// Dial a port
    func dial(_ port: UInt32) async throws -> FileHandle

    /// Shutdown the sandbox
    func shutdown() async throws
}
```

### 8.4 Sandbox State

```swift
import ContainerClient

struct SandboxSnapshot: Codable, Sendable {
    /// The runtime status of the sandbox
    var status: RuntimeStatus

    /// Network attachments for the sandbox
    var networks: [Attachment]

    /// Containers placed in the sandbox
    var containers: [ContainerSnapshot]

    init(
        status: RuntimeStatus,
        networks: [Attachment],
        containers: [ContainerSnapshot]
    )
}
```

---

## 9. Archive Management APIs

### 9.1 ArchiveReader

For reading OCI image archives and tar files.

```swift
import ContainerizationArchive

class ArchiveReader: Sequence {
    // MARK: - Initialization

    /// Initialize with format and filter
    init(format: Format, filter: Filter, file: URL)

    /// Initialize with format and file handle
    init(format: Format, filter: Filter, fileHandle: FileHandle)

    /// Initialize with auto-detection
    init(file: URL)

    /// Initialize from bundle
    init(
        name: String,
        bundle: Bundle,
        tempDirectoryBaseName: String
    ) throws

    // MARK: - Extraction Methods

    /// Extract archive contents to directory
    /// - Parameter to: Destination directory
    func extractContents(to: URL) throws

    /// Extract specific file from archive
    /// - Parameter path: File path in archive
    /// - Returns: Entry and file data
    func extractFile(path: String) throws -> (Entry, Data)
}
```

---

## 10. Error Handling APIs

### 10.1 ContainerizationError

```swift
import ContainerizationError

struct ContainerizationError: Error, Sendable {
    // MARK: - Error Codes

    enum Code: String, Sendable {
        case unknown
        case invalidArgument
        case internalError
        case exists
        case notFound
        case cancelled
        case invalidState
        case empty
        case timeout
        case unsupported
        case interrupted
    }

    // MARK: - Properties

    var code: Code
    var message: String
    var cause: Error?

    // MARK: - Initialization

    init(_ code: Code, message: String, cause: Error? = nil)
    init(_ rawCode: String, message: String, cause: Error? = nil)

    // MARK: - Methods

    /// Check if error has specific code
    func isCode(_ code: Code) -> Bool
}
```

---

## 11. Command-Line Interface

The framework provides a comprehensive CLI tool accessible through the `container` command.

### 11.1 Container Lifecycle Commands

```bash
# Run a container
container run [OPTIONS] IMAGE [COMMAND] [ARG...]

# Create a container without starting
container create [OPTIONS] IMAGE [COMMAND] [ARG...]

# Start a stopped container
container start [OPTIONS] CONTAINER [CONTAINER...]

# Stop running containers
container stop [OPTIONS] CONTAINER [CONTAINER...]

# Kill containers with a signal
container kill [OPTIONS] CONTAINER [CONTAINER...]

# Remove containers
container delete [OPTIONS] CONTAINER [CONTAINER...]

# List containers
container list [OPTIONS]

# Execute command in running container
container exec [OPTIONS] CONTAINER COMMAND [ARG...]

# View container logs
container logs [OPTIONS] CONTAINER

# Display detailed container information
container inspect [OPTIONS] CONTAINER [CONTAINER...]
```

### 11.2 Image Management Commands

```bash
# List images
container image list [OPTIONS]

# Pull an image from registry
container image pull [OPTIONS] IMAGE

# Push an image to registry
container image push [OPTIONS] IMAGE

# Build an image
container build [OPTIONS] PATH

# Save image to tar archive
container image save [OPTIONS] IMAGE

# Load image from tar archive
container image load [OPTIONS]

# Tag an image
container image tag SOURCE_IMAGE[:TAG] TARGET_IMAGE[:TAG]

# Remove images
container image delete [OPTIONS] IMAGE [IMAGE...]

# Remove unused images
container image prune [OPTIONS]

# Display detailed image information
container image inspect [OPTIONS] IMAGE [IMAGE...]
```

### 11.3 Network Management Commands (macOS 26+)

```bash
# Create a network
container network create [OPTIONS] NETWORK

# List networks
container network list [OPTIONS]

# Remove networks
container network delete [OPTIONS] NETWORK [NETWORK...]

# Display detailed network information
container network inspect [OPTIONS] NETWORK [NETWORK...]
```

### 11.4 Volume Management Commands

```bash
# Create a volume
container volume create [OPTIONS] VOLUME

# List volumes
container volume list [OPTIONS]

# Remove volumes
container volume delete [OPTIONS] VOLUME [VOLUME...]

# Display detailed volume information
container volume inspect [OPTIONS] VOLUME [VOLUME...]
```

---

## 12. Common Usage Patterns

### 12.1 Creating and Running a Container

```swift
import Containerization

// Initialize container manager
let kernel = Kernel(
    path: URL(filePath: "/path/to/kernel"),
    platform: .linux,
    commandline: Kernel.CommandLine(debug: false, panic: 0)
)

let initfs = Mount.share(
    source: URL(filePath: "/path/to/initfs"),
    destination: "/init"
)

let network = try VmnetNetwork(subnet: "192.168.64.0/24")

let manager = ContainerManager(
    kernel: kernel,
    initfs: initfs,
    network: network
)

// Create container
let container = try await manager.create(
    "my-container",
    reference: "nginx:latest"
) { config in
    config.cpus = 2
    config.memoryInBytes = 2.gib()
}

// Start container
try await container.create()
try await container.start()

// Wait for container to exit
let exitStatus = try await container.wait()
print("Container exited with code: \(exitStatus.exitCode)")
```

### 12.2 Executing a Process in a Container

```swift
// Execute a process
let process = try await container.exec("shell") { config in
    config.args = ["/bin/sh"]
    config.env = ["PATH=/usr/bin:/bin"]
    config.cwd = "/root"
    config.terminal = true
}

// Start the process
try await process.start()

// Wait for process to complete
let exitStatus = try await process.wait()
```

### 12.3 Network Configuration

```swift
// Create NAT interface
let interface = NATInterface(
    address: "192.168.64.3/24",
    gateway: "192.168.64.1",
    macAddress: nil
)

// Configure DNS
let dns = DNS(
    nameservers: ["8.8.8.8", "8.8.4.4"],
    searchDomains: ["example.com"]
)

// Configure hosts file
let hosts = Hosts(entries: [
    .localHostIPV4(),
    .localHostIPV6(),
    Hosts.Entry(
        ipAddress: "192.168.64.10",
        hostnames: ["service.local"]
    )
])
```

### 12.4 Mount Management

```swift
// Create a shared directory mount
let sharedMount = Mount.share(
    source: URL(filePath: "/Users/username/data"),
    destination: "/mnt/data",
    options: ["ro"]
)

// Create a block device mount
let blockMount = Mount.block(
    format: "ext4",
    source: URL(filePath: "/dev/disk2"),
    destination: "/mnt/disk"
)

// Use in container configuration
let container = try await manager.create("container-id", image: image) { config in
    config.mounts = [sharedMount, blockMount]
}
```

### 12.5 Working with OCI Images

```swift
import ContainerizationOCI

// Parse image reference
let ref = try Reference.parse("docker.io/library/nginx:latest")
print("Domain: \(ref.resolvedDomain ?? "default")")
print("Path: \(ref.path)")
print("Tag: \(ref.tag ?? "latest")")

// Create reference with tag
let taggedRef = try ref.withTag("1.21")

// Create reference with digest
let digestRef = try ref.withDigest("sha256:abc123...")
```

---

## 13. Required Imports and Dependencies

### 13.1 Swift Package Dependencies

```swift
// Package.swift

dependencies: [
    .package(
        url: "https://github.com/apple/containerization.git",
        from: "0.1.0"
    )
]

targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "Containerization", package: "containerization"),
            .product(name: "ContainerizationOCI", package: "containerization"),
            .product(name: "ContainerizationEXT4", package: "containerization"),
            .product(name: "ContainerizationArchive", package: "containerization"),
            .product(name: "ContainerizationError", package: "containerization"),
        ]
    )
]
```

### 13.2 Import Statements

```swift
// Core containerization
import Containerization

// OCI image support
import ContainerizationOCI

// Filesystem support
import ContainerizationEXT4

// Archive handling
import ContainerizationArchive

// Error types
import ContainerizationError

// XPC communication (for advanced use)
import ContainerXPC

// Client library (for advanced use)
import ContainerClient
```

---

## 14. Platform Requirements and Limitations

### 14.1 Platform Support

- **Required:** Apple silicon Macs (M1, M2, M3, etc.)
- **macOS Version:** macOS 26 or later
- **Architecture:** arm64 only

### 14.2 Known Limitations

1. **Memory Ballooning:** Partial support for dynamic memory allocation
2. **Network Routing:** Some network routing constraints exist
3. **Platform-Specific:** macOS 15 has additional restrictions
4. **Performance:** Each container runs in its own lightweight VM, which provides strong isolation but uses more resources than traditional containers

### 14.3 Feature Availability

- Full network management requires macOS 26+
- Rosetta 2 support for linux/amd64 containers
- Nested virtualization support (limited)

---

## 15. Best Practices

### 15.1 Resource Management

```swift
// Always specify resource limits
let container = try await manager.create("container-id", image: image) { config in
    config.cpus = 2
    config.memoryInBytes = 2.gib()
}

// Clean up containers when done
defer {
    try? await container.stop()
    try? await manager.delete("container-id")
}
```

### 15.2 Error Handling

```swift
do {
    let container = try await manager.create("my-container", reference: "nginx:latest") { _ in }
    try await container.start()
} catch let error as ContainerizationError {
    if error.isCode(.notFound) {
        print("Image not found")
    } else if error.isCode(.exists) {
        print("Container already exists")
    } else {
        print("Error: \(error.message)")
    }
}
```

### 15.3 Async/Await Patterns

```swift
// Use async/await for container operations
async {
    let container = try await manager.create("my-container", reference: "nginx") { _ in }
    try await container.create()
    try await container.start()

    // Execute multiple processes concurrently
    async let process1 = container.exec("proc1") { $0.args = ["/bin/sh"] }
    async let process2 = container.exec("proc2") { $0.args = ["/bin/bash"] }

    let (p1, p2) = try await (process1, process2)
}
```

### 15.4 Network Isolation

```swift
// Create isolated network for containers
let network = try VmnetNetwork(subnet: "192.168.100.0/24")

// Use separate networks for different environments
let devNetwork = try VmnetNetwork(subnet: "192.168.10.0/24")
let prodNetwork = try VmnetNetwork(subnet: "192.168.20.0/24")
```

---

## 16. Security Considerations

### 16.1 Isolation Model

Each container runs in its own lightweight VM, providing strong isolation:
- Dedicated kernel per container
- Separate memory space
- Network isolation via vmnet
- Filesystem isolation

### 16.2 Capabilities and Privileges

```swift
// Configure Linux capabilities in OCI spec
var spec = Spec()
spec.process?.capabilities = LinuxCapabilities(
    bounding: ["CAP_NET_BIND_SERVICE"],
    effective: ["CAP_NET_BIND_SERVICE"],
    inheritable: [],
    permitted: ["CAP_NET_BIND_SERVICE"],
    ambient: []
)
```

### 16.3 Seccomp Profiles

```swift
// Configure seccomp for system call filtering
spec.linux?.seccomp = LinuxSeccomp(
    defaultAction: .allow,
    syscalls: [
        LinuxSyscall(
            names: ["chmod", "chown"],
            action: .errno
        )
    ]
)
```

---

## 17. Debugging and Monitoring

### 17.1 Container Statistics

```swift
// Get container resource usage
let stats = try await container.statistics()
print("CPU usage: \(stats.cpu)")
print("Memory usage: \(stats.memory)")
```

### 17.2 Boot Logs

```swift
// Enable boot logging
let vmm = VZVirtualMachineManager(
    kernel: kernel,
    initialFilesystem: initfs,
    bootlog: URL(filePath: "/tmp/boot.log"),
    logger: logger
)
```

### 17.3 Process Monitoring

```swift
// Monitor process exit
let exitStatus = try await process.wait(timeoutInSeconds: 30)
if exitStatus.exitCode != 0 {
    print("Process failed with code: \(exitStatus.exitCode)")
}
```

---

## 18. Advanced Topics

### 18.1 Custom Init Systems

The framework includes `vminitd`, a lightweight init system with gRPC API for:
- Process management
- Filesystem operations
- Network configuration
- Environment management

### 18.2 XPC Service Communication

For building custom services that communicate with containers:

```swift
let client = XPCClient(service: "com.example.container-service")
let message = XPCMessage(route: "custom.operation")
message.set(key: "param", value: "value")

let response = try await client.send(message)
```

### 18.3 Vsock Communication

For direct communication between host and guest:

```swift
// In container, listen on vsock port
let stream = VsockConnectionStream(port: 9000)

for await connection in stream.connections {
    // Handle connection
}

// From host, dial vsock port
let handle = try await container.dialVsock(port: 9000)
```

---

## 19. Migration from Other Container Runtimes

### 19.1 Docker Compatibility

The framework uses OCI-compatible images, so most Docker images work:

```bash
# Pull Docker image
container image pull docker.io/library/nginx:latest

# Run with similar syntax
container run -p 8080:80 nginx:latest
```

### 19.2 Differences from Docker

- Each container runs in a separate VM for stronger isolation
- Slightly higher resource usage per container
- Sub-second start times for lightweight VMs
- Native integration with macOS frameworks

---

## 20. Troubleshooting

### 20.1 Common Errors

**Error:** `ContainerizationError.notFound`
- **Solution:** Pull the image first using `container image pull`

**Error:** `ContainerizationError.exists`
- **Solution:** Use a different container ID or delete the existing container

**Error:** Network connection issues
- **Solution:** Check vmnet permissions and macOS version (26+ required for full support)

### 20.2 Logging

```swift
import Logging

let logger = Logger(label: "com.example.container")
logger.logLevel = .debug

let container = try await manager.create("my-container", reference: "nginx") { config in
    // Configuration
}
```

---

## Conclusion

The Apple Container Framework provides a comprehensive, Swift-native solution for running Linux containers on macOS. Its use of lightweight VMs provides strong isolation while maintaining performance, and its integration with Apple's Virtualization framework makes it a natural choice for macOS development.

Key advantages:
- Native Swift API with modern async/await support
- OCI compatibility for standard container images
- Strong isolation via per-container VMs
- Deep integration with macOS system frameworks
- Sub-second container start times

This documentation covers the major public APIs. For specific implementation details, refer to the source code at:
- https://github.com/apple/container
- https://github.com/apple/containerization

**Note:** The framework is currently pre-1.0.0, so breaking changes may occur between minor versions. Always check the release notes when upgrading.

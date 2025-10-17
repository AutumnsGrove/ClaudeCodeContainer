# Direct Virtualization.framework Usage Guide

**Purpose:** Technical guide for using Apple's Virtualization.framework directly
**Audience:** Developers considering custom VM solutions
**Complexity:** Advanced (Swift knowledge required)
**Status:** Reference implementation guide

---

## Overview

This guide provides technical details for using Apple's Virtualization.framework directly to create Linux VMs on macOS, which is the foundation underlying Apple's container framework, Lima, Colima, and other solutions.

**Note:** This is an advanced approach. For most use cases, use OrbStack, Colima, or Lima instead.

---

## When to Use Direct Virtualization.framework

### Good Reasons

1. **Custom Integration Requirements**
   - Need specific VM configurations not supported by existing tools
   - Building a custom tool/product on top of virtualization
   - Research and experimentation
   - Learning virtualization internals

2. **Special Use Cases**
   - Non-standard VM configurations
   - Custom device emulation
   - Specific security requirements
   - Integration with proprietary systems

### Bad Reasons

1. **"I want containers"** → Use OrbStack or Colima
2. **"Docker Desktop is too slow"** → Use OrbStack or Colima
3. **"I want better performance"** → Use OrbStack or Colima
4. **"I need it to work quickly"** → Use OrbStack or Colima

---

## Technical Requirements

### Platform Requirements

- **macOS Version:** macOS 11 (Big Sur) or later
  - macOS 13 (Ventura) or later for VirtioFS
  - macOS 14+ recommended for stability
- **Hardware:** Apple silicon or Intel Mac
- **Xcode:** Command Line Tools or full Xcode
- **Entitlements:** `com.apple.security.virtualization`
- **Optional:** `com.apple.vm.networking` (for bridged networking)

### Knowledge Requirements

- Swift programming language
- macOS development
- Linux kernel basics
- Virtualization concepts
- Networking fundamentals
- File system knowledge

**Estimated Learning Time:** 2-4 weeks for basic competency

---

## Architecture Overview

### Virtualization.framework Stack

```
┌─────────────────────────────────────┐
│     Your Swift Application          │
├─────────────────────────────────────┤
│   Virtualization.framework API      │
│   - VZVirtualMachine                │
│   - VZVirtualMachineConfiguration   │
│   - VZLinuxBootLoader               │
│   - VZVirtioDevices                 │
├─────────────────────────────────────┤
│   macOS Hypervisor.framework        │
├─────────────────────────────────────┤
│   Apple Silicon / Intel Hardware    │
└─────────────────────────────────────┘
```

### Key Components

1. **VZVirtualMachine**
   - Core VM object
   - Manages VM lifecycle (start, stop, pause)
   - Handles state transitions

2. **VZVirtualMachineConfiguration**
   - Defines VM hardware
   - CPU count, memory size
   - Devices (network, storage, display, etc.)

3. **VZLinuxBootLoader**
   - Boots Linux kernel
   - Provides kernel and initrd
   - Sets kernel command-line arguments

4. **VirtIO Devices**
   - VZVirtioBlockDeviceConfiguration (storage)
   - VZVirtioNetworkDeviceConfiguration (network)
   - VZVirtioFileSystemDeviceConfiguration (file sharing)
   - VZVirtioEntropyDeviceConfiguration (RNG)
   - VZVirtioConsoleDeviceConfiguration (serial)

---

## Implementation Guide

### Step 1: Project Setup

#### Create Swift Project

```bash
mkdir MyVMProject
cd MyVMProject
swift package init --type executable
```

#### Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyVMProject",
    platforms: [
        .macOS(.v13)  // Minimum for VirtioFS
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MyVMProject",
            dependencies: []
        )
    ]
)
```

#### Add Entitlements

Create `MyVMProject.entitlements`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.virtualization</key>
    <true/>
</dict>
</plist>
```

### Step 2: Basic VM Configuration

#### Minimal VM Example

```swift
import Foundation
import Virtualization

class SimpleVM {
    private var virtualMachine: VZVirtualMachine?

    func createVM() throws {
        // Create configuration
        let config = VZVirtualMachineConfiguration()

        // Set CPU count (2-4 cores typical)
        config.cpuCount = 2

        // Set memory size (4GB = 4 * 1024 * 1024 * 1024)
        config.memorySize = 4 * 1024 * 1024 * 1024

        // Configure boot loader
        let bootLoader = VZLinuxBootLoader(
            kernelURL: URL(fileURLWithPath: "/path/to/vmlinuz")
        )
        bootLoader.initialRamdiskURL = URL(fileURLWithPath: "/path/to/initrd.img")
        bootLoader.commandLine = "console=hvc0 root=/dev/vda"
        config.bootLoader = bootLoader

        // Add entropy device (required for Linux)
        let entropyDevice = VZVirtioEntropyDeviceConfiguration()
        config.entropyDevices = [entropyDevice]

        // Add network device
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        config.networkDevices = [networkDevice]

        // Add storage device
        let diskURL = URL(fileURLWithPath: "/path/to/disk.img")
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(
            url: diskURL,
            readOnly: false
        )
        let storageDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        config.storageDevices = [storageDevice]

        // Add console device
        let consoleDevice = VZVirtioConsoleDeviceConfiguration()
        let consolePort = VZVirtioConsolePortConfiguration()
        consolePort.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: FileHandle.standardInput,
            fileHandleForWriting: FileHandle.standardOutput
        )
        consoleDevice.ports[0] = consolePort
        config.consoleDevices = [consoleDevice]

        // Validate configuration
        try config.validate()

        // Create VM
        virtualMachine = VZVirtualMachine(configuration: config)
    }

    func start() {
        guard let vm = virtualMachine else {
            print("VM not created")
            return
        }

        vm.start { result in
            switch result {
            case .success:
                print("VM started successfully")
            case .failure(let error):
                print("Failed to start VM: \\(error)")
            }
        }
    }

    func stop() {
        virtualMachine?.stop { error in
            if let error = error {
                print("Error stopping VM: \\(error)")
            } else {
                print("VM stopped")
            }
        }
    }
}

// Usage
do {
    let vm = SimpleVM()
    try vm.createVM()
    vm.start()

    // Keep running
    RunLoop.main.run()
} catch {
    print("Error: \\(error)")
}
```

### Step 3: File Sharing (VirtioFS)

```swift
import Virtualization

func configureFileSharing(
    config: VZVirtualMachineConfiguration,
    hostPath: String,
    tag: String
) throws {
    guard #available(macOS 13.0, *) else {
        throw NSError(
            domain: "FileSharing",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "VirtioFS requires macOS 13+"]
        )
    }

    // Create directory share
    let sharedDirectory = VZSharedDirectory(
        url: URL(fileURLWithPath: hostPath),
        readOnly: false
    )

    let share = VZSingleDirectoryShare(directory: sharedDirectory)

    // Create file system device
    let fileSystemDevice = VZVirtioFileSystemDeviceConfiguration(tag: tag)
    fileSystemDevice.share = share

    config.directorySharingDevices = [fileSystemDevice]
}

// Usage
let config = VZVirtualMachineConfiguration()
try configureFileSharing(
    config: config,
    hostPath: "/Users/username/shared",
    tag: "shared"
)
```

**Guest Linux mounting:**

```bash
# Inside the Linux VM
mount -t virtiofs shared /mnt/shared
```

### Step 4: Network Configuration

#### NAT Network (Default)

```swift
func configureNATNetwork(config: VZVirtualMachineConfiguration) {
    let networkDevice = VZVirtioNetworkDeviceConfiguration()

    // Create NAT attachment
    networkDevice.attachment = VZNATNetworkDeviceAttachment()

    // Optional: Set MAC address
    let macAddress = VZMACAddress.randomLocallyAdministered()
    networkDevice.macAddress = macAddress

    config.networkDevices = [networkDevice]
}
```

**Network details:**
- VM gets IP in 192.168.64.x range
- Can access internet
- Host can't directly connect to VM (use port forwarding)

#### Bridged Network (Requires Entitlement)

```swift
func configureBridgedNetwork(
    config: VZVirtualMachineConfiguration,
    interfaceName: String
) throws {
    // Requires: com.apple.vm.networking entitlement
    // Must be obtained from Apple (not available to all developers)

    let interface = VZBridgedNetworkInterface.networkInterfaces
        .first { $0.identifier == interfaceName }

    guard let interface = interface else {
        throw NSError(
            domain: "Network",
            code: 2,
            userInfo: [NSLocalizedDescriptionKey: "Interface not found"]
        )
    }

    let networkDevice = VZVirtioNetworkDeviceConfiguration()
    networkDevice.attachment = VZBridgedNetworkDeviceAttachment(interface: interface)

    config.networkDevices = [networkDevice]
}
```

**Note:** Bridged networking requires special entitlement from Apple, not generally available.

### Step 5: Storage Configuration

#### Create Disk Image

```bash
# Create 10GB raw disk image
dd if=/dev/zero of=disk.img bs=1m count=10240

# Or use macOS sparse image
hdiutil create -size 10g -type UDIF -fs "Case-sensitive APFS" disk.img
```

#### Configure Storage in Swift

```swift
func configureStorage(
    config: VZVirtualMachineConfiguration,
    diskPath: String
) throws {
    let diskURL = URL(fileURLWithPath: diskPath)

    // Check if disk exists, create if not
    if !FileManager.default.fileExists(atPath: diskPath) {
        // Create empty disk file
        FileManager.default.createFile(atPath: diskPath, contents: nil)

        // Resize to desired size (10GB)
        let size: UInt64 = 10 * 1024 * 1024 * 1024
        try (diskURL as NSURL).setResourceValue(size, forKey: .fileSizeKey)
    }

    // Create disk attachment
    let diskAttachment = try VZDiskImageStorageDeviceAttachment(
        url: diskURL,
        readOnly: false
    )

    // Create storage device
    let storageDevice = VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)

    config.storageDevices = [storageDevice]
}
```

### Step 6: Linux Kernel Setup

#### Obtaining Linux Kernel

**Option 1: Use distribution kernel**

```bash
# Download Alpine Linux (lightweight)
curl -LO https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/aarch64/alpine-virt-3.18.0-aarch64.iso

# Extract kernel and initrd from ISO
mkdir -p iso-mount
hdiutil mount alpine-virt-3.18.0-aarch64.iso -mountpoint iso-mount
cp iso-mount/boot/vmlinuz-virt ./vmlinuz
cp iso-mount/boot/initramfs-virt ./initrd
hdiutil unmount iso-mount
```

**Option 2: Build custom kernel**

```bash
# Clone Linux kernel
git clone https://github.com/torvalds/linux.git
cd linux

# Configure for virtualization
make defconfig
# Enable: VIRTIO, VIRTIO_FS, VIRTIO_NET, VIRTIO_BLK, etc.

# Build
make -j$(sysctl -n hw.ncpu)

# Result: arch/arm64/boot/Image (for Apple silicon)
```

#### Boot Loader Configuration

```swift
func configureBootLoader(
    config: VZVirtualMachineConfiguration,
    kernelPath: String,
    initrdPath: String
) {
    let bootLoader = VZLinuxBootLoader(
        kernelURL: URL(fileURLWithPath: kernelPath)
    )

    bootLoader.initialRamdiskURL = URL(fileURLWithPath: initrdPath)

    // Kernel command line
    bootLoader.commandLine = [
        "console=hvc0",           // Use virtio console
        "root=/dev/vda",          // Root on first virtio disk
        "rootfstype=ext4",        // Filesystem type
        "rw",                     // Read-write
        "init=/sbin/init"         // Init system
    ].joined(separator: " ")

    config.bootLoader = bootLoader
}
```

### Step 7: Complete VM Manager

```swift
import Foundation
import Virtualization

class VMManager: NSObject {
    private var virtualMachine: VZVirtualMachine?
    private let vmConfig: VMConfiguration

    struct VMConfiguration {
        let cpuCount: Int
        let memorySize: UInt64  // in bytes
        let kernelPath: String
        let initrdPath: String
        let diskPath: String
        let sharedPath: String?
    }

    init(config: VMConfiguration) {
        self.vmConfig = config
        super.init()
    }

    func createAndStartVM() throws {
        let config = VZVirtualMachineConfiguration()

        // CPU and Memory
        config.cpuCount = vmConfig.cpuCount
        config.memorySize = vmConfig.memorySize

        // Boot Loader
        let bootLoader = VZLinuxBootLoader(
            kernelURL: URL(fileURLWithPath: vmConfig.kernelPath)
        )
        bootLoader.initialRamdiskURL = URL(fileURLWithPath: vmConfig.initrdPath)
        bootLoader.commandLine = "console=hvc0 root=/dev/vda rw"
        config.bootLoader = bootLoader

        // Entropy (required)
        config.entropyDevices = [VZVirtioEntropyDeviceConfiguration()]

        // Network
        let networkDevice = VZVirtioNetworkDeviceConfiguration()
        networkDevice.attachment = VZNATNetworkDeviceAttachment()
        config.networkDevices = [networkDevice]

        // Storage
        let diskURL = URL(fileURLWithPath: vmConfig.diskPath)
        let diskAttachment = try VZDiskImageStorageDeviceAttachment(
            url: diskURL,
            readOnly: false
        )
        config.storageDevices = [
            VZVirtioBlockDeviceConfiguration(attachment: diskAttachment)
        ]

        // Console
        let consoleDevice = VZVirtioConsoleDeviceConfiguration()
        let consolePort = VZVirtioConsolePortConfiguration()
        consolePort.attachment = VZFileHandleSerialPortAttachment(
            fileHandleForReading: .standardInput,
            fileHandleForWriting: .standardOutput
        )
        consoleDevice.ports[0] = consolePort
        config.consoleDevices = [consoleDevice]

        // File Sharing (if specified)
        if let sharedPath = vmConfig.sharedPath {
            let share = VZSingleDirectoryShare(
                directory: VZSharedDirectory(
                    url: URL(fileURLWithPath: sharedPath),
                    readOnly: false
                )
            )
            let fsDevice = VZVirtioFileSystemDeviceConfiguration(tag: "shared")
            fsDevice.share = share
            config.directorySharingDevices = [fsDevice]
        }

        // Validate
        try config.validate()

        // Create VM
        virtualMachine = VZVirtualMachine(configuration: config)
        virtualMachine?.delegate = self

        // Start VM
        virtualMachine?.start { result in
            switch result {
            case .success:
                print("✅ VM started successfully")
            case .failure(let error):
                print("❌ Failed to start VM: \\(error)")
            }
        }
    }

    func stop() {
        virtualMachine?.stop { error in
            if let error = error {
                print("Error stopping VM: \\(error)")
            }
        }
    }
}

// MARK: - VZVirtualMachineDelegate

extension VMManager: VZVirtualMachineDelegate {
    func guestDidStop(_ virtualMachine: VZVirtualMachine) {
        print("VM stopped")
        exit(0)
    }

    func virtualMachine(
        _ virtualMachine: VZVirtualMachine,
        didStopWithError error: Error
    ) {
        print("VM stopped with error: \\(error)")
        exit(1)
    }
}

// MARK: - Usage

let config = VMManager.VMConfiguration(
    cpuCount: 2,
    memorySize: 4 * 1024 * 1024 * 1024,  // 4GB
    kernelPath: "/path/to/vmlinuz",
    initrdPath: "/path/to/initrd",
    diskPath: "/path/to/disk.img",
    sharedPath: "/Users/username/shared"
)

do {
    let manager = VMManager(config: config)
    try manager.createAndStartVM()

    // Keep running
    RunLoop.main.run()
} catch {
    print("Error: \\(error)")
    exit(1)
}
```

---

## Known Limitations and Issues

### Framework Limitations

1. **No USB Support**
   - Cannot passthrough USB devices
   - No USB storage, no USB peripherals

2. **No Framebuffer API (Public)**
   - Text console only
   - No GUI display support in public API
   - Workaround: Use VNC or remote display

3. **Limited Device Support**
   - Only VirtIO devices
   - No PCI passthrough
   - No GPU passthrough (on Apple silicon)

4. **Network Constraints**
   - Bridged mode requires special entitlement
   - NAT mode only for most developers
   - Port forwarding manual setup needed

### Known Bugs

1. **Crash with Certain Configurations**
   - Specific Linux kernel versions may crash
   - macOS version compatibility issues
   - Architecture-specific bugs (ARM vs Intel)

2. **VirtioFS Performance**
   - Can be 3-10x slower than native
   - Improved in macOS 13+ but still overhead
   - Large file operations particularly affected

3. **Memory Management**
   - Memory not always properly released
   - Potential leaks in long-running VMs
   - Requires careful resource management

4. **State Management**
   - VM state transitions can be buggy
   - Pause/resume not always reliable
   - Snapshot support limited

---

## Performance Optimization

### CPU Optimization

```swift
// Use appropriate CPU count
// More isn't always better - overhead exists
let cpuCount = min(
    ProcessInfo.processInfo.processorCount - 2,  // Leave 2 for host
    8  // Cap at 8 for diminishing returns
)
config.cpuCount = max(2, cpuCount)  // Minimum 2
```

### Memory Optimization

```swift
// Balance memory allocation
// Too much: waste and pressure on host
// Too little: poor guest performance
let totalMemory = ProcessInfo.processInfo.physicalMemory
let vmMemory = UInt64(Double(totalMemory) * 0.5)  // Use 50% max
config.memorySize = vmMemory
```

### Storage Optimization

1. **Use Raw Images:**
   - Faster than qcow2
   - Better performance
   - Simpler management

2. **Pre-allocate Space:**
   ```bash
   # Pre-allocate 10GB
   dd if=/dev/zero of=disk.img bs=1m count=10240
   ```

3. **Use SSD:**
   - Store VM images on SSD
   - Significant performance improvement

### Network Optimization

1. **Use NAT Mode:**
   - Simpler and often faster
   - No special entitlements needed

2. **Configure Guest Properly:**
   ```bash
   # In guest, use virtio_net driver
   # Enable checksum offload
   ethtool -K eth0 tx on rx on
   ```

---

## Comparison with Existing Tools

### vs. Lima/Colima

**Direct Framework:**
- ✅ Full control
- ✅ Custom configurations
- ❌ Much more code
- ❌ Manual everything

**Lima/Colima:**
- ✅ Pre-built solution
- ✅ Tested and stable
- ✅ Good defaults
- ❌ Less flexibility

**Verdict:** Use Lima/Colima unless specific need for custom solution.

### vs. Apple Container

**Direct Framework:**
- ✅ Stable Virtualization.framework
- ✅ Full control
- ✅ No container abstraction bugs
- ❌ Much more complexity

**Apple Container:**
- ✅ Container-focused
- ✅ OCI compatible
- ❌ Early stage (v0.5.0)
- ❌ Known bugs

**Verdict:** Direct framework is more stable but way more complex.

### Development Time

| Task | Lima/Colima | Direct Framework |
|------|-------------|------------------|
| Setup | 15 min | 2-3 weeks |
| Basic VM | Works | 1 week |
| File sharing | Works | 3-4 days |
| Networking | Works | 2-3 days |
| Debugging | Easy | Hard |
| Maintenance | Minimal | Significant |

---

## When Direct Framework Makes Sense

### Good Use Cases

1. **Building a Product**
   - Creating your own virtualization tool
   - Need specific features not in existing tools
   - Have development resources

2. **Research**
   - Learning virtualization internals
   - Experimenting with VM configurations
   - Academic purposes

3. **Custom Integration**
   - Specific corporate requirements
   - Integration with proprietary systems
   - Custom security models

### Bad Use Cases

1. **"I need containers"** → Use Colima
2. **"I want better performance than Docker"** → Use OrbStack
3. **"Docker Desktop is too expensive"** → Use Colima (free)
4. **"I want it working today"** → Use OrbStack or Colima

---

## Resources

### Official Documentation

- **Virtualization Framework:** https://developer.apple.com/documentation/virtualization
- **WWDC 2022 Session:** "Create macOS or Linux virtual machines"
- **Sample Code:** Apple Developer sample projects

### Community Resources

- **vftool:** https://github.com/evansm7/vftool (minimal wrapper)
- **SimpleVM:** https://github.com/KhaosT/SimpleVM (example implementation)
- **vmcli:** https://github.com/gyf304/vmcli (command-line tool)

### Learning Resources

- Apple Developer Forums (Virtualization tag)
- Stack Overflow (macos-virtualization tag)
- GitHub repositories using Virtualization.framework

---

## Conclusion

### Should You Use Direct Virtualization.framework?

**Probably Not.**

Unless you have specific requirements that existing tools don't meet, using pre-built solutions like OrbStack, Colima, or Lima will save you weeks of development time and provide better reliability.

### If You Do Decide to Use It

Expect:
- **2-4 weeks** to basic competency
- **1-2 months** to production-ready solution
- **Ongoing maintenance** burden
- **Deep debugging** sessions

Benefits:
- **Full control** over configuration
- **Custom features** possible
- **Learning experience** valuable
- **No dependencies** on third-party tools

### Recommendation

1. **Start with Colima or OrbStack**
2. **Only build custom if:**
   - Existing tools don't meet requirements
   - You have development resources
   - You need specific customizations
   - You're building a product on top

**For 99% of use cases: Use existing tools.**

---

**Document Status:** Complete
**Accuracy:** Based on macOS 13-14, subject to changes
**Maintenance:** Review annually or with major macOS releases
**Complexity Rating:** 5/5 (Very Complex)

**Recommended Instead:**
- OrbStack: https://orbstack.dev
- Colima: https://github.com/abiosoft/colima
- Lima: https://lima-vm.io

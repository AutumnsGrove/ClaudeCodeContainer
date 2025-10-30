#!/usr/bin/env swift

// container-with-workspace.swift
// Container with mounted directories for file sharing between host and container

import Foundation
import Containerization

// MARK: - Container with Workspace Example

@main
struct ContainerWithWorkspace {
    static func main() async throws {
        print("Starting container with workspace example...")

        // Initialize client
        let client = try await ContainerClient()

        // Ensure system is running
        guard try await client.healthCheck() else {
            print("Container system not running. Run: container system start")
            exit(1)
        }

        // Create a workspace directory
        let workspaceURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("container-workspace-\(UUID().uuidString)")

        try FileManager.default.createDirectory(
            at: workspaceURL,
            withIntermediateDirectories: true
        )

        print("Created workspace at: \(workspaceURL.path)")

        // Create some test files in workspace
        try await createTestFiles(in: workspaceURL)

        // Configure container with mounted workspace
        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "=== Files in workspace ==="
                ls -la /workspace
                echo ""
                echo "=== Reading host file ==="
                cat /workspace/hello.txt
                echo ""
                echo "=== Writing from container ==="
                echo "Written by container at $(date)" > /workspace/container-output.txt
                echo "File written successfully"
                """])
            .withMount(.bind(
                source: workspaceURL.path,
                target: "/workspace",
                readonly: false
            ))

        // Run container
        print("\nRunning container with workspace mounted...")
        let container = try await client.createContainer(config)

        try await container.start()
        _ = try await container.wait()

        // Read file created by container
        let outputFile = workspaceURL.appendingPathComponent("container-output.txt")
        if FileManager.default.fileExists(atPath: outputFile.path) {
            let content = try String(contentsOf: outputFile)
            print("\n✅ Container created file with content:")
            print(content)
        }

        // Cleanup
        try await container.delete()
        try FileManager.default.removeItem(at: workspaceURL)

        print("\n✅ Workspace example completed successfully!")
    }

    static func createTestFiles(in directory: URL) async throws {
        // Create test file
        let helloFile = directory.appendingPathComponent("hello.txt")
        try "Hello from host system!".write(
            to: helloFile,
            atomically: true,
            encoding: .utf8
        )

        // Create subdirectory with files
        let subDir = directory.appendingPathComponent("data")
        try FileManager.default.createDirectory(
            at: subDir,
            withIntermediateDirectories: true
        )

        let dataFile = subDir.appendingPathComponent("data.json")
        let jsonData = try JSONSerialization.data(withJSONObject: [
            "message": "Test data",
            "timestamp": Date().timeIntervalSince1970
        ])
        try jsonData.write(to: dataFile)
    }
}

// MARK: - Development Workflow Example

struct DevelopmentWorkspace {
    static func runDevelopmentContainer() async throws {
        let client = try await ContainerClient()

        // Use current directory as workspace
        let currentDir = FileManager.default.currentDirectoryPath

        print("Setting up development container for: \(currentDir)")

        // Multiple mounts for development
        let config = ContainerConfiguration()
            .withImage("node:16-alpine")
            .withCommand(["sh", "-c", """
                cd /app
                echo "Installing dependencies..."
                npm install
                echo "Running development server..."
                npm run dev
                """])
            .withWorkingDir("/app")
            .withMount(.bind(
                source: currentDir,
                target: "/app",
                readonly: false
            ))
            .withMount(.bind(
                source: "\(NSHomeDirectory())/.npm",
                target: "/root/.npm",
                readonly: false
            ))
            .withEnvironment([
                "NODE_ENV": "development",
                "NPM_CONFIG_CACHE": "/root/.npm"
            ])
            .withNetwork("dev-network")

        let container = try await client.createContainer(config)
        try await container.start()

        print("Development container started with ID: \(container.id)")
        print("Workspace mounted at /app inside container")
        print("Use 'container exec -it \(container.id) sh' to access")

        // Wait for user input
        print("\nPress Enter to stop development container...")
        _ = readLine()

        try await container.stop()
        try await container.delete()
    }
}

// MARK: - Read-Only Mount Example

struct ReadOnlyWorkspace {
    static func runWithReadOnlyMount() async throws {
        let client = try await ContainerClient()

        // Mount system directories as read-only
        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "=== Examining read-only mounts ==="
                echo "Config files:"
                ls -la /config/ 2>/dev/null || echo "No config directory"
                echo ""
                echo "Trying to write (should fail):"
                echo "test" > /config/test.txt 2>&1 || echo "✓ Write prevented as expected"
                """])
            .withMount(.bind(
                source: "/etc",
                target: "/config",
                readonly: true
            ))

        let container = try await client.createContainer(config)
        try await container.start()
        _ = try await container.wait()
        try await container.delete()

        print("✅ Read-only mount example completed")
    }
}

// MARK: - Volume Sharing Between Containers

struct SharedVolume {
    static func demonstrateVolumeSharing() async throws {
        let client = try await ContainerClient()

        // Create a named volume
        let volumeName = "shared-data-\(UUID().uuidString.prefix(8))"

        print("Creating shared volume: \(volumeName)")

        // First container: Write data to volume
        let writerConfig = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "Creating data in shared volume..."
                echo "Timestamp: $(date)" > /data/timestamp.txt
                echo "Random: $RANDOM" > /data/random.txt
                echo "Data written successfully"
                ls -la /data/
                """])
            .withMount(.volume(
                name: volumeName,
                target: "/data",
                readonly: false
            ))

        print("\n1. Writing data to volume...")
        let writer = try await client.createContainer(writerConfig)
        try await writer.start()
        _ = try await writer.wait()
        try await writer.delete()

        // Second container: Read data from volume
        let readerConfig = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "Reading data from shared volume..."
                echo "Contents of /data:"
                ls -la /data/
                echo ""
                echo "Timestamp file:"
                cat /data/timestamp.txt
                echo "Random file:"
                cat /data/random.txt
                """])
            .withMount(.volume(
                name: volumeName,
                target: "/data",
                readonly: true
            ))

        print("\n2. Reading data from volume...")
        let reader = try await client.createContainer(readerConfig)
        try await reader.start()
        _ = try await reader.wait()
        try await reader.delete()

        print("\n✅ Volume sharing demonstration completed")
    }
}

// MARK: - Complex Mount Configuration

struct ComplexMounts {
    static func runWithMultipleMounts() async throws {
        let client = try await ContainerClient()

        // Create temporary directories
        let tempDir = FileManager.default.temporaryDirectory
        let configDir = tempDir.appendingPathComponent("config")
        let dataDir = tempDir.appendingPathComponent("data")
        let logsDir = tempDir.appendingPathComponent("logs")

        try FileManager.default.createDirectory(at: configDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: dataDir, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: logsDir, withIntermediateDirectories: true)

        // Create config file
        let configFile = configDir.appendingPathComponent("app.conf")
        try "debug=true\nport=8080".write(to: configFile, atomically: true, encoding: .utf8)

        // Configure container with multiple mounts
        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "=== Mount Points ==="
                mount | grep -E '(config|data|logs|tmp)'
                echo ""
                echo "=== Config (read-only) ==="
                cat /config/app.conf
                echo ""
                echo "=== Writing to data ==="
                echo "Application data" > /data/app.dat
                echo ""
                echo "=== Writing to logs ==="
                echo "[$(date)] Application started" > /logs/app.log
                echo ""
                echo "=== Writing to tmpfs ==="
                dd if=/dev/zero of=/tmp/test bs=1M count=10 2>/dev/null
                ls -lh /tmp/test
                echo ""
                echo "✓ All mounts working correctly"
                """])
            .withMount(.bind(
                source: configDir.path,
                target: "/config",
                readonly: true
            ))
            .withMount(.bind(
                source: dataDir.path,
                target: "/data",
                readonly: false
            ))
            .withMount(.bind(
                source: logsDir.path,
                target: "/logs",
                readonly: false
            ))
            .withMount(.tmpfs(
                target: "/tmp",
                size: 104857600  // 100MB
            ))

        print("Running container with complex mount configuration...")
        let container = try await client.createContainer(config)
        try await container.start()
        _ = try await container.wait()

        // Verify files were created
        let dataFile = dataDir.appendingPathComponent("app.dat")
        let logFile = logsDir.appendingPathComponent("app.log")

        if FileManager.default.fileExists(atPath: dataFile.path) {
            print("\n✅ Data file created by container")
        }
        if FileManager.default.fileExists(atPath: logFile.path) {
            let logContent = try String(contentsOf: logFile)
            print("✅ Log file created: \(logContent)")
        }

        // Cleanup
        try await container.delete()
        try FileManager.default.removeItem(at: tempDir)

        print("\n✅ Complex mount example completed")
    }
}

// MARK: - Usage Notes

/*
 To run these examples:

 1. Direct execution:
    chmod +x container-with-workspace.swift
    ./container-with-workspace.swift

 2. Compile and run:
    swiftc container-with-workspace.swift -o container-workspace
    ./container-workspace

 3. Run specific examples:
    - DevelopmentWorkspace.runDevelopmentContainer()
    - ReadOnlyWorkspace.runWithReadOnlyMount()
    - SharedVolume.demonstrateVolumeSharing()
    - ComplexMounts.runWithMultipleMounts()

 Important Notes:
 - Ensure container system is running: container system start
 - Some mounts may require additional permissions
 - Volumes persist until explicitly removed
 - tmpfs mounts use memory, not disk storage
 */

// MARK: - Best Practices

/*
 Workspace Mounting Best Practices:

 1. Security:
    - Use read-only mounts when possible
    - Never mount sensitive directories (e.g., ~/.ssh)
    - Validate mount sources before mounting

 2. Performance:
    - Mount only necessary directories
    - Use volumes for data that doesn't need host access
    - tmpfs for temporary data improves performance

 3. Portability:
    - Use relative paths when possible
    - Document required mount points
    - Provide defaults for missing mounts

 4. Development:
    - Mount source code for hot reload
    - Use volume for dependencies (node_modules, etc.)
    - Separate config, data, and logs

 5. Production:
    - Use named volumes for persistent data
    - Implement proper backup strategies
    - Monitor disk usage
 */
#!/usr/bin/env swift

// minimal-container.swift
// Simplest possible container implementation using Apple's Container Framework

import Foundation
import Containerization

// MARK: - Minimal Container Example

@main
struct MinimalContainer {
    static func main() async throws {
        print("Starting minimal container example...")

        // Initialize the container client
        let client = try await ContainerClient()

        // Ensure the container system is running
        let isHealthy = try await client.healthCheck()
        guard isHealthy else {
            print("Container system is not running. Please run: container system start")
            exit(1)
        }

        // Pull Alpine Linux image (smallest Linux distribution)
        print("Pulling alpine:latest image...")
        _ = try await client.images.pull("alpine:latest")

        // Create minimal container configuration
        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["echo", "Hello from minimal container!"])

        // Create and start the container
        print("Creating container...")
        let container = try await client.createContainer(config)

        print("Starting container with ID: \(container.id)")
        try await container.start()

        // Wait for container to complete
        print("Waiting for container to finish...")
        let exitCode = try await container.wait()

        print("Container exited with code: \(exitCode)")

        // Clean up
        print("Removing container...")
        try await container.delete()

        print("✅ Minimal container example completed successfully!")
    }
}

// MARK: - Alternative Implementations

// Using async streams for output
func minimalContainerWithOutput() async throws {
    let client = try await ContainerClient()

    let config = ContainerConfiguration()
        .withImage("alpine:latest")
        .withCommand(["sh", "-c", "for i in 1 2 3; do echo Line $i; sleep 1; done"])

    let container = try await client.createContainer(config)
    try await container.start()

    // Stream output
    if let process = try await container.exec(command: ["cat", "/proc/1/fd/1"]) {
        for await data in process.stdout {
            if let output = String(data: data, encoding: .utf8) {
                print("Output: \(output)", terminator: "")
            }
        }
    }

    _ = try await container.wait()
    try await container.delete()
}

// Interactive container
func minimalInteractiveContainer() async throws {
    let client = try await ContainerClient()

    let config = ContainerConfiguration()
        .withImage("alpine:latest")
        .withCommand(["/bin/sh"])
        .withEnvironment(["TERM": "xterm-256color"])

    let container = try await client.createContainer(config)
    try await container.start()

    // Attach to container for interactive use
    print("Container is running. Use 'container exec -it \(container.id) /bin/sh' to attach")
    print("Press Enter to stop and remove container...")
    _ = readLine()

    try await container.stop()
    try await container.delete()
}

// MARK: - Error Handling Example

func minimalContainerWithErrorHandling() async {
    do {
        let client = try await ContainerClient()

        // Check if image exists locally
        let images = try await client.images.list()
        let hasAlpine = images.contains { $0.reference.contains("alpine") }

        if !hasAlpine {
            print("Alpine image not found locally, pulling...")
            _ = try await client.images.pull("alpine:latest")
        }

        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["echo", "Hello World"])

        let container = try await client.createContainer(config)

        defer {
            // Ensure cleanup even if error occurs
            Task {
                try? await container.delete()
            }
        }

        try await container.start()
        let exitCode = try await container.wait()

        if exitCode != 0 {
            print("⚠️ Container exited with non-zero code: \(exitCode)")
        } else {
            print("✅ Container completed successfully")
        }

    } catch ContainerizationError.imageNotFound(let image) {
        print("❌ Image not found: \(image)")
    } catch ContainerizationError.containerNotFound(let id) {
        print("❌ Container not found: \(id)")
    } catch {
        print("❌ Unexpected error: \(error)")
    }
}

// MARK: - Usage Notes

/*
 To run this example:

 1. Save this file as minimal-container.swift
 2. Make it executable: chmod +x minimal-container.swift
 3. Ensure container system is running: container system start
 4. Run the script: ./minimal-container.swift

 Or compile and run:

 swiftc minimal-container.swift -o minimal-container
 ./minimal-container

 Requirements:
 - macOS 15+ (macOS 26 recommended)
 - Apple Silicon Mac
 - Container framework installed
 - Swift 6.2+
 */

// MARK: - Package.swift for SPM Integration

/*
 To use in a Swift Package Manager project, create Package.swift:

 // swift-tools-version:6.0
 import PackageDescription

 let package = Package(
     name: "MinimalContainer",
     platforms: [
         .macOS(.v15)
     ],
     dependencies: [
         .package(url: "https://github.com/apple/containerization", from: "0.9.1")
     ],
     targets: [
         .executableTarget(
             name: "MinimalContainer",
             dependencies: [
                 .product(name: "Containerization", package: "containerization")
             ]
         )
     ]
 )
 */
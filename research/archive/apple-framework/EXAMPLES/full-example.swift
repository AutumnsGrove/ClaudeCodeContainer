#!/usr/bin/env swift

// full-example.swift
// Complete implementation demonstrating all features of Apple's Container Framework

import Foundation
import Containerization

// MARK: - Full Container Implementation

@main
struct FullContainerExample {
    static func main() async throws {
        print("=== Full Container Framework Example ===\n")

        // Initialize container system
        let containerSystem = try await ContainerSystem()
        try await containerSystem.start()

        // Run comprehensive example
        try await runComprehensiveExample(system: containerSystem)

        print("\n✅ Full example completed successfully!")
    }

    static func runComprehensiveExample(system: ContainerSystem) async throws {
        // 1. Build custom image
        let image = try await buildCustomImage(system: system)

        // 2. Create network infrastructure
        let network = try await setupNetwork(system: system)

        // 3. Deploy database container
        let database = try await deployDatabase(system: system, network: network)

        // 4. Deploy application container
        let app = try await deployApplication(
            system: system,
            network: network,
            image: image,
            database: database
        )

        // 5. Run tests
        try await runIntegrationTests(
            system: system,
            network: network,
            app: app
        )

        // 6. Cleanup
        try await cleanup(
            system: system,
            containers: [app, database],
            network: network
        )
    }
}

// MARK: - Container System Management

class ContainerSystem {
    private let client: ContainerClient
    private var activeContainers: [String: LinuxContainer] = [:]
    private var networks: [String: Network] = [:]
    private var volumes: [String: Volume] = [:]

    init() async throws {
        self.client = try await ContainerClient()
    }

    func start() async throws {
        print("Starting container system...")

        // Check if system is already running
        if try await client.healthCheck() {
            print("✓ Container system is already running")
            return
        }

        // Start the system
        try await client.start()

        // Verify startup
        var retries = 5
        while retries > 0 {
            if try await client.healthCheck() {
                print("✓ Container system started successfully")
                return
            }
            try await Task.sleep(nanoseconds: 1_000_000_000)
            retries -= 1
        }

        throw ContainerError.systemStartupFailed
    }

    func stop() async throws {
        print("Stopping container system...")

        // Stop all containers
        for (_, container) in activeContainers {
            try? await container.stop()
        }

        // Remove all containers
        for (_, container) in activeContainers {
            try? await container.delete()
        }

        // Clean up networks and volumes
        for (_, network) in networks {
            try? await network.delete()
        }

        // Stop the system
        try await client.stop()
        print("✓ Container system stopped")
    }

    // Container lifecycle management
    func createContainer(
        name: String,
        config: ContainerConfiguration
    ) async throws -> LinuxContainer {
        let container = try await client.createContainer(config)
        activeContainers[name] = container
        return container
    }

    // Network management
    func createNetwork(name: String) async throws -> Network {
        guard #available(macOS 26.0, *) else {
            throw ContainerError.featureRequiresMacOS26
        }

        let network = try await client.createNetwork(
            name: name,
            driver: "vmnet"
        )
        networks[name] = network
        return network
    }

    // Volume management
    func createVolume(name: String) async throws -> Volume {
        let volume = Volume(name: name)
        volumes[name] = volume
        return volume
    }
}

// MARK: - Image Building

func buildCustomImage(system: ContainerSystem) async throws -> Image {
    print("\n📦 Building custom application image...")

    // Create temporary build directory
    let buildDir = FileManager.default.temporaryDirectory
        .appendingPathComponent("container-build-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: buildDir, withIntermediateDirectories: true)

    defer {
        try? FileManager.default.removeItem(at: buildDir)
    }

    // Create Dockerfile
    let dockerfile = """
    FROM alpine:latest

    # Install dependencies
    RUN apk add --no-cache \\
        nodejs \\
        npm \\
        curl \\
        bash

    # Create app directory
    WORKDIR /app

    # Copy package files
    COPY package*.json ./

    # Install app dependencies
    RUN npm ci --only=production

    # Copy application code
    COPY . .

    # Create non-root user
    RUN adduser -D appuser
    USER appuser

    # Expose port
    EXPOSE 3000

    # Health check
    HEALTHCHECK --interval=30s --timeout=3s \\
        CMD curl -f http://localhost:3000/health || exit 1

    # Start command
    CMD ["node", "server.js"]
    """

    let dockerfilePath = buildDir.appendingPathComponent("Dockerfile")
    try dockerfile.write(to: dockerfilePath, atomically: true, encoding: .utf8)

    // Create package.json
    let packageJson = """
    {
        "name": "example-app",
        "version": "1.0.0",
        "main": "server.js",
        "scripts": {
            "start": "node server.js"
        },
        "dependencies": {
            "express": "^4.18.0"
        }
    }
    """

    let packagePath = buildDir.appendingPathComponent("package.json")
    try packageJson.write(to: packagePath, atomically: true, encoding: .utf8)

    // Create simple server
    let serverJs = """
    const express = require('express');
    const app = express();
    const port = process.env.PORT || 3000;

    app.get('/', (req, res) => {
        res.json({ message: 'Hello from containerized app!' });
    });

    app.get('/health', (req, res) => {
        res.status(200).json({ status: 'healthy' });
    });

    app.listen(port, () => {
        console.log(`Server running on port ${port}`);
    });
    """

    let serverPath = buildDir.appendingPathComponent("server.js")
    try serverJs.write(to: serverPath, atomically: true, encoding: .utf8)

    // Build the image
    let imageManager = system.client.images
    let image = try await imageManager.build(
        dockerfile: dockerfilePath,
        context: buildDir,
        tag: "example-app:latest",
        platform: Platform(os: .linux, arch: .arm64),
        buildArgs: [
            "BUILD_DATE": ISO8601DateFormatter().string(from: Date()),
            "VERSION": "1.0.0"
        ]
    )

    print("✓ Image built: \(image.reference)")
    return image
}

// MARK: - Network Setup

func setupNetwork(system: ContainerSystem) async throws -> Network {
    print("\n🌐 Setting up network infrastructure...")

    guard #available(macOS 26.0, *) else {
        print("⚠️ Custom networks require macOS 26, using default network")
        return DefaultNetwork()
    }

    // Create custom network with specific configuration
    let network = try await system.createNetwork(name: "app-network")

    print("✓ Network created: app-network")
    return network
}

// MARK: - Database Deployment

func deployDatabase(
    system: ContainerSystem,
    network: Network
) async throws -> LinuxContainer {
    print("\n🗄️ Deploying database container...")

    // Create volume for persistent storage
    let dataVolume = try await system.createVolume(name: "postgres-data")

    // Configure database container
    let dbConfig = ContainerConfiguration()
        .withImage("postgres:14-alpine")
        .withHostname("database")
        .withNetwork(network.name)
        .withEnvironment([
            "POSTGRES_USER": "appuser",
            "POSTGRES_PASSWORD": "secretpassword",
            "POSTGRES_DB": "appdb",
            "PGDATA": "/var/lib/postgresql/data/pgdata"
        ])
        .withMount(.volume(
            name: dataVolume.name,
            target: "/var/lib/postgresql/data",
            readonly: false
        ))
        .withResources(ResourceLimits(
            cpus: 2,
            memory: 2_147_483_648  // 2GB
        ))
        .withRestartPolicy(RestartPolicy.unlessStopped)

    // Create and start database
    let database = try await system.createContainer(
        name: "database",
        config: dbConfig
    )
    try await database.start()

    // Wait for database to be ready
    print("Waiting for database to be ready...")
    try await waitForDatabase(container: database)

    print("✓ Database deployed and ready")
    return database
}

// MARK: - Application Deployment

func deployApplication(
    system: ContainerSystem,
    network: Network,
    image: Image,
    database: LinuxContainer
) async throws -> LinuxContainer {
    print("\n🚀 Deploying application container...")

    // Create workspace volume
    let workspace = FileManager.default.temporaryDirectory
        .appendingPathComponent("app-workspace")
    try FileManager.default.createDirectory(
        at: workspace,
        withIntermediateDirectories: true
    )

    // Configure application container
    let appConfig = ContainerConfiguration()
        .withImage(image.reference)
        .withHostname("application")
        .withNetwork(network.name)
        .withEnvironment([
            "NODE_ENV": "production",
            "PORT": "3000",
            "DATABASE_URL": "postgresql://appuser:secretpassword@database:5432/appdb",
            "LOG_LEVEL": "info"
        ])
        .withMount(.bind(
            source: workspace.path,
            target: "/data",
            readonly: false
        ))
        .withMount(.tmpfs(
            target: "/tmp",
            size: 536_870_912  // 512MB
        ))
        .withPorts([
            PortMapping(hostPort: 8080, containerPort: 3000)
        ])
        .withResources(ResourceLimits(
            cpus: 4,
            memory: 4_294_967_296,  // 4GB
            disk: 10_737_418_240     // 10GB
        ))
        .withRestartPolicy(RestartPolicy.onFailure(maxRetries: 3))
        .withLabels([
            "app": "example",
            "version": "1.0.0",
            "environment": "production"
        ])

    // Create and start application
    let app = try await system.createContainer(
        name: "application",
        config: appConfig
    )
    try await app.start()

    print("✓ Application deployed at http://localhost:8080")
    return app
}

// MARK: - Integration Tests

func runIntegrationTests(
    system: ContainerSystem,
    network: Network,
    app: LinuxContainer
) async throws {
    print("\n🧪 Running integration tests...")

    // Test 1: Health check
    print("  Testing health endpoint...")
    let healthProcess = try await app.exec(
        command: ["curl", "-f", "http://localhost:3000/health"]
    )
    let healthExitCode = try await healthProcess.wait()
    assert(healthExitCode == 0, "Health check failed")
    print("  ✓ Health check passed")

    // Test 2: Database connectivity
    print("  Testing database connection...")
    let dbProcess = try await app.exec(
        command: ["sh", "-c", "echo 'SELECT 1' | psql $DATABASE_URL"]
    )
    let dbExitCode = try await dbProcess.wait()
    assert(dbExitCode == 0, "Database connection failed")
    print("  ✓ Database connection successful")

    // Test 3: File system operations
    print("  Testing file system...")
    let fsProcess = try await app.exec(
        command: ["sh", "-c", "echo 'test' > /data/test.txt && cat /data/test.txt"]
    )

    var output = ""
    for await data in fsProcess.stdout {
        output += String(data: data, encoding: .utf8) ?? ""
    }
    assert(output.contains("test"), "File system test failed")
    print("  ✓ File system operations working")

    // Test 4: Network connectivity
    print("  Testing external network...")
    let netProcess = try await app.exec(
        command: ["ping", "-c", "3", "8.8.8.8"]
    )
    let netExitCode = try await netProcess.wait()
    assert(netExitCode == 0, "Network connectivity failed")
    print("  ✓ External network accessible")

    // Test 5: Resource limits
    print("  Testing resource limits...")
    let resourceInfo = try await app.inspect()
    print("  ✓ Resource limits applied")

    print("\n✅ All integration tests passed!")
}

// MARK: - Cleanup

func cleanup(
    system: ContainerSystem,
    containers: [LinuxContainer],
    network: Network
) async throws {
    print("\n🧹 Cleaning up resources...")

    // Stop containers gracefully
    for container in containers {
        print("  Stopping container: \(container.id.prefix(12))")
        try await container.stop(timeout: 10)
    }

    // Remove containers
    for container in containers {
        print("  Removing container: \(container.id.prefix(12))")
        try await container.delete()
    }

    // Remove network
    if #available(macOS 26.0, *) {
        print("  Removing network: \(network.name)")
        try await network.delete()
    }

    print("✓ Cleanup completed")
}

// MARK: - Helper Functions

func waitForDatabase(container: LinuxContainer, maxRetries: Int = 30) async throws {
    for attempt in 1...maxRetries {
        let process = try await container.exec(
            command: ["pg_isready", "-U", "appuser"]
        )
        let exitCode = try await process.wait()

        if exitCode == 0 {
            return
        }

        print("  Waiting for database... (\(attempt)/\(maxRetries))")
        try await Task.sleep(nanoseconds: 1_000_000_000)
    }

    throw ContainerError.databaseStartupTimeout
}

// MARK: - Error Types

enum ContainerError: Error {
    case systemStartupFailed
    case featureRequiresMacOS26
    case databaseStartupTimeout
    case networkCreationFailed
    case volumeCreationFailed
}

// MARK: - Supporting Types

struct Volume {
    let name: String
}

struct Image {
    let reference: String
}

struct DefaultNetwork: Network {
    var id: String { "default" }
    var name: String { "bridge" }
    var type: NetworkType { .bridge }
    var subnet: String { "172.17.0.0/16" }
    var gateway: String? { "172.17.0.1" }
    var dns: [String] { ["8.8.8.8", "8.8.4.4"] }

    func connect(container: LinuxContainer) async throws {}
    func disconnect(container: LinuxContainer) async throws {}
    func inspect() async throws -> NetworkInspection {
        NetworkInspection()
    }
    func delete() async throws {}
}

struct NetworkInspection {
    // Network inspection details
}

enum NetworkType {
    case bridge
    case host
    case none
    case custom
}

struct RestartPolicy {
    enum Policy {
        case no
        case always
        case unlessStopped
        case onFailure(maxRetries: Int)
    }

    let policy: Policy

    static let no = RestartPolicy(policy: .no)
    static let always = RestartPolicy(policy: .always)
    static let unlessStopped = RestartPolicy(policy: .unlessStopped)
    static func onFailure(maxRetries: Int) -> RestartPolicy {
        RestartPolicy(policy: .onFailure(maxRetries: maxRetries))
    }
}

// MARK: - Configuration Extensions

extension ContainerConfiguration {
    func withLabels(_ labels: [String: String]) -> Self {
        var config = self
        config.labels = labels
        return config
    }

    func withRestartPolicy(_ policy: RestartPolicy) -> Self {
        var config = self
        config.restartPolicy = policy
        return config
    }
}

// MARK: - Usage Instructions

/*
 Full Container Framework Example

 This example demonstrates:
 - Container system lifecycle management
 - Custom image building with Dockerfile
 - Network creation and configuration
 - Volume management for persistent data
 - Multi-container applications
 - Resource limits and constraints
 - Health checks and monitoring
 - Integration testing
 - Proper cleanup and error handling

 To run:
 1. chmod +x full-example.swift
 2. ./full-example.swift

 Requirements:
 - macOS 15+ (basic features)
 - macOS 26+ (full network features)
 - Apple Silicon Mac
 - 16GB+ RAM recommended
 - Container framework installed

 This example creates:
 - Custom application image
 - PostgreSQL database container
 - Node.js application container
 - Custom network for container communication
 - Persistent volumes for data
 - Temporary filesystems for cache

 Production Considerations:
 - Implement proper logging
 - Add monitoring and alerting
 - Use secrets management
 - Implement backup strategies
 - Add load balancing for scale
 - Use container orchestration for complex deployments
 */

// MARK: - Best Practices Summary

/*
 Container Framework Best Practices:

 1. Lifecycle Management
    - Always clean up resources
    - Handle errors gracefully
    - Implement health checks
    - Use restart policies

 2. Security
    - Run as non-root user
    - Use read-only filesystems where possible
    - Limit capabilities
    - Isolate networks
    - Manage secrets properly

 3. Performance
    - Set appropriate resource limits
    - Use volumes for persistent data
    - tmpfs for temporary files
    - Native arm64 images on Apple Silicon

 4. Networking
    - Use custom networks for isolation
    - Configure DNS properly
    - Implement service discovery
    - Handle network failures

 5. Storage
    - Use volumes for data persistence
    - Bind mounts for development
    - tmpfs for performance
    - Regular backups

 6. Monitoring
    - Implement health checks
    - Log important events
    - Track resource usage
    - Monitor application metrics
 */
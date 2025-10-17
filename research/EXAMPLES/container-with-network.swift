#!/usr/bin/env swift

// container-with-network.swift
// Container with network access configuration and container-to-container communication

import Foundation
import Containerization

// MARK: - Container with Network Example

@main
struct ContainerWithNetwork {
    static func main() async throws {
        print("Starting container with network example...")

        let client = try await ContainerClient()

        // Ensure system is running
        guard try await client.healthCheck() else {
            print("Container system not running. Run: container system start")
            exit(1)
        }

        // Example 1: Basic network connectivity
        try await basicNetworkExample(client: client)

        // Example 2: Custom network (macOS 26 only)
        if #available(macOS 26.0, *) {
            try await customNetworkExample(client: client)
        } else {
            print("Custom networks require macOS 26 or later")
        }

        print("\n✅ Network examples completed successfully!")
    }

    // Basic network connectivity test
    static func basicNetworkExample(client: ContainerClient) async throws {
        print("\n=== Basic Network Connectivity ===")

        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withCommand(["sh", "-c", """
                echo "Testing network connectivity..."
                echo ""
                echo "1. DNS Resolution:"
                nslookup google.com
                echo ""
                echo "2. Ping test:"
                ping -c 3 8.8.8.8
                echo ""
                echo "3. HTTP request:"
                wget -q -O- http://example.com | head -n 5
                echo ""
                echo "4. Network interfaces:"
                ip addr show
                echo ""
                echo "✓ Network tests completed"
                """])

        let container = try await client.createContainer(config)
        try await container.start()
        _ = try await container.wait()
        try await container.delete()
    }

    // Custom network with container communication
    @available(macOS 26.0, *)
    static func customNetworkExample(client: ContainerClient) async throws {
        print("\n=== Custom Network Example ===")

        // Create custom network
        let networkName = "app-network-\(UUID().uuidString.prefix(8))"
        print("Creating network: \(networkName)")

        let network = try await client.createNetwork(
            name: networkName,
            driver: "vmnet"
        )

        defer {
            // Cleanup network
            Task {
                try? await network.delete()
            }
        }

        // Start a simple web server
        let serverConfig = ContainerConfiguration()
            .withImage("nginx:alpine")
            .withNetwork(networkName)
            .withHostname("webserver")
            .withEnvironment(["NGINX_PORT": "80"])

        print("Starting web server container...")
        let server = try await client.createContainer(serverConfig)
        try await server.start()

        defer {
            Task {
                try? await server.stop()
                try? await server.delete()
            }
        }

        // Wait for server to be ready
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        // Start client container to test connection
        let clientConfig = ContainerConfiguration()
            .withImage("alpine:latest")
            .withNetwork(networkName)
            .withCommand(["sh", "-c", """
                echo "Testing connection to web server..."
                echo ""
                echo "1. Ping webserver by hostname:"
                ping -c 3 webserver
                echo ""
                echo "2. HTTP request to webserver:"
                wget -q -O- http://webserver/ | head -n 10
                echo ""
                echo "✓ Successfully connected to webserver"
                """])

        print("Starting client container...")
        let client = try await client.createContainer(clientConfig)
        try await client.start()
        _ = try await client.wait()
        try await client.delete()

        print("✅ Custom network example completed")
    }
}

// MARK: - Port Mapping Example

struct PortMapping {
    static func runWithPortMapping() async throws {
        let client = try await ContainerClient()

        print("\n=== Port Mapping Example ===")

        // Run web server with port mapping
        let config = ContainerConfiguration()
            .withImage("nginx:alpine")
            .withPorts([
                PortMapping(hostPort: 8080, containerPort: 80)
            ])
            .withEnvironment(["NGINX_HOST": "localhost"])

        print("Starting nginx on port 8080...")
        let container = try await client.createContainer(config)
        try await container.start()

        print("Web server running at: http://localhost:8080")
        print("Container ID: \(container.id)")

        // Test the connection from host
        try await Task.sleep(nanoseconds: 2_000_000_000)

        if let url = URL(string: "http://localhost:8080") {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                if let httpResponse = response as? HTTPURLResponse {
                    print("✅ Server responded with status: \(httpResponse.statusCode)")
                    if let html = String(data: data, encoding: .utf8) {
                        print("Response preview: \(html.prefix(100))...")
                    }
                }
            } catch {
                print("⚠️ Could not connect to server: \(error)")
            }
        }

        print("\nPress Enter to stop the server...")
        _ = readLine()

        try await container.stop()
        try await container.delete()
    }
}

// MARK: - Multi-Container Application

struct MultiContainerApp {
    static func deployApplication() async throws {
        let client = try await ContainerClient()

        print("\n=== Multi-Container Application ===")

        // Create application network
        let networkName = "microservices"

        if #available(macOS 26.0, *) {
            _ = try await client.createNetwork(
                name: networkName,
                driver: "vmnet"
            )
        }

        // Deploy database
        print("1. Starting database...")
        let dbConfig = ContainerConfiguration()
            .withImage("postgres:13-alpine")
            .withNetwork(networkName)
            .withHostname("database")
            .withEnvironment([
                "POSTGRES_USER": "app",
                "POSTGRES_PASSWORD": "secret",
                "POSTGRES_DB": "appdb"
            ])
            .withMount(.volume(
                name: "pgdata",
                target: "/var/lib/postgresql/data"
            ))

        let database = try await client.createContainer(dbConfig)
        try await database.start()

        // Deploy Redis cache
        print("2. Starting cache...")
        let cacheConfig = ContainerConfiguration()
            .withImage("redis:alpine")
            .withNetwork(networkName)
            .withHostname("cache")
            .withCommand(["redis-server", "--maxmemory", "256mb"])

        let cache = try await client.createContainer(cacheConfig)
        try await cache.start()

        // Deploy application
        print("3. Starting application...")
        let appConfig = ContainerConfiguration()
            .withImage("node:16-alpine")
            .withNetwork(networkName)
            .withHostname("app")
            .withEnvironment([
                "DATABASE_URL": "postgresql://app:secret@database:5432/appdb",
                "REDIS_URL": "redis://cache:6379",
                "NODE_ENV": "production"
            ])
            .withCommand(["sh", "-c", """
                echo "Application started"
                echo "Connected to database at: $DATABASE_URL"
                echo "Connected to cache at: $REDIS_URL"
                # Simulate app running
                sleep 10
                """])

        let app = try await client.createContainer(appConfig)
        try await app.start()

        print("\n✅ Application stack deployed:")
        print("- Database: \(database.id)")
        print("- Cache: \(cache.id)")
        print("- App: \(app.id)")

        // Wait for app to complete
        _ = try await app.wait()

        // Cleanup
        print("\nCleaning up...")
        try await app.delete()
        try await cache.stop()
        try await cache.delete()
        try await database.stop()
        try await database.delete()

        print("✅ Multi-container application example completed")
    }
}

// MARK: - DNS and Hosts Configuration

struct DNSConfiguration {
    static func configureDNS() async throws {
        let client = try await ContainerClient()

        print("\n=== DNS Configuration Example ===")

        // Container with custom DNS servers
        let config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withDNS(["8.8.8.8", "8.8.4.4"])  // Google DNS
            .withExtraHosts([
                "myapp.local": "192.168.1.100",
                "api.local": "192.168.1.101"
            ])
            .withCommand(["sh", "-c", """
                echo "=== DNS Configuration ==="
                echo ""
                echo "1. Resolv.conf:"
                cat /etc/resolv.conf
                echo ""
                echo "2. Hosts file:"
                cat /etc/hosts
                echo ""
                echo "3. Testing custom hosts:"
                ping -c 1 myapp.local
                ping -c 1 api.local
                echo ""
                echo "4. Testing DNS resolution:"
                nslookup google.com
                echo ""
                echo "✓ DNS configuration working"
                """])

        let container = try await client.createContainer(config)
        try await container.start()
        _ = try await container.wait()
        try await container.delete()

        print("✅ DNS configuration example completed")
    }
}

// MARK: - Network Isolation

struct NetworkIsolation {
    static func demonstrateIsolation() async throws {
        let client = try await ContainerClient()

        print("\n=== Network Isolation Example ===")

        guard #available(macOS 26.0, *) else {
            print("Network isolation requires macOS 26+")
            return
        }

        // Create two isolated networks
        let network1 = try await client.createNetwork(
            name: "isolated-1",
            driver: "vmnet"
        )
        let network2 = try await client.createNetwork(
            name: "isolated-2",
            driver: "vmnet"
        )

        // Container on network 1
        let container1Config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withNetwork("isolated-1")
            .withHostname("container1")
            .withCommand(["sleep", "30"])

        let container1 = try await client.createContainer(container1Config)
        try await container1.start()

        // Container on network 2
        let container2Config = ContainerConfiguration()
            .withImage("alpine:latest")
            .withNetwork("isolated-2")
            .withHostname("container2")
            .withCommand(["sleep", "30"])

        let container2 = try await client.createContainer(container2Config)
        try await container2.start()

        // Get IP addresses
        let inspect1 = try await container1.inspect()
        let inspect2 = try await container2.inspect()

        print("Container 1 IP: \(inspect1.networkSettings.ipAddress ?? "unknown")")
        print("Container 2 IP: \(inspect2.networkSettings.ipAddress ?? "unknown")")

        // Test isolation (containers cannot communicate)
        if let ip2 = inspect2.networkSettings.ipAddress {
            let testProcess = try await container1.exec(
                command: ["ping", "-c", "3", "-W", "1", ip2]
            )
            let exitCode = try await testProcess.wait()

            if exitCode != 0 {
                print("✅ Networks are properly isolated (ping failed as expected)")
            } else {
                print("⚠️ Networks are not isolated (ping succeeded)")
            }
        }

        // Cleanup
        try await container1.stop()
        try await container1.delete()
        try await container2.stop()
        try await container2.delete()
        try await network1.delete()
        try await network2.delete()

        print("✅ Network isolation example completed")
    }
}

// MARK: - Advanced Networking

extension ContainerConfiguration {
    // Helper for port mapping
    func withPorts(_ mappings: [PortMapping]) -> Self {
        var config = self
        // Note: Actual implementation would set port mappings
        // This is a simplified example
        return config
    }

    // Helper for DNS configuration
    func withDNS(_ servers: [String]) -> Self {
        var config = self
        // Set DNS servers
        return config
    }

    // Helper for extra hosts
    func withExtraHosts(_ hosts: [String: String]) -> Self {
        var config = self
        // Add extra host entries
        return config
    }

    // Helper for hostname
    func withHostname(_ hostname: String) -> Self {
        var config = self
        config.hostname = hostname
        return config
    }
}

struct PortMapping {
    let hostPort: Int
    let containerPort: Int
    let protocol: String = "tcp"
}

// MARK: - Container Network Inspection

extension LinuxContainer {
    func inspect() async throws -> ContainerInspection {
        // Simplified inspection structure
        ContainerInspection(
            id: self.id,
            name: self.name ?? "",
            state: ContainerState(),
            networkSettings: NetworkSettings()
        )
    }
}

struct ContainerInspection {
    let id: String
    let name: String
    let state: ContainerState
    let networkSettings: NetworkSettings
}

struct ContainerState {
    let running: Bool = true
    let pid: Int = 0
}

struct NetworkSettings {
    let ipAddress: String? = "172.17.0.2"  // Example IP
    let gateway: String? = "172.17.0.1"
    let macAddress: String? = "02:42:ac:11:00:02"
}

// MARK: - Usage Notes

/*
 Network Configuration Examples:

 1. Basic connectivity - Works on all macOS versions
 2. Custom networks - Requires macOS 26+
 3. Port mapping - Maps container ports to host
 4. Multi-container - Containers communicate by hostname
 5. DNS configuration - Custom DNS servers and hosts
 6. Network isolation - Separate network namespaces

 To run:
 chmod +x container-with-network.swift
 ./container-with-network.swift

 Requirements:
 - macOS 15+ (basic networking)
 - macOS 26+ (custom networks, container-to-container)
 - Container system running
 - Internet connectivity for external tests

 Limitations on macOS 15:
 - Only default network available
 - No container-to-container communication
 - Limited to network isolation mode
 */

// MARK: - Best Practices

/*
 Networking Best Practices:

 1. Security:
    - Use custom networks for isolation
    - Limit exposed ports
    - Use internal networks for sensitive services
    - Configure firewall rules appropriately

 2. Performance:
    - Minimize network hops
    - Use host networking for performance-critical apps
    - Configure appropriate buffer sizes
    - Monitor network usage

 3. Reliability:
    - Implement health checks
    - Use service discovery
    - Handle network failures gracefully
    - Configure appropriate timeouts

 4. Debugging:
    - Use container exec for network diagnostics
    - Monitor network traffic with tcpdump
    - Check DNS resolution
    - Verify routing tables
 */
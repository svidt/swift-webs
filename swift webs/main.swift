//
//  main.swift
//  swift webs
//
//  Created by Kristian Emil on 04/04/2025.
//

import Foundation
import Network

let args = CommandLine.arguments

guard args.count > 1 else {
    print("Please provide a command - start / stop")
    exit(1)
}

var port: UInt16 = 8080

if args[1].lowercased() == "start" {
    // Check for custom port
    if args.count > 2, let customPort = UInt16(args[2]) {
        port = customPort
    }
    
    do {
        let listener = try NWListener(using: .tcp, on: NWEndpoint.Port(integerLiteral: port))
        
        listener.newConnectionHandler = { connection in
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    print("Client connected 👤")
                    
                    // Set up receive handler first
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
                        if let data = data, let requestString = String(data: data, encoding: .utf8) {
                            print("Received request: \(requestString.prefix(100))...")
                            
                            // Now send a response after receiving data
                            let responseBody = "Hello, Swift Server!"
                            let response = """
                            HTTP/1.1 200 OK
                            Content-Length: \(responseBody.utf8.count)
                            Content-Type: text/plain
                            
                            \(responseBody)
                            """
                            
                            connection.send(content: response.data(using: .utf8)!, completion: .contentProcessed({ _ in
                                connection.cancel()
                            }))
                        }
                    }
                case .failed(let error):
                    print("Connection failed: \(error)")
                case .cancelled:
                    print("Connection cancelled")
                default:
                    break
                }
            }
            
            // Start the connection after setting up handlers
            connection.start(queue: .main)
        }
        
        // Start the listener outside of connection handling
        listener.start(queue: .main)
        print("""
        ✅ Webserver started
        ✅ Running on port: \(port)
        Press CTRL+C to stop.
        """)
        
        // Run the main loop
        RunLoop.main.run()
        
    } catch {
        print("Failed to start server: \(error)")
        exit(2) // Network error exit code
    }
} else if args[1].lowercased() == "stop" {
    print("Stop command received")
    exit(0)
} else {
    print("Unknown command. Available commands: start / stop")
    exit(1)
}

//
//  ARUnderstanding.swift
//  SimpleARKitVision
//
//  Created by John Haney on 3/31/24.
//

#if canImport(ARKit)
@_exported import ARKit
#endif
#if canImport(RealityKit)
@_exported import RealityKit
#endif
import OSLog

@Observable
@MainActor
public class ARUnderstanding {
    // Public
    public private(set) var errorState = false
    
    // Private
    private let logger: Logger
    public static let session: ARUnderstandingSession = ARUnderstandingSession()

    private(set) var providers: [ARProviderDefinition]
    
    #if os(visionOS) || os(iOS)
    @available(visionOS, introduced: 2.0)
    @available(iOS, introduced: 18.0)
    public init(providers: [ARProviderDefinition], logger: Logger = Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "general")) {
        self.providers = providers
        self.logger = logger
    }
    #else
    private init(logger: Logger = Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "general")) {
        self.providers = []
        self.logger = logger
    }
    #endif
    
    public var anchorUpdates: AsyncStream<CapturedAnchor> {
        AsyncStream { continuation in
            let name = UUID().uuidString
            let output = AnchorStreamOutput(continuation: continuation)
            Self.session.add(output: output, name: name)
            continuation.onTermination = { _ in
                Task {
                    await MainActor.run {
                        Self.session.remove(outputNamed: name)
                    }
                }
            }
            ensureSessionIsRunning()
        }
    }
    
    private func ensureSessionIsRunning() {
        guard !Self.session.isRunning
        else {
            return
        }
        
        #if os(visionOS) || os(iOS)
        #if targetEnvironment(simulator)
        #else
        if #available(visionOS 2.0, iOS 18.0, *) {
            Self.session.add(input: ARUnderstandingLiveInput(providers: providers, logger: logger))
        }
        #endif
        #endif

        Self.session.start()
    }
}

import QuartzCore

extension ARUnderstanding: @preconcurrency ARUnderstandingInput {
    public var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            let task = Task {
                defer { continuation.finish() }
                continuation.yield(ARUnderstandingSession.Message.newSession)
                for await update in self.anchorUpdates {
                    switch continuation.yield(ARUnderstandingSession.Message.anchor(update)) {
                    case .terminated: return
                    default: break
                    }
                }
            }
            continuation.onTermination = { @Sendable termination in
                switch termination {
                case .cancelled: task.cancel()
                default: break
                }
            }
        }
    }
}

//
//  ARUnderstandingSession.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/16/25.
//

import Foundation
#if canImport(RealityKit)
import RealityKit
#endif
import Combine
import OSLog

public protocol ARUnderstandingInput {
    var messages: AsyncStream<ARUnderstandingSession.Message> { get }
}

public protocol ARUnderstandingOutput {
    @MainActor func handle(_ message: ARUnderstandingSession.Message) async
}

public struct AnchorStreamOutput: ARUnderstandingOutput {
    let continuation: AsyncStream<CapturedAnchor>.Continuation
    @MainActor public func handle(_ message: ARUnderstandingSession.Message) async {
        switch message {
        case .newSession:
            break
        case .anchor(let capturedAnchor):
            continuation.yield(capturedAnchor)
        case .authorizationDenied(let string):
            break
        case .trackingError(let string):
            break
        case .unknown:
            break
        }
    }
}

public class ARUnderstandingSession {
    private var base: AsyncStream<ARUnderstandingSession.Message>?
    private var continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?
    
    private var inputs: [String: (ARUnderstandingInput, Task<(), Never>?)]
    private var outputs: [String: (ARUnderstandingOutput, Task<(), Never>)]

    public private(set) var isRunning = false
    
    public enum Message: Hashable, Sendable {
        case newSession
        case anchor(CapturedAnchor)
        case authorizationDenied(String)
        case trackingError(String)
        case unknown
    }
    
    public init() {
        self.base = nil
        self.continuation = nil
        self.inputs = [:]
        self.outputs = [:]
        let base = AsyncStream<ARUnderstandingSession.Message> { continuation in
            self.continuation = continuation
        }
        self.base = base
    }
    
    @discardableResult
    @MainActor public func add(input: ARUnderstandingInput) -> String {
        let name = UUID().uuidString
        add(input: input, named: name)
        return name
    }
    
    @MainActor func add(input: ARUnderstandingInput, named name: String) {
        inputs[name] = (input, nil)
        if isRunning {
            runInput(input, name: name)
        }
    }
    
    @MainActor public func setInputs(_ inputs: [String: ARUnderstandingInput]) {
        self.inputs = inputs.mapValues({ ($0, nil) })
        
        if isRunning {
            self.start()
        }
    }
    
    /// Adds (or replaces) a set of inputs using ARUnderstanding providers specified
    /// - Parameter providers: list of ARProviderDefinition choices (ex. [.device, .mesh, .planes])
#if !targetEnvironment(simulator)
    @available(visionOS, introduced: 2.0)
    @available(iOS, introduced: 18.0)
    @available(macOS, unavailable)
    @available(tvOS, unavailable)
    @available(watchOS, unavailable)
    @available(macCatalyst, unavailable)
    @MainActor public func addUnderstanding(_ providers: [ARProviderDefinition]) {
        let understanding = ARUnderstandingLiveInput(providers: providers, logger: logger)
        add(input: understanding, named: "ARUnderstanding")
    }
#endif
    
    @MainActor public func remove(inputNamed name: String) {
        if let (input, inputTask) = self.inputs.removeValue(forKey: name) {
            inputTask?.cancel()
        }
    }
    
    @MainActor @discardableResult public func add(output: ARUnderstandingOutput, name: String) -> String {
        let task = Task {
            guard let base else { return }
            for await message in base {
                guard !Task.isCancelled else { return }
                await output.handle(message)
            }
        }
        outputs[name] = (output, task)
        return name
    }
    
    static func runOutput(_ connector: AsyncStream<Message>, _ output: ARUnderstandingOutput & Sendable, name: String) -> Task<(), Never> {
        let task = Task {
            for await message in connector {
                await output.handle(message)
            }
        }
        return task
    }
    
    @discardableResult
    public func remove(outputNamed name: String) -> Bool {
        self.outputs.removeValue(forKey: name) != nil
    }
    
    @MainActor public func start() {
        self.stop()
        for (name, (input, _)) in inputs {
            runInput(input, name: name)
        }
        isRunning = true
    }
    
    @MainActor private func runInput(_ input: ARUnderstandingInput, name: String) {
        let task = Task {
            for await message in input.messages {
                guard !Task.isCancelled else { return }
                switch continuation?.yield(message) {
                case .terminated:
                    logger.debug("runInput terminated")
                    return
                default:
                    continue
                }
            }
            logger.debug("runInput complete")
        }
        inputs[name] = (input, task)
    }
    
    public func stop() {
        let tasks: [(String, (any ARUnderstandingInput, Task<(), Never>?))] = inputs.map({ ($0.key, $0.value) })
        for (name, (input, inputTask)) in tasks {
            if let inputTask {
                inputTask.cancel()
                inputs[name] = (input, nil)
            }
        }
        isRunning = false
    }
    
    public func removeAll() {
        stop()
        inputs.removeAll()
        outputs.removeAll()
    }
}

//extension ARUnderstandingOutput {
//    func handle(_ message: ARUnderstandingSession.Message) async {
//        switch message {
//        case .newSession:
//            await self.handleNewSession()
//        case .anchor(let capturedAnchor):
//            await self.handleAnchor(capturedAnchor)
//        case .anchorData(let data):
//            if let (capturedAnchor, _) = try? CapturedAnchor.unpack(data: data) {
//                logger.trace("anchorData unpacked: \(capturedAnchor.id)")
//                await self.handleAnchor(capturedAnchor)
//            } else {
//                logger.error("anchorData failed to unpack: \(data.count) bytes")
//            }
//        case .authorizationDenied(let string):
//            break
//        case .trackingError(let string):
//            break
//        case .unknown:
//            break
//        }
//    }
//}

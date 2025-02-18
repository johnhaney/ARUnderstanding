//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/16/25.
//

import Foundation
import RealityKit

public protocol ARUnderstandingInput {
    @MainActor var sessionUpdates: AsyncStream<ARUnderstandingSession.Message> { get }
}

public protocol ARUnderstandingOutput {
    func handleNewSession() async
    func handleAnchor(_ anchor: CapturedAnchor) async
}

public class ARUnderstandingSession {
    var inputs: [String: ARUnderstandingInput]
    var outputs: [String: ARUnderstandingOutput]
    private var inputTasks: [String: Task<(), Never>] = [:]
    private var isRunning = false
    
    public enum Message: Hashable, Codable, Sendable {
        case newSession
        case anchor(CapturedAnchor)
    }
    
    public init() {
        inputs = [:]
        outputs = [:]
    }
    
    @discardableResult
    @MainActor public func add(input: ARUnderstandingInput) -> String {
        let string = UUID().uuidString
        self.inputs[string] = input
        if isRunning {
            runInput(input)
        }
        return string
    }
    
    @MainActor public func setInputs(_ inputs: [String: ARUnderstandingInput]) {
        var shouldStart = false
        if isRunning { shouldStart = true }

        self.stop()
        self.inputs = inputs
        
        if shouldStart {
            self.start()
        }
    }
    
    @discardableResult public func add(output: ARUnderstandingOutput, name: String? = nil) -> String {
        let string = name ?? UUID().uuidString
        self.outputs[string] = output
        return string
    }
    
    @discardableResult
    public func remove(outputNamed name: String) -> Bool {
        self.outputs.removeValue(forKey: name) != nil
    }
    
    @MainActor public func start() {
        self.stop()
        self.inputTasks = inputs.mapValues { input in
            runInput(input)
        }
    }
    
    @MainActor private func runInput(_ input: ARUnderstandingInput) -> Task<(), Never> {
        Task {
            for await update in input.sessionUpdates {
                switch update {
                case .newSession:
                    Task {
                        self.handleNewSession()
                    }
                case .anchor(let capturedAnchor):
                    Task {
                        self.handleAnchor(capturedAnchor)
                    }
                }
            }
        }
    }
    
    @MainActor private func handleNewSession() {
        for output in outputs.values {
            Task {
                await output.handleNewSession()
            }
        }
    }
    
    @MainActor private func handleAnchor(_ anchor: CapturedAnchor) {
        for output in outputs.values {
            Task {
                await output.handleAnchor(anchor)
            }
        }
    }

    public func stop() {
        let inputTasks = self.inputTasks.values
        for input in inputTasks {
            input.cancel()
        }
    }
}

extension Entity {
    func removeAllChildren() async {
        let children = Array(self.children)
        for child in children {
            child.removeFromParent()
        }
    }
}

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
    private var inputTasks: [String: Task<(), Never>]
    private var isRunning = false
    
    public enum Message: Hashable, Sendable {
        case newSession
        case anchor(CapturedAnchorProxy)
        case unknown
        
        static func anchor(_ anchor: CapturedAnchor) -> Self {
            if let proxy = try? CapturedAnchorProxy(anchor: anchor) {
                return .anchor(proxy)
            } else {
                return .unknown
            }
        }
    }
    
    public init() {
        inputs = [:]
        inputTasks = [:]
        outputs = [:]
    }
    
    @discardableResult
    @MainActor public func add(input: ARUnderstandingInput) -> String {
        let string = UUID().uuidString
        self.inputs[string] = input
        if isRunning {
            runInput(input, name: string)
        }
        return string
    }
    
    @MainActor public func setInputs(_ inputs: [String: ARUnderstandingInput]) {
        self.inputs = inputs
        
        if isRunning {
            self.start()
        }
    }
    
    @discardableResult public func add(output: ARUnderstandingOutput, name: String) -> String {
        let string = name
        self.outputs[string] = output
        return string
    }
    
    @discardableResult
    public func remove(outputNamed name: String) -> Bool {
        self.outputs.removeValue(forKey: name) != nil
    }
    
    @MainActor public func start() {
        self.stop()
        for (name, input) in inputs {
            runInput(input, name: name)
        }
    }
    
    @MainActor private func runInput(_ input: ARUnderstandingInput, name: String) {
        let task = Task {
            for await update in input.sessionUpdates {
                switch update {
                case .newSession:
                    Task {
                        self.handleNewSession()
                    }
                case .anchor(let proxy):
                    Task {
                        if let capturedAnchor = proxy.anchor {
                            self.handleAnchor(capturedAnchor)
                        }
                    }
                case .unknown:
                    break
                }
            }
        }
        inputTasks[name] = task
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
        self.inputTasks.removeAll()
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

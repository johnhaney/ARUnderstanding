//
//  ARUnderstandingSession.swift
//  ARUnderstandingSessionPrototype
//
//  Created by John Haney on 3/9/25.
//

import Foundation

public protocol ARUnderstandingInput {
    var messages: AsyncStream<ARUnderstandingSession.Message> { get }
}

public protocol ARUnderstandingOutput {
    func handle(message: ARUnderstandingSession.Message) async
}

public actor ARUnderstandingSession {
    private var base: AsyncStream<ARUnderstandingSession.Message>?
    private var continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?
    
    private var inputs: [String: (ARUnderstandingInput, Task<(), Never>)]
    private var outputs: [String: (ARUnderstandingOutput, Task<(), Never>)]

    public enum Message {
        case newSession
    }
    
    init() {
        self.base = nil
        self.continuation = nil
        self.inputs = [:]
        self.outputs = [:]
        let base = AsyncStream<ARUnderstandingSession.Message> { continuation in
            Task {
                await self.setContinuation(continuation)
            }
        }
        self.base = base
    }
    
    private func setContinuation(_ continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation) async {
        self.continuation = continuation
    }
    
    func addInput(_ input: ARUnderstandingInput, name: String) {
        let task = Task {
            for await message in input.messages {
                guard !Task.isCancelled else { return }
                switch continuation?.yield(message) {
                case .terminated:
                    print("input [\(name)] terminated")
                    return
                default: break
                }
            }
        }
        inputs[name] = (input, task)
    }
    
    func addOutput(_ output: ARUnderstandingOutput, name: String) {
        let task = Task {
            guard let base else { return }
            for await message in base {
                guard !Task.isCancelled else {
                    logger.debug("output task [\(name)] was cancelled")
                    return
                }
                await output.handle(message: message)
            }
        }
        outputs[name] = (output, task)
    }
}

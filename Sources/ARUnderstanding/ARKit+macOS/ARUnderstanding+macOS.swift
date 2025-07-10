//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/1/25.
//

#if os(macOS)
import Foundation
import OSLog

struct ARUnderstandingLiveInput: ARUnderstandingInput {
    var messages: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }
    
    var sessionUpdates: AsyncStream<ARUnderstandingSession.Message> {
        AsyncStream { nil }
    }
    
    private let providers: [ARProviderDefinition]
    private let logger: Logger

    init(providers: [ARProviderDefinition], logger: Logger = Logger(subsystem: "com.appsyoucanmake.ARUnderstanding", category: "ARUnderstandingLiveInput")) {
        self.providers = providers
        self.logger = logger
    }
}
#endif

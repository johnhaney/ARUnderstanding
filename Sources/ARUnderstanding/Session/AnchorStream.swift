//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 5/30/25.
//

import Foundation

//public class AnchorStream: ARUnderstandingOutput {
//    var name: String = UUID().uuidString
//    @MainActor private static var continuations: [UUID: AsyncStream<CapturedAnchor>.Continuation] = [:]
//    var anchorUpdates: AsyncStream<CapturedAnchor> {
//        AsyncStream { continuation in
//            let uuid = UUID()
//            Task {
//                Self.continuations[uuid] = continuation
//            }
//            continuation.onTermination {
//                Task {
//                    await Self.continuations.removeValue(forKey: uuid)
//                }
//            }
//        }
//    }
//    
//    public func handle(_ message: ARUnderstandingSession.Message) async {
//        switch message {
//        case .newSession:
//            break
//        case .anchor(let capturedAnchor):
//            yield(capturedAnchor)
//        case .anchorData(let data):
//            if let (anchor, _) = try? CapturedAnchor.unpack(data: data) {
//                yield(anchor)
//            }
//        case .authorizationDenied(let string):
//            break
//        case .trackingError(let string):
//            break
//        case .unknown:
//            break
//        }
//    }
//    
//    @MainActor func yield(_ anchor: CapturedAnchor) {
//        let output = Self.continuations.values
//        for out in output {
//            out.yield(anchor)
//        }
//    }
//}
//
//extension ARUnderstanding {
//    public var anchorUpdates: AsyncStream<CapturedAnchor> {
//        let stream = AnchorStream()
//        session.add(output: stream, name: stream.name)
//        return stream.anchorUpdates
//    }
//}

//
//  RoomTrackingProvider.swift
//  ARUnderstanding
//
//  Created by John Haney on 3/4/25.
//

//#if os(iOS)
//import Foundation
//import ARKit
//import RealityKit
//
//final public class RoomTrackingProvider: AnchorCapturingDataProvider, ARUnderstandingInput {
//    typealias AnchorType = ARAnchor
//    
//    var anchorCapabilities: Set<SpatialTrackingSession.Configuration.AnchorCapability> {
//        Set()
//    }
//    
//    var sceneUnderstanding: Set<SpatialTrackingSession.Configuration.SceneUnderstandingCapability> {
//        [.collision, .occlusion, .physics, .shadow]
//    }
//    
//    var stream: AsyncStream<ARUnderstandingSession.Message>
//    var continuation: AsyncStream<ARUnderstandingSession.Message>.Continuation?
//    
//    init() {
//        stream = AsyncStream { _ in }
//        stream = AsyncStream { continuation in
//            self.continuation = continuation
//        }
//    }
//    
//    func configure(_ configuration: inout ARWorldTrackingConfiguration) {
//    }
//    
//    public var state: DataProviderState = .initialized
//    
//    public static var requiredAuthorizations: [ARKitSession.AuthorizationType] { [] }
//    
//    public static var isSupported: Bool { true }
//    
//    public var description: String { "RoomTrackingProvider" }
//    
//    func capture(anchor: CapturedRoomAnchor, timestamp: TimeInterval, event: CapturedAnchorEvent) -> CapturedAnchor? {
//        let captured = anchor.captured
//        return .room(CapturedAnchorUpdate(anchor: captured, timestamp: timestamp, event: event))
//    }
//    
//    public var anchorUpdates: AsyncStream<CapturedAnchorUpdate<CapturedRoomAnchor>> {
//        AsyncStream { continuation in
//            let stream = self.stream
//            let task = Task {
//                for await message in stream {
//                    guard !Task.isCancelled else { return }
//                    switch message {
//                    case .newSession:
//                        break
//                    case .anchor(let capturedAnchor):
//                        switch capturedAnchor {
//                        case .room(let capturedAnchorUpdate):
//                            continuation.yield(capturedAnchorUpdate)
//                        default:
//                            break
//                        }
//                    case .anchorData(let data):
//                        if let (update, _) = try? CapturedAnchor.unpack(data: data) {
//                            switch update {
//                            case .room(let capturedAnchorUpdate):
//                                continuation.yield(capturedAnchorUpdate)
//                            default:
//                                break
//                            }
//                        }
//                    case .authorizationDenied(let string):
//                        break
//                    case .trackingError(let string):
//                        break
//                    case .unknown:
//                        break
//                    }
//                }
//            }
//            continuation.onTermination = { @Sendable termination in
//                switch termination {
//                case .cancelled: task.cancel()
//                default: break
//                }
//            }
//        }
//    }
//}
//#endif

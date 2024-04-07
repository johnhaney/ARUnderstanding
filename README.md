# ARUnderstanding
Provides a simple interface for getting ARKit values from visionOS

example usage:

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
        }
        .task {
            for await anchor in ARUnderstanding(providers: [.hands]).anchorUpdates {
                switch anchor {
                case .hand(let handAnchor):
                    switch handAnchor.chirality {
                    case .right:
                        // TODO: handle right hand here
                        break
                    case .left:
                        // TODO: handle left hand here
                        break
                    }
                }
            }
        }
    }

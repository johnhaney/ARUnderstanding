# ARUnderstanding
Provides a simple interface for getting ARKit values from visionOS

example usage:

struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
        }
        .task {
            for await handAnchor in ARUnderstanding.handUpdates {
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

for await anchor in ARUnderstanding(providers: [.hands, .planes, .mesh, .world, .images()]).anchorUpdates {
    // TODO: switch on the anchor and handle the various types of anchors being returned
}

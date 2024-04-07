# ARUnderstanding
Provides a simple interface for getting ARKit values from visionOS

example usage:

```
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
```

For simultaneous anchors...
```
for await anchor in ARUnderstanding(providers: [.hands, .planes, .mesh, .world, .images()]).anchorUpdates {
    // TODO: switch on the anchor and handle the various types of anchors being returned
}
```

And for more direct control over the providers, you can pass them in yourself:

```
for await anchor in ARUnderstanding(providers: [.hands(HandTrackingProvider())]).anchoUpdates {
    // TODO: handle anchors here
}
```

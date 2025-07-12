# ARUnderstanding

[<img src="https://img.youtube.com/vi/f5Rdk0a5lB4/hqdefault.jpg" width="600" height="300"
/>](https://www.youtube.com/embed/f5Rdk0a5lB4)

Provides a simple interface for getting ARKit values from visionOS and iOS.
Anchors captured on these devices can be transferred and used on iOS, macOS, tvOS, watchOS, and visionOS
Anchors can be visualized as Entities in RealityKit on iOS 18 or later, macOS 15 or later, tvOS 26 or later, and visionOS

example usage:

```
struct ImmersiveView: View {
    var body: some View {
        RealityView { content in
        }
        .task {
            for await handUpdate in ARUnderstanding.handUpdates {
                switch handUpdate.anchor.chirality {
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

ARUnderstanding includes **debug visualizations** you can add to your scene based on the returned anchors See the ARVisualizer example in [https://github.com/johnhaney/ARKitVision]:
```
switch anchor.event {
case .added:
    let entity = Entity()
    anchor.visualize(in: entity, with: [anchor.defaultMaterial])
    rootEntity.addChild(entity)
    visualizations[anchor.id] = entity
case .updated:
    guard let entity = visualizations[anchor.id]
    else {
        let entity = Entity()
        anchor.visualize(in: entity, with: [anchor.defaultMaterial])
        rootEntity.addChild(entity)
        visualizations[anchor.id] = entity
        return
    }
    anchor.visualize(in: entity, with: [anchor.defaultMaterial])
```


For simultaneous anchors of different types, use anchorUpdates and a switch statement...
```
for await update in ARUnderstanding(providers: [.hands, .planes, .meshes, .device, .image(resourceGroupName: "AR Resources")]).anchorUpdates {
    switch update {
    case .hand(let handUpdate):
        if handUpdate.anchor.chirality == .left {
            // TODO: left hand
        }
    case .device(let deviceUpdate):
        insideYourHead.transform = deviceUpdate.anchor.originFromAnchorTransform
    ...
    }
}
```

And for more direct control over the providers, you can configure and pass them in yourself:

```
for await anchor in ARUnderstanding(providers: [.hands(HandTrackingProvider())]).anchorUpdates {
    // TODO: handle anchors here
}
```

With ARUnderstanding 2.0, the whole infrastructure of how ARUnderstanding runs will move to run on top of ARUnderstandingSession.

This will ensure that you can safely and easily add the providers you want and ARUnderstanding will update the ARUnderstandingSession as needed to adapt to what your app is using.

ARUnderstanding runs an ARUnderstandingSession which links Input and Output

ARUnderstandingInput is implemented by:

AnchorPlayback - for playing back anchors saved in a file
ARUnderstandingLiveInput - for managing the capture of ARKit anchors from the device
Supported ARKit Providers - for wrapping the anchors from the device into the ARUnderstandingSession

ARUnderstandingOutput is implemented by:

AnchorRecorder - for capturing the stream of anchors and saving to a file
ARUnderstandingVisualizer - for displaying visual entities in a RealityView representing the anchors

# ARUnderstanding

[<img src="https://img.youtube.com/vi/f5Rdk0a5lB4/hqdefault.jpg" width="600" height="300"
/>](https://www.youtube.com/embed/f5Rdk0a5lB4)

Provides a simple interface for getting ARKit values from visionOS

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
    let entity = anchor.visualization
    rootEntity.addChild(entity)
    visualizations[anchor.id] = entity
case .updated:
    guard let entity = visualizations[anchor.id]
    else {
        let entity = anchor.visualization
        rootEntity.addChild(entity)
        visualizations[anchor.id] = entity
        return
    }
    entity.components.remove(OpacityComponent.self)
    anchor.update(visualization: entity)
```


For simultaneous anchors...
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

And for more direct control over the providers, you can pass them in yourself:

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

ARUnderstandingOutput is implemented by:

AnchorRecorder - for capturing the stream of anchors and saving to a file
ARUnderstandingVisualizer - for displaying visual entities in a RealityView representing the anchors

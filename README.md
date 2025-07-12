# ARUnderstanding

[<img src="https://img.youtube.com/vi/f5Rdk0a5lB4/hqdefault.jpg" width="600" height="300"
/>](https://www.youtube.com/embed/f5Rdk0a5lB4)

* Provides a simple interface for getting ARKit values from visionOS and iOS.
* Anchors captured on these devices can be transferred and used on iOS, macOS, tvOS, watchOS, and visionOS
* Anchors can be visualized as Entities in RealityKit on iOS 18 or later, macOS 15 or later, tvOS 26 or later, and visionOS

| ARKit Anchor   | visionOS | iOS       |
| -------------- | -------- | --------- |
| Device Pose    | device   | device    |
| Scene meshes   | meshes   | meshes    |
| Planes         | planes   | planes    |
| Image Detected | image    | image     |
| Object Tracked | object   | object    |
| World Anchors  | world    | world     |
| Face mesh      | n/a      | face\*    |
| Body           | n/a      | body\*\*  |
| Hands          | hands    | n/a       |
| Room           | room     | n/a\*\*\* |

\* Body detection tracks other people seen by the back camera, and runs a different configuration, so only a few other tracking options are available when capturing body anchors

\+ Face anchors visualization does not use the full face mesh yet. Face Anchors packed and unpacked will also not have access to the mesh. For now, use the Face Anchors as a way to get the general head pose on iOS.

\= Room is not supported on iOS yet. This will use a different configuration and may have some additional restrictions on what other anchors are available at the same time.

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

## Version Highlights

Going forward, the version of this Swift Package will match the most recent OS version supported. We will endeavor to maintain forward and backward interoperability.

| Version | Description |
| ------- | ----------- |
| 18.0.0  | supports pre-26 versions, with forward compatibility to process anchors captured on visionOS 26 |
| 18.0.2  | link this Swift Package against all Apple platforms, including watchOS |
| 26.0.0  | adds functionality introduced in visionOS 26, iOS 26, macOS 26, and tvOS 26 |

## ARUnderstandingSession

With ARUnderstanding 2.0, the whole infrastructure of how ARUnderstanding runs will move to run on top of one ARUnderstandingSession. This will ensure that you can safely and easily add the providers you want dynamically and ARUnderstanding will update the ARUnderstandingSession as needed to adapt to what your app is using.

You can extend ARUnderstandingInput to feed in data from another device.

You can extend ARUnderstandingOutput to store, forward, or transform the anchors coming from the ARUnderstandingSession.

#### ARUnderstandingInput is implemented by:

AnchorPlayback - for playing back anchors saved in a file
ARUnderstandingLiveInput - for managing the capture of ARKit anchors from the device
Supported ARKit Providers - for wrapping the anchors from the device into the ARUnderstandingSession

ARUnderstandingOutput is implemented by:

AnchorRecorder - for capturing the stream of anchors and saving to a file
ARUnderstandingVisualizer - for displaying visual entities in a RealityView representing the anchors

## Why use ARUnderstanding when SpatialTrackingSession exists?

SpatialTrackingSession is a great simplified way to access anchors and discover features avialable in the space around your users. This is a great API for many use cases and it's a great place to start.

ARUnderstanding is great for when you need "see" all the anchors of a given type and do something which takes all of them into account. For example, if you need to see all the tables in a room and then you might decide to place content on some or all of them.

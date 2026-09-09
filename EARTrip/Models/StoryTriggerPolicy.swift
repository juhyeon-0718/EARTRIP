import Foundation

/// One source of truth for automatic story triggering. Independent of CoreLocation.
struct StoryTriggerPolicy {
    let maximumAccuracy: Double = 65
    let maximumPadding: Double = 20

    func accepts(accuracy: Double) -> Bool {
        accuracy.isFinite && accuracy >= 0 && accuracy <= maximumAccuracy
    }

    func contains(distance: Double, radius: Double, accuracy: Double) -> Bool {
        accepts(accuracy: accuracy) && distance.isFinite && distance >= 0 &&
            radius >= 0 && distance <= radius + min(accuracy, maximumPadding)
    }
}

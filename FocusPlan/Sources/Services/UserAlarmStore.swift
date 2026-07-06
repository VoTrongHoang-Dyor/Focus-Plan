import Foundation

/// Persist UserAlarm qua UserDefaults (JSON) — local, single-device, đủ cho alarm form.
struct UserAlarmStore {
    private static let key = "user-alarms-v1"
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    func load() -> [UserAlarm] {
        guard let data = defaults.data(forKey: Self.key) else { return [] }
        return (try? JSONDecoder().decode([UserAlarm].self, from: data)) ?? []
    }

    func append(_ alarm: UserAlarm) {
        var all = load()
        all.append(alarm)
        if let data = try? JSONEncoder().encode(all) {
            defaults.set(data, forKey: Self.key)
        }
    }

    var latest: UserAlarm? { load().last }
}

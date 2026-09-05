import UIKit

// Main-thread leases let simultaneous foreground installs restore the original system setting once.
final class InstallationScreenActivity
{
    static let shared = InstallationScreenActivity(read: { UIApplication.shared.isIdleTimerDisabled },
                                                    write: { UIApplication.shared.isIdleTimerDisabled = $0 })
    private var identifiers = Set<UUID>()
    private var previousValue: Bool?
    private let read: () -> Bool
    private let write: (Bool) -> Void

    init(read: @escaping () -> Bool, write: @escaping (Bool) -> Void)
    {
        self.read = read
        self.write = write
    }

    func begin(_ identifier: UUID)
    {
        precondition(Thread.isMainThread)
        guard identifiers.insert(identifier).inserted else { return }
        if previousValue == nil { previousValue = read() }
        write(true)
    }

    func end(_ identifier: UUID)
    {
        precondition(Thread.isMainThread)
        guard identifiers.remove(identifier) != nil, identifiers.isEmpty else { return }
        if let previousValue { write(previousValue) }
        previousValue = nil
    }
}

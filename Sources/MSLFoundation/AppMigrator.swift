import Foundation

/// Manages the migration process between specific versions of an app. Especially useful for bug / hot fixes.
public class AppMigrator {
    /// The key used to look up the migration history
    public let migrationHistoryKey: String

    /// Current build of the installed app (23)
    public let currentBuild: String

    /// Current version of the installed app (1.0.0)
    public let currentVersion: String

    /// Describes which migrations have successfully completed/failed
    private lazy var migrationHistory: [String: Bool] = {
        return UserDefaults.standard.object(forKey: self.migrationHistoryKey) as? [String: Bool] ?? [String: Bool]()
    }()

    public convenience init(bundle: Bundle) {
        guard let build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String else {
            preconditionFailure(
                """
                App build number not found! Be sure to provide a bundle that has `CFBundleVersion`
                defined in it's Info Dictionary.
                """
            )
        }

        guard let version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String else {
            preconditionFailure(
                """
                App version not found! Be sure to provide a bundle that has `CFBundleShortVersionString`
                defined in it's Info Dictionary.
                """
            )
        }

        guard let bundleId = bundle.bundleIdentifier else {
            preconditionFailure(
                """
                Bundle Identifier not found! Be sure to provide the bundle for your main application.
                """
            )
        }

        self.init(build: build, version: version, migrationKey: bundleId)
    }

    public init(build: String, version: String, migrationKey: String) {
        self.currentBuild = build
        self.currentVersion = version
        self.migrationHistoryKey = "\(migrationKey)_MIGRATION_HISTORY"
    }

    /// Provide a list of migrations to execute. Migrations are executed in the order they are supplied in the array.
    public func load(_ migrations: [AppMigration]) {
        self.execute(migrations)

        // Update the migration history
        UserDefaults.standard.set(self.migrationHistory, forKey: self.migrationHistoryKey)
    }

    private func execute(_ migrations: [AppMigration]) {
        // Get the next migration
        guard let migration = migrations.first else {
            return
        }

        // The remaining migrations that need to be run
        let remaining = Array(migrations.dropFirst())

        guard self.migrationHistory[migration.name] != true else {
            // Migration has been completed already
            self.execute(remaining)
            return
        }

        guard self.preceedesCurrentVersion(migration.version) else {
            // Migration should not be applied yet
            self.execute(remaining)
            return
        }

        // swiftlint:disable:next force_unwrapping
        guard migration.prerequisite == nil || self.migrationHistory[migration.prerequisite!.name] == true else {
            // Migration depends on another migration which has not completed yet
            self.execute(remaining)
            return
        }

        migration.migrate { completed in
            if completed {
                // The migration succeeded
                self.migrationHistory[migration.name] = true

                // Continue
                self.execute(remaining)
            } else {
                self.migrationHistory[migration.name] = false

                // The migration failed, so we need to rollback now.
                migration.rollback()

                // Continue
                self.execute(remaining)
            }
        }
    }

    /// Returns true if the supplied version is less than or equal to the current version of the app
    private func preceedesCurrentVersion(_ version: String) -> Bool {
        let currentVersionNumbers = self.currentVersion.split(separator: ".").compactMap { Int($0) }
        let versionNumbers = version.split(separator: ".").compactMap { Int($0) }

        for index in 0...currentVersionNumbers.count - 1 {
            // Success if we've run out of numbers to check
            if versionNumbers.count - 1 < index {
                break
            }

            // Fails if a number at a location is greater than the current version
            if versionNumbers[index] > currentVersionNumbers[index] {
                return false
            }
        }

        return true
    }
}

/// A protocol to describe the migration process for a specific version of the app.
public protocol AppMigration {
    /// The name of the migration. Migration names should be unique and therefore default to "{CLASSNAME}_{VERSION}".
    static var name: String { get }

    /// Version of the app this migration should be applied to
    static var version: String { get }

    /// The migration that should be applied before this one
    static var prerequisite: AppMigration.Type? { get }

    /**
     Describes the changes that should be applied to the app.

     - returns:
     A boolean to indicate whether the migration passed or failed

     */
    func migrate(_ completion: @escaping ((Bool) -> Void))

    /**
     Describes the changes to be reversed in the event a migration was not successful.
     */
    func rollback()
}

public extension AppMigration {
    static var name: String {
        return "\(type(of: self))_\(self.version)"
    }

    var name: String {
        return Self.name
    }

    var version: String {
        return Self.version
    }

    var prerequisite: AppMigration.Type? {
        return Self.prerequisite
    }

    func rollback() {}
}

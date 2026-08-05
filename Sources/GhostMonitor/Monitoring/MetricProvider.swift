import Foundation

public protocol MetricProvider: Sendable {
    associatedtype Snapshot: Sendable
    func collect() async throws -> Snapshot
}

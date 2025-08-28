import Dependencies

extension DependencyValues {
    public var apiClient: APIClientKind {
        get { self[APIClientKindKey.self] }
        set { self[APIClientKindKey.self] = newValue }
    }

    private enum APIClientKindKey: DependencyKey {
        static var liveValue: APIClientKind {
            fatalError(
                """
                Live value of APIClientKindKey has not been set. 
                Please call setupAPIClient before using
                """
            )
        }

        static var testValue: APIClientKind {
            fatalError("Test value of APIClientKindKey has not been set")
        }
    }
}

public func setupAPIClient(client: APIClientKind) {
    prepareDependencies { values in
        values.apiClient = client
    }
}

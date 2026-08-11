import RxSwift

/// Bridges RxSwift's pre-concurrency observer to APIs whose callbacks are `@Sendable`.
nonisolated final class RxObserverBox<Element>: @unchecked Sendable {
    private let observer: AnyObserver<Element>

    init(_ observer: AnyObserver<Element>) {
        self.observer = observer
    }

    func onNext(_ element: Element) {
        observer.onNext(element)
    }

    func onError(_ error: any Error) {
        observer.onError(error)
    }

    func onCompleted() {
        observer.onCompleted()
    }
}

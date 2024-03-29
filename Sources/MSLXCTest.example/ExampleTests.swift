import MSLCombine
import MSLXCTest
import XCTest

class TestService {
    @PublisherConvertible
    var testValue = false
    lazy var testValuePublisher = self.$testValue

    func updateTestValue(_ newValue: Bool) {
        testValue = newValue
    }
}

class TestObservableObject: ObservableObject {
    @Published
    var testValue = 0

    func updateTestValue(_ newValue: Int) {
        testValue = newValue
    }
}

final class ExampleTest: XCTestCase {
    func test_publisherConvertibleEmitsNewValue() {
        let service = TestService()
        service.updateTestValue(true)
        let updatedSetting = awaitPublisherConvertible(service.testValuePublisher)
        XCTAssertEqual(true, updatedSetting)
    }

    func test_publishedEmitsSpecificValue() throws {
        let observableObject = TestObservableObject()
        let publishedValues = awaitPublished(observableObject.$testValue) {
            observableObject.updateTestValue(1)
        }

        let valueLastPublished = try XCTUnwrap(publishedValues.last)
        XCTAssertEqual(0, valueLastPublished)
    }
}

import MSLCombine

class ExampleService {
    @PublisherConvertible
    var exampleValue = false
    lazy var exampleValuePublisher = self.$exampleValue
}

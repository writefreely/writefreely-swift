import XCTest
@testable import WriteFreely

final class WriteFreelyClientTests: XCTestCase {
    static var allTests = [
        ("testWFClientInitializer_WithValidInstance_SetsRequestURL", testWFClientInitializer_WithValidInstance_SetsRequestURL),
        ("testCreateCollection_WithValidCollectionData_CreatesNewWFCollection", testCreateCollection_WithValidCollectionData_CreatesNewWFCollection)
    ]

    var client: WFClient!
    var session: MockURLSession!
    var instanceURL: URL!

    let user = WFUser.testUser
    let collection = WFCollection.testCollection

    override func setUpWithError() throws {
        super.setUp()
        session = MockURLSession()
        instanceURL = URL(string: "https://write.as/")!
        client = WFClient(for: instanceURL, with: session)
    }

    func testWFClientInitializer_WithValidInstance_SetsRequestURL() {
        client = WFClient(for: instanceURL, with: session)

        let expectedRequestURL = URL(string: "api/", relativeTo: instanceURL)!

        XCTAssertEqual(client.requestURL, expectedRequestURL)
    }

    func testCreateCollection_WithValidCollectionData_CreatesNewWFCollection() {
        guard let _ = try? setSessionData(resource: "test_collection", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 201
        client = WFClient(for: instanceURL, with: session)
        client.user = user

        let expectedCollection = WFCollection(
            alias: "new-blog",
            title: "Test Blog",
            description: "",
            styleSheet: "",
            isPublic: false,
            views: 0,
            email: "new-blog-wjn6epspzjqankz41mlfvz@writeas.com"
        )

        client.createCollection(
            withTitle: collection.title,
            alias: collection.alias,
            completion: { result in
                switch result {
                case .success(let collection):
                    XCTAssertEqual(collection.alias, expectedCollection.alias)
                    XCTAssertEqual(collection.title, expectedCollection.title)
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                }
            }
        )
    }

    @discardableResult
    private func setSessionData(resource: String, fileExt: String, for target: XCTestCase) throws -> URL? {
        guard let fileURL = Bundle.module.url(forResource: resource, withExtension: fileExt) else {
            return nil
        }
        do {
            session.nextData = try Data(contentsOf: fileURL)
            return fileURL
        } catch {
            throw error
        }
    }
}

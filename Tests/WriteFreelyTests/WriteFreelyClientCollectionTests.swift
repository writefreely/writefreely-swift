import XCTest
@testable import WriteFreely

final class WriteFreelyClientCollectionTests: XCTestCase {
    static var allTests = [
        ("testCreateCollection_WithValidCollectionData_CreatesNewWFCollection", testCreateCollection_WithValidCollectionData_CreatesNewWFCollection),
        ("testCreateCollection_WithInvalidCollectionData_ReturnsBadRequestError", testCreateCollection_WithInvalidCollectionData_ReturnsBadRequestError),
        ("testGetCollection_WithValidCollectionData_RetrievesCollectionMetadata", testGetCollection_WithValidCollectionData_RetrievesCollectionMetadata),
        ("testGetCollection_WithInvalidCollectionData_ReturnsInvalidDataError", testGetCollection_WithInvalidCollectionData_ReturnsInvalidDataError),
        ("testDeleteCollection_WithValidCollectionAlias_ReturnsTrue", testDeleteCollection_WithValidCollectionAlias_ReturnsTrue),
        ("testDeleteCollection_WithInvalidCollectionAlias_ReturnsInvalidResponseError", testDeleteCollection_WithInvalidCollectionAlias_ReturnsInvalidResponseError)
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
        client.user = user
    }
    
    func testCreateCollection_WithValidCollectionData_CreatesNewWFCollection() {
        guard let _ = try? session.setData(resource: "test_collection", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }
        
        session.expectedStatusCode = 201
        
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
    
    func testCreateCollection_WithInvalidCollectionData_ReturnsBadRequestError() {
        guard let _ = try? session.setData(resource: "error_collection_400", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }
        
        session.expectedStatusCode = 400
        
        client.createCollection(withTitle: "", completion: { result in
            switch result {
            case .success(let collection):
                XCTFail("Created a collection named '\(collection.title)'")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.badRequest)
            }
        })
    }
    
    func testGetCollection_WithValidCollectionData_RetrievesCollectionMetadata() {
        guard let _ = try? session.setData(resource: "test_collection", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }
        
        let expectedCollection = WFCollection(
            alias: "new-blog",
            title: "Test Blog",
            description: "",
            styleSheet: "",
            isPublic: false,
            views: 0,
            email: "new-blog-wjn6epspzjqankz41mlfvz@writeas.com"
        )
        
        client.getCollection(withAlias: "new-blog", completion: { result in
            switch result {
            case .success(let collection):
                XCTAssertEqual(collection.alias, expectedCollection.alias)
                XCTAssertEqual(collection.title, expectedCollection.title)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }
    
    func testGetCollection_WithInvalidCollectionData_ReturnsInvalidDataError() {
        guard let _ = try? session.setData(resource: "error_collection_400", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }
        
        client.getCollection(withAlias: "new-blog", completion: { result in
            switch result {
            case .success(let collection):
                XCTFail("Fetched a collection named '\(collection.title)'")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.invalidData)
            }
        })
    }
    
    func testDeleteCollection_WithValidCollectionAlias_ReturnsTrue() {
        guard let _ = try? session.setData(resource: "test_delete_collection", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }
        
        session.expectedStatusCode = 204
        
        client.deleteCollection(withAlias: "new-blog", completion: { result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "Delete collection should return true")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }
    
    func testDeleteCollection_WithInvalidCollectionAlias_ReturnsInvalidResponseError() {
        client = WFClient(for: instanceURL, with: session)
        client.user = user

        client.deleteCollection(withAlias: "fake-blog", completion: { result in
            switch result {
            case .success(let success):
                XCTFail("Got \(success) instead of error when deleting collection")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.invalidResponse)
            }
        })
    }
    
}

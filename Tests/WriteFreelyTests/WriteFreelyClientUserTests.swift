import XCTest
@testable import WriteFreely

final class WriteFreelyClientUserTests: XCTestCase {
    static var allTests = [
        ("testLogin_WithValidCredentials_SetsCurrentUser", testLogin_WithValidCredentials_SetsCurrentUser),
        ("testLogin_WithInvalidCredentials_ReturnsUnauthorized", testLogin_WithInvalidCredentials_ReturnsUnauthorized),
        ("testLogout_WithValidToken_CompletesSuccessfully", testLogout_WithValidToken_CompletesSuccessfully),
        ("testLogout_WithoutAccessToken_ReturnsBadRequestError", testLogout_WithoutAccessToken_ReturnsBadRequestError),
        ("testLogout_WithInvalidToken_ReturnsNotFoundError", testLogout_WithInvalidToken_ReturnsNotFoundError),
        ("testGetUserData_WithValidToken_FetchesTestUser", testGetUserData_WithValidToken_FetchesTestUser),
        ("testGetUserData_WithInvalidToken_ReturnsUnauthorized", testGetUserData_WithInvalidToken_ReturnsUnauthorized),
    ]

    var client: WFClient!
    var session: MockURLSession!
    var instanceURL: URL!

    let decoder = JSONDecoder()

    override func setUpWithError() throws {
        super.setUp()
        session = MockURLSession()
        instanceURL = URL(string: "https://write.as/")
        client = WFClient(for: instanceURL, with: session)
    }

    func testLogin_WithValidCredentials_SetsCurrentUser() {
        guard let _ = try? session.setData(resource: "test_user", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 200

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: "2015-02-03T02:41:19Z")
        let expectedUser = WFUser(
            token: "00000000-0000-0000-0000-000000000000",
            username: "matt",
            email: "matt@example.com",
            createdDate: date
        )

        client.login(username: "matt@example.com", password: "goodpassword", completion: { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(user.username, expectedUser.username)
                XCTAssertEqual(user.token, expectedUser.token)
                XCTAssertEqual(user.createdDate, expectedUser.createdDate)
                XCTAssertEqual(user.email, expectedUser.email)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }

    func testLogin_WithInvalidCredentials_ReturnsUnauthorized() {
        guard let _ = try? session.setData(resource: "incorrect_password_401", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 401

        client.login(username: "matt@example.com", password: "badpassword", completion: { result in
            switch result {
            case .success:
                XCTFail("Logged in successfully with invalid credentials")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.unauthorized)
            }
        })
    }

    func testLogout_WithValidToken_CompletesSuccessfully() {
        guard let _ = try? session.setData(resource: "test_logout_user", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 204

        client.logout(token: "00000000-0000-0000-0000-000000000000", completion: { result in
            switch result {
            case .success(let success):
                XCTAssertTrue(success, "User logout should return true")
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }

    func testLogout_WithoutAccessToken_ReturnsBadRequestError() {
        guard let _ = try? session.setData(resource: "bad_request_400", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 400

        client.logout(token: "", completion: { result in
            switch result {
            case .success:
                XCTFail("Logged out successfully without passing access token")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.badRequest)
            }
        })
    }

    func testLogout_WithInvalidToken_ReturnsNotFoundError() {
        guard let _ = try? session.setData(resource: "invalid_token_404", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 404

        client.logout(token: "1234", completion: { result in
            switch result {
            case .success:
                XCTFail("Logged out successfully without passing access token")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.notFound)
            }
        })
    }

    func testGetUserData_WithValidToken_FetchesTestUser() {
        guard let _ = try? session.setData(resource: "test_user", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 200
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: "2015-02-03T02:41:19Z")
        let expectedUser = WFUser(
            token: "00000000-0000-0000-0000-000000000000",
            username: "matt",
            email: "matt@example.com",
            createdDate: date
        )

        client.getUserData(token: "00000000-0000-0000-0000-000000000000", completion: { result in
            switch result {
            case .success(let user):
                XCTAssertEqual(expectedUser.username, user.username)
                XCTAssertEqual(expectedUser.email, user.email)
                XCTAssertEqual(expectedUser.createdDate, user.createdDate)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }

    func testGetUserData_WithInvalidToken_ReturnsUnauthorized() {
        guard let _ = try? session.setData(resource: "invalid_token_401", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 401

        client.getUserData(token: "", completion: { result in
            switch result {
            case .success:
                XCTFail("Fetched current user without valid access token")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.unauthorized)
            }
        })
    }

    func testGetUserCollections_WithValidToken_FetchesUserCollections() {
        guard let _ = try? session.setData(resource: "test_fetch_user_collections", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 200

        let expectedCollections = [
            WFCollection(
                alias: "matt",
                title: "Matt",
                description: "My great blog!",
                styleSheet: "",
                isPublic: true,
                views: 46,
                email: "matt-7e7euebput9t5jr3v4csgferutf@writeas.com"
            ),
            WFCollection(
                alias: "new-blog",
                title: "Test Blog",
                description: "Another great blog!",
                styleSheet: "",
                isPublic: false,
                views: 0,
                email: "new-blog-wjn6epspzjqankz41mlfvz@writeas.com"
            )
        ]

        client.getUserCollections(token: "00000000-0000-0000-0000-000000000000", completion: { result in
            switch result {
            case .success(let collections):
                XCTAssertEqual(collections[0].alias, expectedCollections[0].alias)
                XCTAssertEqual(collections[0].title, expectedCollections[0].title)
                XCTAssertEqual(collections[0].description, expectedCollections[0].description)
                XCTAssertEqual(collections[0].styleSheet, expectedCollections[0].styleSheet)
                XCTAssertEqual(collections[0].isPublic, expectedCollections[0].isPublic)
                XCTAssertEqual(collections[0].views, expectedCollections[0].views)
                XCTAssertEqual(collections[0].email, expectedCollections[0].email)
                XCTAssertEqual(collections[1].alias, expectedCollections[1].alias)
                XCTAssertEqual(collections[1].title, expectedCollections[1].title)
                XCTAssertEqual(collections[1].description, expectedCollections[1].description)
                XCTAssertEqual(collections[1].styleSheet, expectedCollections[1].styleSheet)
                XCTAssertEqual(collections[1].isPublic, expectedCollections[1].isPublic)
                XCTAssertEqual(collections[1].views, expectedCollections[1].views)
                XCTAssertEqual(collections[1].email, expectedCollections[1].email)
            case .failure(let error):
                XCTFail(error.localizedDescription)
            }
        })
    }

    func testGetUserCollections_WithInvalidToken_ReturnsUnauthorized() {
        guard let _ = try? session.setData(resource: "invalid_token_401", fileExt: "json", for: self) else {
            XCTFail("Error opening test resource file")
            return
        }

        session.expectedStatusCode = 401

        client.getUserCollections(token: "", completion: { result in
            switch result {
            case .success:
                XCTFail("Fetched current user without valid access token")
            case .failure(let error):
                XCTAssertEqual(error as? WFError, WFError.unauthorized)
            }
        })
    }
}

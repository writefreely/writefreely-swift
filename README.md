# WriteFreely

A Swift package that wraps the [WriteFreely](https://writefreely.org) API, for use in your Swift projects.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See _Deployment_ for notes on how to add the library to your app.

## TODO

- Add a test suite
- Add project metadocuments (LICENSE, CONTRIBUTING, &cet.)
- Add code documentation comments to methods
- Extend for use with [Write.as](https://write.as) (e.g., add `modifyToken` handling for unauthenticated post manipulation)
- Improve `movePost(id: with modifyToken: to collectionAlias: completion:)` to return `Result<[Post], Error>`

### Prerequisites

You'll need Xcode 11.5 / Swift 5.2 installed along with the command line tools to work on this package.

### Installing

1. Clone this repository.
2. There is no step two.writefreely-swift

## Running the tests

TK — see **TODO** section above

## Deployment

Follow the instructions in this [Apple Developer document](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) to add the `WriteFreely` Swift package to your app.

Once you've done that, just import the library into whichever files should consume it:

```swift
@import Foundation  // Or UIKit, Cocoa, &cet.
@import WriteFreely

// The rest of the Swift file goes here
```

Use public methods on the `WriteFreelyClient` to send and receive data from the server. The methods leverage completion blocks and the `Result` type, so you'd call them like so:

```swift
func loginHandler(result: (Result<User, Error>)) {
    do {
        let user = try result.get()
        print("Hello, \(user.username)!")
    } catch {
        print(error)
    }
}


guard let instanceURL = URL(string: "https://your.writefreely.host/") else { fatalError() }
let client = WriteFreelyClient(for: instanceURL)
client.login(username: "username", password: "password", completion: loginHandler)
```

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/writeas/writefreely-swift/tags).

## Authors

* **Angelo Stavrow** - *Initial work* - [AngeloStavrow](https://github.com/AngeloStavrow)

See also the list of [contributors](https://github.com/writeas/writefreely-swift/contributors) who participated in this project.

## License

This project is licensed under the BSD 3-Clause License - see the [LICENSE.md](LICENSE.md) file for details.

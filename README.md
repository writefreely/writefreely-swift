# WriteFreely

A Swift package that wraps the [WriteFreely](https://writefreely.org) API, for use in your Swift projects.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to add the dependency to your app.

## TODO

- Add a test suite
- Add project metadocuments (LICENSE, CONTRIBUTING, &cet.)
- Add code documentation comments to methods
- Extend for use with [Write.as](https://write.as) (e.g., add `modifyToken` handling for unauthenticated post manipulation)
- Refactor `CollectionJson`, `CollectionsJson`, `PostJson`, `PostsJson`, and `NestedPostsJson` into a single generic method
- Improve `movePost(id: with modifyToken: to collectionAlias: completion:)` to return `Result<[Post], Error>`

### Prerequisites

You'll need Xcode 11.5 / Swift 5.2 installed along with the command line tools to work on this package.

### Installing

1. Clone this repository.
2. There is no step two.

## Running the tests

TK — see **TODO** section above

## Deployment

Follow the instructions in this [Apple Developer document](https://developer.apple.com/documentation/swift_packages/adding_package_dependencies_to_your_app) to add the `WriteFreely` Swift package to your app.

## Contributing

Please read [CONTRIBUTING.md](CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/writeas/project_name/tags).

## Authors

* **Angelo Stavrow** - *Initial work* - [AngeloStavrow](https://github.com/AngeloStavrow)

See also the list of [contributors](https://github.com/writeas/project_name/contributors) who participated in this project.

## License

This project is licensed under the AGPL License - see the [LICENSE.md](LICENSE.md) file for details.

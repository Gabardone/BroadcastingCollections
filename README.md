# BroadcastingCollections
BroadcastingCollections is a library of classes and protocols that gives developers the ability to easily and efficiently keep track of changes being made to a collection, receiving callbacks about what precisely those changes are at the appropriate times and allowing for easy creation of automatically updated filtered and sorted versions of those collections.

## Compatibility
BroadcastingCollections is currently being built on Xcode 9.3.1, using Apple's latest SDK and Swift 4.1.

It's been used and tested on macOS 10.13 and iOS 11, but should work without changes on the latest versions of TvOS and WatchOS. 

It should also work with minimal changes on any older Apple OS which supports Swift deployment.

## Installation
Just clone the repo whenever it works best for your project setup, either as a submodule or as a sibling repository.

## Setup
BroadcastingCollections only depends on Foundation and the Swift standard library so you can easily add the framework straight to your project. You'll need to perform the following steps:

- Add the BroadcastingCollections project to your workspace or your project.
- Add BroadcastingCollections.framework as a dependency on your targets that will use it.
- Add a copy phase on your application's build process to copy the framework into the application's frameworks folder.

## How to Use
The included demo app target builds a standard setup for a master-detail UI, including support for multiple selection. Reading through it should be enough to clear out how to use it in similar setups.

For existing codebases, an easy thing to do is to replace a model array with an EditableBroadcastingOrderedSet and set a table controller as its listener.

## Contributing Ideas
The BroadcastingCollections library is already useful and useable in its current shape, but it's a first public version and is still in active development. Anything you believe should be improved deserves filing an issue, including but not limited to:

- Bugs. The more reproducible the better.
- Documentation issues, including of course lack of documentation or misleading/confusing comments.
- Feature requests. The more reasoned the better, especially welcome seeing what other people may want to do with BroadcastingCollections that they quite can't do.

Anyone who may want to contribute patches, keep in mind the following:

- For bug fixes, I'm aiming for keeping test coverate as high as possible. Please include unit tests that would reproduce the issue if possible.
- Please discuss any changes of the API or its current behavior before going ahead with them.

## Release History
* 1.0.0 (20180515)
 * Initial public release.

## License
Copyright 2018 Óscar Morales Vivó

Licensed under the MIT License: http://www.opensource.org/licenses/mit-license.php

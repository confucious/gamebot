// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Gamebot",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .executable(
            name: "Gamebot",
            targets: ["Gamebot"]),
        .library(
            name: "GamebotLib",
            targets: ["GamebotLib"]),
//        .executable(
//            name: "SlackMessageEnqueuer",
//            targets: ["SlackMessageEnqueuer"]),
//        .library(
//            name: "SlackMessageEnqueuerLib",
//            targets: ["SlackMessageEnqueuerLib"]),
        .library(
            name: "SlackModels",
            targets: ["SlackModels"]),
        .library(
            name: "Codenames",
            targets: ["Codenames"]),
        .library(
            name: "JustOne",
            targets: ["JustOne"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/swift-aws/aws-sdk-swift.git", from: "4.0.0"),
        .package(url: "https://github.com/swift-sprinter/aws-lambda-swift-sprinter-nio-plugin", from: "1.0.0-alpha.3"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(name: "Gamebot", dependencies: ["GamebotLib"]),
        .target(
            name: "GamebotLib",
            dependencies: [
                "LambdaSwiftSprinterNioPlugin",
                "SlackModels",
                "Codenames",
                "DynamoDB",
        ]),
        .testTarget(
            name: "GamebotTests",
            dependencies: ["GamebotLib"]),
//        .target(name: "SlackMessageEnqueuer", dependencies: ["SlackMessageEnqueuerLib"]),
//        .target(
//            name: "SlackMessageEnqueuerLib",
//            dependencies: [
//                "LambdaSwiftSprinterNioPlugin",
//                "SlackModels",
//                "SQS",
//        ]),
//        .testTarget(
//            name: "SlackMessageEnqueuerTests",
//            dependencies: ["SlackMessageEnqueuerLib"]),
        .target(
            name: "SlackModels",
            dependencies: []),
        //        .testTarget(
        //            name: "SlackModelsTests",
        //            dependencies: ["SlackModels"]),
        .target(
            name: "Codenames",
            dependencies: ["SlackModels"]),
        .testTarget(
            name: "CodenamesTests",
            dependencies: ["Codenames"]),
        .target(
            name: "JustOne",
            dependencies: ["SlackModels"]),
//        .testTarget(
//            name: "JustOneTests",
//            dependencies: ["JustOne"]),
    ]
)

import ProjectDescription

let project = Project(
    name: "Virtu",
    packages: [
        .package(url: "https://github.com/firebase/firebase-ios-sdk.git", .upToNextMajor(from: "11.8.1"))
    ],
    settings: .settings(
        base: [
            "DEVELOPMENT_TEAM": "966XSX2G64"
        ]
    ),
    targets: [
        .target(
            name: "Virtu",
            destinations: [.iPhone],
            product: .app,
            bundleId: "net.sndwv.Virtu",
            deploymentTargets: .iOS("18.2"),
            infoPlist: .extendingDefault(with: [
                "UILaunchScreen": ["UIColorName": "Background"],
                "FirebaseAppDelegateProxyEnabled": false,
                "APIBaseURL": "http://169.254.153.53:3000",
                "S3BaseURL": "https://cm-virtu-convert-out.s3.us-east-1.amazonaws.com"
            ]),
            sources: ["Virtu/**"],
            resources: .resources([
                "Virtu/Resources/**",
            ]),
            dependencies: [
                .package(product: "FirebaseAuth"),
                .package(product: "FirebaseCore")
            ]
        )
    ]
)

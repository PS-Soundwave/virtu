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
                "APIBaseURL": "http://169.254.34.72:3000",
                "S3BaseURL": "https://d2atizltqcfmsa.cloudfront.net",
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"]
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

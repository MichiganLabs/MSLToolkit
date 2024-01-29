#  [Charles Proxy](https://www.charlesproxy.com/download/)

# ServerTrustManager should only be used for DEBUG builds and should **never** be used for Release builds.

## Why Use a Proxy?
A proxy allows you to inspect and manipulate http requests made from web and mobile apps:
* Simulating bad network conditions (timeouts, low bandwidth, latency)
* Simulating remote APIs with local fake data (using map-local)
* Editing responses and requests before they are sent or received (using breakpoints)
* Transparently monitor requests with minimal (if any) app changes.

## Creating a Debug Cert
For simplicity you may want to use a pre-existing certificate, consider this with your team before creating a new certificate. If a new certificate is required follow the following steps:
```
$ openssl req -x509 -newkey rsa:4096 -keyout privatekey.pem -out certificate.pem -days 365 -nodes
$ openssl pkcs12 -export -out debug_cert.p12 -inkey privatekey.pem -in certificate.pem
```

## Setup Charles
1. From the menu select "Proxy" → "SSL Proxying Settings" → "Root Certificate" → “Create Secure Store” and go through the setup.
1. After setting up the secure store, select “P12” and select your `.p12` file.
1. Restart Charles

## Initializing in iOS
### Setup your Bundle
You must first generate a bundle with your Charles certificate. If using a pre-existing debug cert, once should already be provided for you. This file should be saved in the appropriate package, in the location `Sources/XXXX/Resources/`

Then, update `XXXX/Package.swift` with the following `resources` section.

```
let package = Package(
    ...
    
    targets: [
        ...
        resources: [
            .copy("Resources/SSLCertificate.bundle")
        ]
    ]
)
``` 

### Include in your `Session` setup
Wherever a `Session` is being created in your project you will now want to include the `serverTrustManager`. The start of an `ApiService` using leveraging the certificate is below.
```
public class ApiService: ApiServiceProtocol, HearseeServiceProtocol {
    let session: Session

    public init(serverUrl: String) {
        var serverTrustManager: ServerTrustManager?

        #if DEBUG
            // We only want to use the Charles Proxy Evaluator when we are debugging
            if
                let url = Bundle.module.url(forResource: "SSLCertificates", withExtension: "bundle"),
                let bundle = Bundle(url: url)
            {
                serverTrustManager = MSLNetworking.generateServerTrustManager(charlesCertBundle: bundle)
            }
        #endif

        session = Session(
            serverTrustManager: serverTrustManager,
            eventMonitors: [NetworkLogger()]
        )
    }
}

```

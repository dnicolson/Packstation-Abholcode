# Packstation Abholcode

An iOS app that includes a Watch Extension to display the DHL Packstation Abholcode on an Apple Watch without the need for the iOS device.

<div style="align:center" align="center">
    <img src="https://github.com/dnicolson/Packstation-Abholcode/blob/main/Assets/Screenshot%20watchOS.png?raw=true" width="200px">
</div>

## How it Works

1. Sign in on an iOS device is handled by GoogleSignIn.
2. The Abholcode is fetched from Gmail using GoogleAPIClientForREST/Gmail.
3. The sign in authorization is saved in the Keychain.
4. A WatchConnectivity session is used to send the raw Keychain data to the watch if available.
5. The authorization is retrieved from the Keychain on the watch using GTMAppAuth.

It is necessary to manually retrieve, send and save the Keychain data on the watch because since watchOS 2.0 the watch has a distinct Keychain from the iOS device.

# Release Checklist

Do not distribute a production build until every release gate below is complete.

## Content and legal gates

- [ ] Obtain written permission to use the content provider's API, trademarks, artwork, lyrics, streams, and download capability in every distribution territory.
- [ ] Keep the authorization evidence available for App Review.
- [ ] Replace `BAIDUFM_API_BASE_URL` with the authorized production HTTPS endpoint.
- [ ] Set `BAIDUFM_CONTENT_PROVIDER_AUTHORIZED=YES` only after authorization evidence has been reviewed; Release builds intentionally fail while it remains `NO`.
- [ ] Confirm that the production provider returns HTTPS URLs for audio, artwork, and lyrics.
- [ ] Publish Terms of Use, a privacy policy, copyright contact information, and a content-removal process.

## Security and privacy gates

- [x] Remove App Transport Security exceptions and reject insecure media URLs.
- [x] Add a privacy manifest for app-container file metadata and `UserDefaults` access.
- [ ] Verify the merged archive privacy report for all third-party dependencies.
- [ ] Complete the App Store privacy questionnaire from observed production behavior.
- [ ] Run a dependency vulnerability and license audit before each release.

## Build and distribution gates

- [x] Provide a signable iOS application target and a shared `BaiduFMApp` scheme.
- [x] Separate Debug and Release build configuration files.
- [ ] Set the Apple Developer team and final bundle identifier.
- [ ] Provide final App Store icons, screenshots, support URL, and marketing metadata.
- [ ] Produce a Release archive and distribute it to internal TestFlight testers.
- [ ] Verify launch, playback, interruptions, background audio, and downloads on physical devices.

## Quality gates

- [ ] Maintain at least 99.9% crash-free sessions during the staged rollout.
- [ ] Keep playback-start failures below 0.5% on supported networks.
- [ ] Verify English and Simplified Chinese on every supported device class.
- [ ] Complete VoiceOver, Dynamic Type, contrast, and Reduce Motion audits.

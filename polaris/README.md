# Polaris

Polaris is a Flutter astronomy companion for planning and recording observations.

## Observation location and weather

Quest sessions can use the device's current location or manually entered
coordinates. The observation site is stored locally for offline use. Android
asks for location permission only when the user requests a GPS refresh; a
manually entered location does not require permission. Weather is fetched from
the keyless Open-Meteo forecast API, cached locally, and reused when offline.
The profile and observation sessions show temperature, dew point, cloud cover,
humidity, wind, gusts, and precipitation probability.

## Visibility and guest access

The catalog calculates object altitude and azimuth from labeled right
ascension/declination coordinates and the saved observation site. The
“Видны сейчас” filter uses altitude above 15 degrees; records without both
coordinates are not included. Guests can browse the catalog and use local
observation features; account access is requested for catalog edits and photo
uploads. The profile includes a persistent red night-mode switch.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

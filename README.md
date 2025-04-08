# Farmer App

A complete farming companion app for weather insights, crop health monitoring, and disease detection.

## Setup Instructions

### Firebase Setup

1. This project uses Firebase for authentication. To set up Firebase:

   - In Xcode, go to File > Add Packages
   - Enter the Firebase iOS SDK URL: https://github.com/firebase/firebase-ios-sdk.git
   - Select the following packages:
     - FirebaseAuth
     - FirebaseFirestore (optional, for future use)
     - FirebaseStorage (optional, for future use)

2. Make sure the `GoogleService-Info.plist` file is added to the project. This file contains your Firebase configuration.

3. Initialize Firebase in your AppDelegate as shown in the `FarmerApp.swift` file.

### Running the App

1. Open `Farmer.xcodeproj` in Xcode
2. Select your target device or simulator
3. Build and run the app (⌘R)

## Features

- Onboarding screens to introduce app features
- User authentication (signup, login, password reset)
- Weather forecasts for farming (coming soon)
- Disease detection for crops using ML models (coming soon)
- Crop analytics (coming soon)

## Architecture

The app uses:

- SwiftUI for the user interface
- Firebase Authentication for user management
- MVVM architecture pattern

## License

[Your License Information] 
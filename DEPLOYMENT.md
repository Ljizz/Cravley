# Cravely iOS App - Deployment Guide

This guide will help you set up and deploy the Cravely iOS app from scratch.

## Prerequisites

### Required Software
- **Xcode 15.0+** (latest version recommended)
- **iOS 16.0+** deployment target
- **macOS 13.0+** for development
- **Swift 5.9+**
- **Git** for version control

### Required Accounts
- **Apple Developer Account** ($99/year) for App Store deployment
- **Firebase Account** (free tier available)
- **Yelp API Account** (for restaurant data)
- **Google Cloud Platform Account** (for Google Places API)

## Project Setup

### 1. Clone and Initial Setup

```bash
# Clone the repository
git clone <repository-url>
cd cravely-ios

# Install dependencies (if using CocoaPods)
pod install

# Or if using Swift Package Manager (recommended)
# Dependencies will be resolved automatically when opening in Xcode
```

### 2. Xcode Project Configuration

1. Open `Cravely.xcodeproj` in Xcode
2. Select the project in the navigator
3. Update the following settings:

#### General Tab
- **Bundle Identifier**: `com.yourcompany.cravely` (must be unique)
- **Version**: `1.0.0`
- **Build**: `1`
- **Deployment Target**: `iOS 16.0`
- **Team**: Select your Apple Developer Team

#### Signing & Capabilities
- **Automatically manage signing**: Enabled
- **Team**: Your Apple Developer Team
- Add required capabilities:
  - Push Notifications
  - Background Modes (Location updates, Background fetch, Remote notifications)
  - App Groups (optional, for sharing data)
  - Associated Domains (for deep linking)

### 3. Firebase Setup

#### Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or select existing
3. Add iOS app with your bundle identifier
4. Download `GoogleService-Info.plist`
5. Replace `Cravely/Resources/GoogleService-Info.plist.template` with the downloaded file

#### Enable Firebase Services
1. **Authentication**
   - Enable Email/Password provider
   - Enable Google Sign-In (optional)
   - Enable Apple Sign-In
   
2. **Firestore Database**
   - Create database in production mode
   - Set up security rules (see template in GoogleService-Info.plist.template)
   
3. **Storage**
   - Enable Cloud Storage
   - Set up security rules for user photos and restaurant images
   
4. **Cloud Messaging**
   - Enable for push notifications
   - Upload APNs certificates/keys

#### Firebase Security Rules

**Firestore Rules** (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read and write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Restaurants are readable by all authenticated users
    match /restaurants/{restaurantId} {
      allow read: if request.auth != null;
      allow write: if false; // Only server-side updates
    }
    
    // Reviews are readable by all, writable by owners
    match /reviews/{reviewId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null && request.auth.uid == request.resource.data.userID;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userID;
    }
    
    // Wait time reports
    match /waitTimeReports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth != null && request.auth.uid == resource.data.userID;
    }
  }
}
```

**Storage Rules** (`storage.rules`):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /users/{userId}/profile/{imageId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    match /reviews/{reviewId}/photos/{imageId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null;
    }
  }
}
```

### 4. API Keys Configuration

#### Yelp API Setup
1. Go to [Yelp Developer Portal](https://www.yelp.com/developers)
2. Create a new app
3. Get your API key
4. Create `APIKeys.plist` in `Cravely/Resources/`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>YelpAPIKey</key>
    <string>YOUR_YELP_API_KEY_HERE</string>
    <key>GooglePlacesAPIKey</key>
    <string>YOUR_GOOGLE_PLACES_API_KEY_HERE</string>
</dict>
</plist>
```

#### Google Places API Setup
1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable Places API
3. Create credentials (API Key)
4. Add to `APIKeys.plist`

### 5. Push Notifications Setup

#### Apple Push Notification Service (APNs)
1. In Apple Developer Portal, create APNs certificates or authentication keys
2. Upload to Firebase Cloud Messaging
3. Test push notifications in Firebase Console

### 6. Premium Subscription Setup

#### App Store Connect Configuration
1. Go to [App Store Connect](https://appstoreconnect.apple.com/)
2. Create your app
3. Set up in-app purchases:
   - `cravely_premium_monthly` - Monthly subscription ($3.99)
   - `cravely_premium_yearly` - Yearly subscription ($29.99)

#### RevenueCat Setup (Optional)
1. Create account at [RevenueCat](https://www.revenuecat.com/)
2. Configure products
3. Add SDK to project
4. Update subscription handling code

## Testing

### Local Development
1. Use iOS Simulator for basic testing
2. Use physical device for location and camera features
3. Test with mock data using `FeatureFlags.showMockData = true`

### Test Flight
1. Archive app in Xcode
2. Upload to App Store Connect
3. Add internal/external testers
4. Distribute beta versions

### Unit Tests
```bash
# Run unit tests
cmd+U in Xcode
# Or via command line
xcodebuild test -scheme Cravely -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment

### App Store Submission

#### Preparation
1. Update version numbers
2. Create app screenshots (required sizes)
3. Write app description and keywords
4. Set up app privacy details
5. Configure app categories and age rating

#### Submission Process
1. Archive app in Xcode (Product → Archive)
2. Upload to App Store Connect
3. Fill out app information
4. Submit for review
5. Monitor review status

#### App Store Assets Required
- **App Icon**: 1024x1024px
- **Screenshots**: 
  - iPhone 6.7": 1290x2796px (required)
  - iPhone 6.5": 1242x2688px
  - iPhone 5.5": 1242x2208px
  - iPad Pro (6th Gen): 2048x2732px
- **Privacy Policy URL**
- **Support URL**

### Distribution Certificates

#### Production Certificates
1. **iOS Distribution Certificate**
2. **Push Notification Certificate**
3. **Provisioning Profile** (App Store distribution)

## Monitoring and Analytics

### Firebase Analytics
- Automatic event tracking enabled
- Custom events for key user actions
- Conversion tracking for premium upgrades

### Crashlytics
- Automatic crash reporting
- Custom logging for debugging
- Performance monitoring

### App Store Analytics
- Download and usage metrics
- User acquisition data
- Revenue tracking

## Environment Configuration

### Development Environment
```swift
#if DEBUG
static let baseAPIURL = "https://api-dev.cravely.app"
static let enableDebugFeatures = true
#endif
```

### Production Environment
```swift
#if RELEASE
static let baseAPIURL = "https://api.cravely.app"
static let enableDebugFeatures = false
#endif
```

## Security Considerations

### Data Protection
- All sensitive data encrypted at rest
- API keys stored securely in plist files
- User authentication via Firebase Auth
- Network traffic over HTTPS only

### Privacy Compliance
- Location permission with clear usage description
- Photo library access for review photos only
- Data collection transparency
- GDPR/CCPA compliance for user data

## Troubleshooting

### Common Issues

#### Build Errors
- **Missing Bundle Identifier**: Update in project settings
- **Code Signing Issues**: Check developer team and certificates
- **Missing API Keys**: Ensure APIKeys.plist is added to project

#### Firebase Issues
- **GoogleService-Info.plist not found**: Ensure file is in project and build target
- **Authentication errors**: Check Firebase project configuration
- **Database permission denied**: Review Firestore security rules

#### API Issues
- **Yelp API errors**: Check API key and rate limits
- **Location services not working**: Verify permissions in Info.plist

### Debug Features
```swift
// Enable debug menu in development
#if DEBUG
FeatureFlags.enableDebugFeatures = true
FeatureFlags.showMockData = true
#endif
```

## Support and Maintenance

### Monitoring
- Set up alerts for crash rates and API errors
- Monitor user feedback and app reviews
- Track key performance indicators (KPIs)

### Updates
- Regular security updates
- iOS version compatibility updates
- Feature enhancements based on user feedback
- Bug fixes and performance improvements

---

## Quick Start Checklist

- [ ] Xcode project configured with correct bundle ID
- [ ] Firebase project created and configured
- [ ] GoogleService-Info.plist added to project
- [ ] API keys configured (Yelp, Google Places)
- [ ] Code signing certificates set up
- [ ] App Store Connect app created
- [ ] In-app purchases configured
- [ ] Push notification certificates uploaded
- [ ] Privacy policy and support URLs ready
- [ ] App tested on device
- [ ] Screenshots and app metadata prepared

For additional help, refer to the individual service documentation or create an issue in the repository.
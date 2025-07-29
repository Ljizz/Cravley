# Cravely - Smart Dining Companion iOS App

Cravely is an intelligent dining companion app that helps users discover amazing restaurants using AI-powered recommendations, real-time wait times, and personalized preferences.

## Features

### Core Features (MVP)
- **User Authentication**: Email/password, Google Sign-In, and Apple Sign-In
- **Location-Based Discovery**: Find restaurants near you with map and list views
- **Restaurant Profiles**: Detailed information including menus, reviews, and contact details
- **Favorites & Lists**: Save favorite restaurants and create custom collections
- **Crowdsourced Wait Times**: Submit and view real-time wait time data
- **AI Recommendations**: Personalized restaurant suggestions based on preferences

### Premium Features
- **Advanced AI Engine**: Hyper-personalized recommendations
- **Smart Wait Time Alerts**: Push notifications when wait times drop
- **Extended Search Radius**: Discover restaurants up to 50 miles away
- **Unlimited Lists**: Create unlimited restaurant collections
- **Priority Support**: Faster customer support

## Architecture

### Technology Stack
- **Frontend**: SwiftUI (iOS 17+)
- **Backend**: Firebase (Auth, Firestore, Storage, Messaging)
- **Maps**: Apple MapKit with Core Location
- **External APIs**: 
  - Yelp Fusion API for restaurant data
  - OpenAI API for AI recommendations (future enhancement)
- **Authentication**: Firebase Auth with social login support
- **Subscription**: Apple StoreKit for premium features

### Project Structure
```
Cravely/
├── CravelyApp.swift              # Main app entry point
├── ContentView.swift             # Root navigation view
├── Models/
│   ├── User.swift               # User data models
│   └── Restaurant.swift         # Restaurant data models
├── Managers/
│   ├── AuthenticationManager.swift    # User authentication
│   ├── LocationManager.swift          # Core Location services
│   └── RestaurantManager.swift        # Restaurant data management
├── Services/
│   ├── YelpService.swift             # Yelp API integration
│   └── AIRecommendationService.swift # AI recommendation engine
├── Views/
│   ├── AuthenticationView.swift      # Login/signup screens
│   ├── DiscoverView.swift           # Restaurant discovery
│   ├── RestaurantDetailView.swift   # Restaurant details
│   ├── FavoritesView.swift          # Favorites and lists
│   ├── CravelyPicksView.swift       # AI recommendations
│   ├── ProfileView.swift            # User profile and settings
│   └── FilterView.swift             # Search filters
└── Info.plist                      # App configuration
```

## Setup Instructions

### Prerequisites
- Xcode 15.0+
- iOS 17.0+ deployment target
- Apple Developer Account
- Firebase project
- Yelp API key

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-org/cravely-ios.git
   cd cravely-ios
   ```

2. **Install Dependencies**
   The project uses Swift Package Manager. Dependencies will be automatically resolved when you open the project in Xcode.

3. **Firebase Setup**
   - Create a new Firebase project at https://console.firebase.google.com
   - Add an iOS app to your Firebase project
   - Download `GoogleService-Info.plist` and add it to your Xcode project
   - Enable Authentication with Email/Password, Google, and Apple Sign-In
   - Set up Cloud Firestore database
   - Configure Firebase Storage

4. **API Keys Configuration**
   - Get a Yelp API key from https://www.yelp.com/developers
   - Create a `Config.plist` file and add your API keys:
   ```xml
   <?xml version="1.0" encoding="UTF-8"?>
   <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
   <plist version="1.0">
   <dict>
       <key>YelpAPIKey</key>
       <string>YOUR_YELP_API_KEY</string>
       <key>OpenAIAPIKey</key>
       <string>YOUR_OPENAI_API_KEY</string>
   </dict>
   </plist>
   ```

5. **Google Sign-In Setup**
   - Add your iOS app to the Google Sign-In configuration
   - Add the URL scheme to your app's Info.plist

6. **Apple Sign-In Setup**
   - Enable Sign in with Apple capability in your app
   - Configure Apple Sign-In in your Apple Developer account

### Build and Run

1. Open `Cravely.xcodeproj` in Xcode
2. Select your development team and update the bundle identifier
3. Build and run the project on a device or simulator

## Development Workflow

### Phase 1: Core Features (Weeks 1-8)
- [x] Project setup and architecture
- [x] User authentication system
- [x] Location services integration
- [x] Restaurant discovery and search
- [x] Favorites and lists functionality
- [x] Wait time submission system

### Phase 2: Premium Features (Weeks 9-10)
- [ ] AI recommendation engine
- [ ] Push notification system
- [ ] Subscription management
- [ ] Premium feature gates

### Phase 3: Polish & Launch (Weeks 11-12)
- [ ] UI/UX improvements
- [ ] Performance optimization
- [ ] App Store preparation
- [ ] Beta testing and feedback

## Key Components

### Authentication System
- Supports multiple sign-in methods
- Secure user profile management
- Preference synchronization across devices

### Restaurant Discovery
- Location-based search with configurable radius
- Advanced filtering by cuisine, price, rating, wait time
- Map and list view modes
- Real-time restaurant data from Yelp API

### AI Recommendations
- Personalized suggestions based on user preferences
- Machine learning algorithm considering dining history
- Location-aware recommendations
- Explanation of why restaurants are recommended

### Wait Time System
- Crowdsourced wait time reporting
- Real-time average calculations
- Historical wait time data
- Smart alerts for premium users

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style Guidelines
- Follow Swift API Design Guidelines
- Use SwiftUI best practices
- Maintain consistent naming conventions
- Write unit tests for business logic
- Document public APIs

## Testing

### Unit Tests
```bash
# Run unit tests
xcodebuild test -scheme Cravely -destination 'platform=iOS Simulator,name=iPhone 15'
```

### UI Tests
```bash
# Run UI tests
xcodebuild test -scheme CravelyUITests -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Deployment

### App Store Release
1. Update version number in Info.plist
2. Create app icons and screenshots
3. Write App Store description and keywords
4. Submit for App Store review
5. Monitor app performance and user feedback

### Firebase Security Rules
Ensure proper Firestore security rules are configured:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can only access their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Restaurants are publicly readable
    match /restaurants/{restaurantId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null; // For wait time submissions
    }
    
    // User lists are private
    match /restaurantLists/{listId} {
      allow read, write: if request.auth != null && 
        resource.data.userID == request.auth.uid;
    }
  }
}
```

## Support

For technical support or questions:
- Email: dev@cravely.app
- Documentation: https://docs.cravely.app
- Issues: https://github.com/your-org/cravely-ios/issues

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Restaurant data provided by Yelp Fusion API
- Maps powered by Apple MapKit
- Icons from SF Symbols
- Firebase for backend services
- OpenAI for AI recommendations (future enhancement)
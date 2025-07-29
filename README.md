# Cravely

A smart dining companion iOS app that helps users discover and decide where to eat with AI-powered recommendations, real-time wait times, and personalized suggestions.

## Features

### Core Features (MVP)
- 📍 Location-based restaurant discovery (list + map view)
- 🍽️ Restaurant profiles with menus, reviews, and wait times
- ⭐ Save favorites and create custom lists
- 📸 User-submitted reviews and photos
- ⏰ Crowdsourced wait time reporting
- 🤖 AI-powered recommendations (Premium)

### Premium Features ($3.99/month or $29.99/year)
- 🎯 Personalized AI dining assistant
- 🔔 Smart alerts and notifications
- 📊 Forecasted busy hours
- 🚀 Early access to new features

## Tech Stack

- **Frontend**: Swift, SwiftUI, Core Location, MapKit
- **Backend**: Firebase
- **APIs**: Yelp/Google Places API
- **AI**: OpenAI or open-source models
- **Payments**: RevenueCat

## Project Structure

```
Cravely/
├── App/
│   ├── CravelyApp.swift
│   └── ContentView.swift
├── Models/
│   ├── Restaurant.swift
│   ├── Review.swift
│   ├── WaitTime.swift
│   ├── User.swift
│   └── Location.swift
├── Views/
│   ├── Discovery/
│   ├── Restaurant/
│   ├── Profile/
│   └── Premium/
├── Services/
│   ├── LocationService.swift
│   ├── RestaurantService.swift
│   ├── ReviewService.swift
│   ├── WaitTimeService.swift
│   └── AIRecommendationService.swift
├── Utils/
│   ├── Constants.swift
│   └── Extensions.swift
└── Resources/
    ├── Info.plist
    └── Assets.xcassets
```

## Getting Started

1. Clone the repository
2. Open `Cravely.xcodeproj` in Xcode
3. Configure Firebase settings
4. Add API keys for Yelp/Google Places
5. Build and run on iOS simulator or device

## MVP Success Metrics

- Activation rate (profile setup and preferences)
- Search-to-visit conversion
- Premium upgrade conversion
- AI recommendation usage
- User retention (D1, D7, D30)

## Future Roadmap

- In-app reservations (OpenTable integration)
- Group voting for dining decisions
- Social features and shared lists
- Apple Watch integration
- AR-based restaurant browsing
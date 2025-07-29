import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingPreferences = false
    @State private var showingSubscription = false
    
    var body: some View {
        NavigationView {
            List {
                // User Info Section
                Section {
                    UserInfoRow()
                }
                
                // Preferences Section
                Section("Preferences") {
                    NavigationLink(destination: PreferencesView()) {
                        Label("Dining Preferences", systemImage: "slider.horizontal.3")
                    }
                    
                    NavigationLink(destination: NotificationSettingsView()) {
                        Label("Notifications", systemImage: "bell")
                    }
                }
                
                // Premium Section
                if let user = authManager.currentUser {
                    Section("Premium") {
                        if user.isPremium {
                            PremiumStatusRow()
                        } else {
                            Button(action: {
                                showingSubscription = true
                            }) {
                                Label("Upgrade to Premium", systemImage: "star.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                
                // App Section
                Section("App") {
                    NavigationLink(destination: AboutView()) {
                        Label("About Cravely", systemImage: "info.circle")
                    }
                    
                    NavigationLink(destination: SupportView()) {
                        Label("Help & Support", systemImage: "questionmark.circle")
                    }
                    
                    Link("Privacy Policy", destination: URL(string: "https://cravely.app/privacy")!)
                        .foregroundColor(.primary)
                    
                    Link("Terms of Service", destination: URL(string: "https://cravely.app/terms")!)
                        .foregroundColor(.primary)
                }
                
                // Account Section
                Section("Account") {
                    Button("Sign Out") {
                        authManager.signOut()
                    }
                    .foregroundColor(.red)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingSubscription) {
                SubscriptionView()
            }
        }
    }
}

struct UserInfoRow: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        HStack(spacing: 16) {
            // Profile Image
            AsyncImage(url: URL(string: authManager.currentUser?.profileImageURL ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Circle()
                    .fill(Color.orange.opacity(0.3))
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.title)
                            .foregroundColor(.orange)
                    )
            }
            .frame(width: 60, height: 60)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(authManager.currentUser?.name ?? "User")
                    .font(.headline)
                
                Text(authManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if authManager.currentUser?.isPremium == true {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Premium Member")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

struct PremiumStatusRow: View {
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "star.fill")
                        .foregroundColor(.orange)
                    Text("Premium Active")
                        .fontWeight(.semibold)
                }
                
                Text("Enjoy unlimited features and AI recommendations")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Manage") {
                // TODO: Open subscription management
            }
            .buttonStyle(.bordered)
            .foregroundColor(.orange)
        }
    }
}

struct PreferencesView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var preferences: UserPreferences
    @State private var selectedCuisines: Set<String> = []
    @State private var selectedDietaryRestrictions: Set<String> = []
    
    let cuisineTypes = ["Italian", "Mexican", "Chinese", "Japanese", "Thai", "Indian", "American", "French", "Mediterranean", "Korean", "Vietnamese", "Greek"]
    let dietaryOptions = ["Vegetarian", "Vegan", "Gluten-Free", "Keto", "Paleo", "Dairy-Free", "Nut-Free", "Halal", "Kosher"]
    
    init() {
        _preferences = State(initialValue: UserPreferences())
    }
    
    var body: some View {
        List {
            Section("Cuisine Preferences") {
                ForEach(cuisineTypes, id: \.self) { cuisine in
                    HStack {
                        Text(cuisine)
                        Spacer()
                        if selectedCuisines.contains(cuisine) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedCuisines.contains(cuisine) {
                            selectedCuisines.remove(cuisine)
                        } else {
                            selectedCuisines.insert(cuisine)
                        }
                        updatePreferences()
                    }
                }
            }
            
            Section("Dietary Restrictions") {
                ForEach(dietaryOptions, id: \.self) { option in
                    HStack {
                        Text(option)
                        Spacer()
                        if selectedDietaryRestrictions.contains(option) {
                            Image(systemName: "checkmark")
                                .foregroundColor(.orange)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if selectedDietaryRestrictions.contains(option) {
                            selectedDietaryRestrictions.remove(option)
                        } else {
                            selectedDietaryRestrictions.insert(option)
                        }
                        updatePreferences()
                    }
                }
            }
            
            Section("Price Range") {
                Picker("Price Range", selection: $preferences.priceRange) {
                    ForEach(PriceRange.allCases, id: \.self) { range in
                        Text(range.description).tag(range)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .onChange(of: preferences.priceRange) { _ in
                    updatePreferences()
                }
            }
            
            Section("Distance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Maximum Distance: \(String(format: "%.1f", preferences.maxDistance)) miles")
                        .font(.subheadline)
                    
                    Slider(value: $preferences.maxDistance, in: 1...25, step: 0.5) {
                        Text("Distance")
                    }
                    .onChange(of: preferences.maxDistance) { _ in
                        updatePreferences()
                    }
                }
            }
        }
        .navigationTitle("Preferences")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentPreferences()
        }
    }
    
    private func loadCurrentPreferences() {
        if let user = authManager.currentUser {
            preferences = user.preferences
            selectedCuisines = Set(user.preferences.cuisineTypes)
            selectedDietaryRestrictions = Set(user.preferences.dietaryRestrictions)
        }
    }
    
    private func updatePreferences() {
        preferences.cuisineTypes = Array(selectedCuisines)
        preferences.dietaryRestrictions = Array(selectedDietaryRestrictions)
        
        guard var user = authManager.currentUser else { return }
        user.preferences = preferences
        
        Task {
            await authManager.updateUserProfile(user)
        }
    }
}

struct NotificationSettingsView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var notifications: NotificationPreferences
    
    init() {
        _notifications = State(initialValue: NotificationPreferences())
    }
    
    var body: some View {
        List {
            Section("Smart Alerts") {
                Toggle("Wait Time Alerts", isOn: $notifications.waitTimeAlerts)
                    .onChange(of: notifications.waitTimeAlerts) { _ in
                        updateNotifications()
                    }
                
                Toggle("New Recommendations", isOn: $notifications.newRecommendations)
                    .onChange(of: notifications.newRecommendations) { _ in
                        updateNotifications()
                    }
                
                Toggle("Favorite Restaurant Updates", isOn: $notifications.favoriteRestaurantUpdates)
                    .onChange(of: notifications.favoriteRestaurantUpdates) { _ in
                        updateNotifications()
                    }
            }
            
            Section(footer: Text("Manage which notifications you receive from Cravely.")) {
                EmptyView()
            }
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadCurrentNotifications()
        }
    }
    
    private func loadCurrentNotifications() {
        if let user = authManager.currentUser {
            notifications = user.preferences.notifications
        }
    }
    
    private func updateNotifications() {
        guard var user = authManager.currentUser else { return }
        user.preferences.notifications = notifications
        
        Task {
            await authManager.updateUserProfile(user)
        }
    }
}

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "star.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.orange)
                        
                        Text("Cravely Premium")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Unlock the full power of AI-driven dining")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)
                    
                    // Features
                    VStack(spacing: 16) {
                        FeatureRow(icon: "sparkles", title: "Advanced AI Recommendations", description: "Get hyper-personalized restaurant suggestions")
                        FeatureRow(icon: "bell.badge", title: "Smart Wait Time Alerts", description: "Be notified when wait times drop at your favorites")
                        FeatureRow(icon: "map", title: "Extended Search Radius", description: "Discover amazing restaurants up to 50 miles away")
                        FeatureRow(icon: "list.star", title: "Unlimited Lists", description: "Create and share unlimited restaurant collections")
                        FeatureRow(icon: "crown", title: "Priority Support", description: "Get help faster with premium customer support")
                    }
                    .padding(.horizontal)
                    
                    // Pricing
                    VStack(spacing: 12) {
                        Text("$4.99/month")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Text("Cancel anytime")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Subscribe Button
                    Button("Start Free Trial") {
                        // TODO: Implement subscription
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal)
                    
                    Text("7-day free trial, then $4.99/month")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.orange)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

struct AboutView: View {
    var body: some View {
        List {
            Section {
                VStack(spacing: 16) {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("Cravely")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Version 1.0.0")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            }
            
            Section("About") {
                Text("Cravely is your smart dining companion that uses AI to help you discover amazing restaurants based on your preferences, location, and dining history.")
                    .font(.body)
                    .padding(.vertical, 8)
            }
            
            Section("Credits") {
                Text("Built with love by the Cravely team")
                Text("Restaurant data powered by Yelp")
                Text("Maps provided by Apple MapKit")
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SupportView: View {
    var body: some View {
        List {
            Section("Get Help") {
                Link("FAQ", destination: URL(string: "https://cravely.app/faq")!)
                Link("Contact Support", destination: URL(string: "mailto:support@cravely.app")!)
                Link("Report a Bug", destination: URL(string: "https://cravely.app/bug-report")!)
            }
            
            Section("Community") {
                Link("Follow us on Twitter", destination: URL(string: "https://twitter.com/cravelyapp")!)
                Link("Join our Discord", destination: URL(string: "https://discord.gg/cravely")!)
            }
        }
        .navigationTitle("Help & Support")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthenticationManager())
}
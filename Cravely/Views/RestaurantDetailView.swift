import SwiftUI
import MapKit

struct RestaurantDetailView: View {
    let restaurant: Restaurant
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    @State private var showingWaitTimeSheet = false
    @State private var showingListSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Image
                AsyncImage(url: URL(string: restaurant.imageURL ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                }
                .frame(height: 250)
                .clipped()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Restaurant Info
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(restaurant.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button(action: {
                                Task {
                                    await restaurantManager.toggleFavorite(restaurant)
                                }
                            }) {
                                Image(systemName: restaurantManager.isFavorite(restaurant) ? "heart.fill" : "heart")
                                    .font(.title2)
                                    .foregroundColor(restaurantManager.isFavorite(restaurant) ? .red : .gray)
                            }
                        }
                        
                        Text(restaurant.cuisineType)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            // Rating
                            HStack(spacing: 4) {
                                ForEach(0..<5) { index in
                                    Image(systemName: index < Int(restaurant.rating) ? "star.fill" : "star")
                                        .foregroundColor(.orange)
                                }
                                Text(String(format: "%.1f", restaurant.rating))
                                    .fontWeight(.medium)
                                Text("(\(restaurant.reviewCount) reviews)")
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Price Range
                            Text(restaurant.priceRange.rawValue)
                                .font(.title3)
                                .fontWeight(.semibold)
                        }
                    }
                    
                    Divider()
                    
                    // Current Wait Time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Current Wait Time")
                            .font(.headline)
                        
                        if let waitTime = restaurant.currentWaitTime {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .foregroundColor(waitTime > 30 ? .red : .green)
                                Text("\(waitTime) minutes")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(waitTime > 30 ? .red : .green)
                                Spacer()
                            }
                        } else {
                            Text("No current wait time data")
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Report Wait Time") {
                            showingWaitTimeSheet = true
                        }
                        .buttonStyle(.bordered)
                        .foregroundColor(.orange)
                    }
                    
                    Divider()
                    
                    // Location and Contact
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Location & Contact")
                            .font(.headline)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: "location")
                                    .foregroundColor(.orange)
                                Text(restaurant.address)
                            }
                            
                            if let distance = locationManager.distance(to: restaurant) {
                                HStack {
                                    Image(systemName: "ruler")
                                        .foregroundColor(.orange)
                                    Text(String(format: "%.1f miles away", distance))
                                }
                            }
                            
                            if let phone = restaurant.phone {
                                HStack {
                                    Image(systemName: "phone")
                                        .foregroundColor(.orange)
                                    Text(phone)
                                }
                            }
                            
                            if let website = restaurant.website {
                                HStack {
                                    Image(systemName: "globe")
                                        .foregroundColor(.orange)
                                    Link("Visit Website", destination: URL(string: website)!)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                    
                    // Mini Map
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: restaurant.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                    )), annotationItems: [restaurant]) { restaurant in
                        MapPin(coordinate: restaurant.coordinate, tint: .orange)
                    }
                    .frame(height: 150)
                    .cornerRadius(10)
                    
                    Divider()
                    
                    // Hours
                    if !restaurant.openingHours.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Hours")
                                .font(.headline)
                            
                            ForEach(restaurant.openingHours, id: \.self) { hours in
                                Text(hours)
                                    .font(.body)
                            }
                        }
                        
                        Divider()
                    }
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button("Add to List") {
                            showingListSheet = true
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        
                        if let menuURL = restaurant.menuURL {
                            Link(destination: URL(string: menuURL)!) {
                                Text("View Menu")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingWaitTimeSheet) {
            WaitTimeSubmissionView(restaurant: restaurant)
        }
        .sheet(isPresented: $showingListSheet) {
            AddToListView(restaurant: restaurant)
        }
    }
}

struct WaitTimeSubmissionView: View {
    let restaurant: Restaurant
    @EnvironmentObject var restaurantManager: RestaurantManager
    @Environment(\.dismiss) private var dismiss
    @State private var waitMinutes = 15
    @State private var partySize = 2
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Report Wait Time")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Help other diners by sharing the current wait time at \(restaurant.name)")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    VStack {
                        Text("Wait Time")
                            .font(.headline)
                        
                        Picker("Wait Time", selection: $waitMinutes) {
                            ForEach([0, 5, 10, 15, 20, 25, 30, 45, 60, 90], id: \.self) { minutes in
                                Text("\(minutes) min").tag(minutes)
                            }
                        }
                        .pickerStyle(WheelPickerStyle())
                        .frame(height: 150)
                    }
                    
                    VStack {
                        Text("Party Size")
                            .font(.headline)
                        
                        Picker("Party Size", selection: $partySize) {
                            ForEach(1...8, id: \.self) { size in
                                Text("\(size)").tag(size)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                }
                
                Button("Submit") {
                    Task {
                        await restaurantManager.submitWaitTime(
                            for: restaurant.id ?? "",
                            minutes: waitMinutes,
                            partySize: partySize
                        )
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AddToListView: View {
    let restaurant: Restaurant
    @EnvironmentObject var restaurantManager: RestaurantManager
    @Environment(\.dismiss) private var dismiss
    @State private var newListName = ""
    @State private var showingNewListForm = false
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Add to List")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                List(restaurantManager.userLists) { list in
                    Button(action: {
                        Task {
                            await restaurantManager.addRestaurantToList(restaurant, listID: list.id ?? "")
                            dismiss()
                        }
                    }) {
                        HStack {
                            Text(list.name)
                                .foregroundColor(.primary)
                            Spacer()
                            Image(systemName: "plus.circle")
                                .foregroundColor(.orange)
                        }
                    }
                }
                
                Button("Create New List") {
                    showingNewListForm = true
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingNewListForm) {
                NewListView(restaurant: restaurant, dismiss: dismiss)
            }
        }
    }
}

struct NewListView: View {
    let restaurant: Restaurant
    let dismiss: DismissAction
    @EnvironmentObject var restaurantManager: RestaurantManager
    @State private var listName = ""
    @State private var isPublic = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Create New List")
                    .font(.title2)
                    .fontWeight(.bold)
                
                TextField("List Name", text: $listName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Toggle("Make Public", isOn: $isPublic)
                
                Button("Create & Add Restaurant") {
                    Task {
                        await restaurantManager.createList(name: listName, isPublic: isPublic)
                        if let newList = restaurantManager.userLists.last {
                            await restaurantManager.addRestaurantToList(restaurant, listID: newList.id ?? "")
                        }
                        dismiss()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(listName.isEmpty ? Color.gray : Color.orange)
                .foregroundColor(.white)
                .cornerRadius(10)
                .disabled(listName.isEmpty)
                
                Spacer()
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RestaurantDetailView(restaurant: Restaurant(
        id: "1",
        name: "Sample Restaurant",
        address: "123 Main St",
        latitude: 37.7749,
        longitude: -122.4194,
        cuisineType: "Italian",
        priceRange: .moderate,
        rating: 4.5,
        reviewCount: 150,
        isOpen: true,
        openingHours: ["Mon-Fri: 11:00-22:00", "Sat-Sun: 10:00-23:00"],
        waitTimes: []
    ))
    .environmentObject(RestaurantManager())
    .environmentObject(LocationManager())
}
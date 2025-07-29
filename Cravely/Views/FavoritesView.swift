import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @State private var selectedSegment = 0
    @State private var showingNewListSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Segmented Control
                Picker("View", selection: $selectedSegment) {
                    Text("Favorites").tag(0)
                    Text("Lists").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // Content
                if selectedSegment == 0 {
                    FavoritesListView()
                } else {
                    UserListsView()
                }
            }
            .navigationTitle("Favorites")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                Task {
                    await restaurantManager.loadFavorites()
                    await restaurantManager.loadUserLists()
                }
            }
        }
    }
}

struct FavoritesListView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @EnvironmentObject var locationManager: LocationManager
    
    var body: some View {
        if restaurantManager.favoriteRestaurants.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "heart")
                    .font(.system(size: 60))
                    .foregroundColor(.gray)
                
                Text("No Favorites Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Tap the heart icon on restaurants you love to save them here.")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List(restaurantManager.favoriteRestaurants) { restaurant in
                NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                    RestaurantRowView(restaurant: restaurant)
                }
            }
            .refreshable {
                await restaurantManager.loadFavorites()
            }
        }
    }
}

struct UserListsView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @State private var showingNewListSheet = false
    
    var body: some View {
        VStack {
            if restaurantManager.userLists.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("No Lists Yet")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Create custom lists to organize your favorite restaurants.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                    
                    Button("Create Your First List") {
                        showingNewListSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                    .foregroundColor(.white)
                    .tint(.orange)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(restaurantManager.userLists) { list in
                        NavigationLink(destination: ListDetailView(list: list)) {
                            ListRowView(list: list)
                        }
                    }
                    .onDelete(perform: deleteList)
                }
                .refreshable {
                    await restaurantManager.loadUserLists()
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingNewListSheet = true
                }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showingNewListSheet) {
            CreateListView()
        }
    }
    
    private func deleteList(at offsets: IndexSet) {
        // TODO: Implement list deletion
        // restaurantManager.userLists.remove(atOffsets: offsets)
    }
}

struct ListRowView: View {
    let list: RestaurantList
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(list.name)
                    .font(.headline)
                
                Text("\(list.restaurantIDs.count) restaurants")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("Created \(list.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if list.isPublic {
                Image(systemName: "globe")
                    .foregroundColor(.blue)
                    .font(.caption)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding(.vertical, 4)
    }
}

struct CreateListView: View {
    @EnvironmentObject var restaurantManager: RestaurantManager
    @Environment(\.dismiss) private var dismiss
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
                
                Toggle("Make list public", isOn: $isPublic)
                
                Text("Public lists can be discovered and followed by other users.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
                
                Button("Create List") {
                    Task {
                        await restaurantManager.createList(name: listName, isPublic: isPublic)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ListDetailView: View {
    let list: RestaurantList
    @EnvironmentObject var restaurantManager: RestaurantManager
    @State private var restaurants: [Restaurant] = []
    @State private var isLoading = true
    
    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Loading restaurants...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if restaurants.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    
                    Text("Empty List")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Add restaurants to this list from the restaurant detail pages.")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 40)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(restaurants) { restaurant in
                    NavigationLink(destination: RestaurantDetailView(restaurant: restaurant)) {
                        RestaurantRowView(restaurant: restaurant)
                    }
                }
            }
        }
        .navigationTitle(list.name)
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadRestaurants()
        }
    }
    
    private func loadRestaurants() {
        Task {
            var loadedRestaurants: [Restaurant] = []
            
            for restaurantID in list.restaurantIDs {
                if let restaurant = await restaurantManager.getRestaurant(by: restaurantID) {
                    loadedRestaurants.append(restaurant)
                }
            }
            
            restaurants = loadedRestaurants
            isLoading = false
        }
    }
}

#Preview {
    FavoritesView()
        .environmentObject(RestaurantManager())
        .environmentObject(LocationManager())
}
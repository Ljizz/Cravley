import SwiftUI

struct FilterView: View {
    @Binding var selectedFilters: [RestaurantFilter]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedCuisines: Set<String> = []
    @State private var selectedPriceRanges: Set<PriceRange> = []
    @State private var minimumRating: Double = 0
    @State private var maxDistance: Double = 25
    @State private var openNow: Bool = false
    @State private var maxWaitTime: Double = 60
    @State private var shortWaitOnly: Bool = false
    
    let cuisineTypes = ["Italian", "Mexican", "Chinese", "Japanese", "Thai", "Indian", "American", "French", "Mediterranean", "Korean", "Vietnamese", "Greek", "Pizza", "Burgers", "Seafood", "Steakhouse", "Sushi", "BBQ"]
    
    var body: some View {
        NavigationView {
            List {
                Section("Cuisine Type") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                        ForEach(cuisineTypes, id: \.self) { cuisine in
                            FilterChip(
                                title: cuisine,
                                isSelected: selectedCuisines.contains(cuisine)
                            ) {
                                if selectedCuisines.contains(cuisine) {
                                    selectedCuisines.remove(cuisine)
                                } else {
                                    selectedCuisines.insert(cuisine)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Price Range") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 12) {
                        ForEach(PriceRange.allCases, id: \.self) { priceRange in
                            FilterChip(
                                title: priceRange.rawValue,
                                isSelected: selectedPriceRanges.contains(priceRange)
                            ) {
                                if selectedPriceRanges.contains(priceRange) {
                                    selectedPriceRanges.remove(priceRange)
                                } else {
                                    selectedPriceRanges.insert(priceRange)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Rating") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Minimum Rating:")
                            Spacer()
                            Text(minimumRating > 0 ? String(format: "%.1f", minimumRating) : "Any")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("0")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $minimumRating, in: 0...5, step: 0.5) {
                                Text("Rating")
                            }
                            .accentColor(.orange)
                            
                            Text("5")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        HStack(spacing: 4) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < Int(minimumRating) ? "star.fill" : "star")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            if minimumRating > 0 {
                                Text("& up")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Distance") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Maximum Distance:")
                            Spacer()
                            Text(String(format: "%.0f miles", maxDistance))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("1")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Slider(value: $maxDistance, in: 1...50, step: 1) {
                                Text("Distance")
                            }
                            .accentColor(.orange)
                            
                            Text("50")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Availability") {
                    Toggle("Open Now", isOn: $openNow)
                    
                    Toggle("Short Wait Only", isOn: $shortWaitOnly)
                    
                    if shortWaitOnly {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Maximum Wait Time:")
                                Spacer()
                                Text("\(Int(maxWaitTime)) minutes")
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack {
                                Text("0")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Slider(value: $maxWaitTime, in: 0...120, step: 5) {
                                    Text("Wait Time")
                                }
                                .accentColor(.orange)
                                
                                Text("120")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        clearAllFilters()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Apply") {
                        applyFilters()
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadCurrentFilters()
        }
    }
    
    private func loadCurrentFilters() {
        // Parse existing filters to populate UI state
        for filter in selectedFilters {
            switch filter {
            case .cuisine(let cuisine):
                selectedCuisines.insert(cuisine)
            case .priceRange(let priceRange):
                selectedPriceRanges.insert(priceRange)
            case .rating(let rating):
                minimumRating = rating
            case .distance(let distance):
                maxDistance = distance
            case .openNow:
                openNow = true
            case .shortWait(let waitTime):
                shortWaitOnly = true
                maxWaitTime = Double(waitTime)
            }
        }
    }
    
    private func applyFilters() {
        var filters: [RestaurantFilter] = []
        
        // Add cuisine filters
        for cuisine in selectedCuisines {
            filters.append(.cuisine(cuisine))
        }
        
        // Add price range filters
        for priceRange in selectedPriceRanges {
            filters.append(.priceRange(priceRange))
        }
        
        // Add rating filter
        if minimumRating > 0 {
            filters.append(.rating(minimumRating))
        }
        
        // Add distance filter
        filters.append(.distance(maxDistance))
        
        // Add availability filters
        if openNow {
            filters.append(.openNow)
        }
        
        if shortWaitOnly {
            filters.append(.shortWait(Int(maxWaitTime)))
        }
        
        selectedFilters = filters
    }
    
    private func clearAllFilters() {
        selectedCuisines.removeAll()
        selectedPriceRanges.removeAll()
        minimumRating = 0
        maxDistance = 25
        openNow = false
        shortWaitOnly = false
        maxWaitTime = 60
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.orange : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FilterView(selectedFilters: .constant([]))
}
import SwiftUI
import CoreLocation

/// 停车场列表视图
struct ParkingLotsListView: View {
    @EnvironmentObject var parkingLotViewModel: ParkingLotViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @ObservedObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLot: ParkingLot?
    @State private var showingDetail = false
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // 0. 离线模式提示
                    if parkingLotViewModel.isOfflineMode {
                        offlineBanner
                    }
                    
                    // 1. 当前位置
                    if locationManager.currentLocation != nil {
                        currentLocationBar
                    }
                    
                    // 2. 搜索框和地址候选列表
                    searchSection
                    
                    // 4. 当前位置最近停车场卡片
                    if let currentLocation = locationManager.currentLocation,
                       let nearestLot = nearestParkingLot {
                        nearestSection(nearestLot: nearestLot, currentLocation: currentLocation)
                    }
                    
                    // 5. 附近停车场卡片列表
                    nearbySection
                }
                .padding(.bottom)
            }
            .navigationTitle(NSLocalizedString("parking_list_title"))
            .onAppear {
                parkingLotViewModel.loadLots()
                locationManager.request()
                // 检查离线状态
                if !NetworkMonitor.shared.isConnected {
                    parkingLotViewModel.isOfflineMode = true
                    parkingLotViewModel.lastCacheTime = CoreDataService.shared.getCacheTimestamp()
                }
            }
            .onChange(of: locationManager.currentLocation) { newLocation in
                parkingLotViewModel.updateCurrentLocation(newLocation)
            }
            .onChange(of: networkMonitor.isConnected) { isConnected in
                if !isConnected {
                    parkingLotViewModel.isOfflineMode = true
                    parkingLotViewModel.lastCacheTime = CoreDataService.shared.getCacheTimestamp()
                } else {
                    parkingLotViewModel.isOfflineMode = false
                    // 网络恢复时重新加载数据
                    parkingLotViewModel.loadLots()
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let lot = selectedLot {
                    // 这里不要再传 .environmentObject(authViewModel)
                    ParkingLotDetailView(lot: lot, currentLocation: locationManager.currentLocation)
                }
            }
        }
    }
    
    // MARK: - 子视图拆分，减轻类型推断
    
    private var offlineBanner: some View {
        HStack {
            Image(systemName: "wifi.slash")
                .foregroundColor(.orange)
            VStack(alignment: .leading, spacing: 4) {
                Text(NSLocalizedString("offline_mode"))
                    .font(.headline)
                if let cacheTime = parkingLotViewModel.lastCacheTime {
                    Text(NSLocalizedString("last_updated") + ": \(formatCacheTime(cacheTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var currentLocationBar: some View {
        HStack {
            Image(systemName: "location.fill")
                .foregroundColor(.blue)
            Text(NSLocalizedString("current_location"))
                .font(.headline)
            Spacer()
            if let address = locationManager.currentAddress {
                Text(address)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            } else {
                Text(NSLocalizedString("loading"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding(.horizontal)
        .padding(.top)
    }
    
    private var searchSection: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField(NSLocalizedString("search_placeholder"), text: $parkingLotViewModel.searchText)
                    .onChange(of: parkingLotViewModel.searchText) { _ in
                        parkingLotViewModel.onSearchTextChanged()
                    }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
            
            // 地址候选下拉列表
            if !parkingLotViewModel.addressSuggestions.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(parkingLotViewModel.addressSuggestions) { suggestion in
                        Button(action: {
                            parkingLotViewModel.selectAddressSuggestion(suggestion)
                        }) {
                            HStack {
                                Image(systemName: "mappin.circle.fill")
                                    .foregroundColor(.blue)
                                Text(suggestion.address)
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 12)
                        }
                        
                        if suggestion.id != parkingLotViewModel.addressSuggestions.last?.id {
                            Divider()
                                .padding(.leading, 40)
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(10)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal)
    }
    
    private func nearestSection(nearestLot: ParkingLot, currentLocation: CLLocation) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(NSLocalizedString("nearest_parking"))
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            NearestParkingCard(
                lot: nearestLot,
                currentLocation: currentLocation
            ) {
                selectedLot = nearestLot
                showingDetail = true
            }
        }
        .padding(.horizontal)
    }
    
    private var nearbySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题和筛选排序区域
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(NSLocalizedString("nearby_parking"))
                        .font(.headline)
                        .fontWeight(.semibold)
                    Spacer()
                }
                
                // 筛选和排序视图
                FilterAndSortView(currentLocation: locationManager.currentLocation)
                    .environmentObject(parkingLotViewModel)
                    .environmentObject(authViewModel)
                    .onAppear {
                        // 更新收藏列表
                        parkingLotViewModel.favoriteParkingLotIds = authViewModel.getFavorites()
                    }
                    .onChange(of: authViewModel.currentUser?.favoriteParkingLotIds) { _ in
                        // 当收藏列表变化时更新
                        parkingLotViewModel.favoriteParkingLotIds = authViewModel.getFavorites()
                        parkingLotViewModel.applyFiltersAndSort(currentLocation: locationManager.currentLocation)
                    }
            }
            .padding(.horizontal)
            
            if parkingLotViewModel.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding()
            } else if nearbyParkingLots.isEmpty {
                VStack {
                    Image(systemName: "parkinglot")
                        .font(.system(size: 60))
                        .foregroundColor(.gray)
                    Text(NSLocalizedString("no_results"))
                        .foregroundColor(.gray)
                        .padding(.top)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                // 提前捕获当前定位，减少闭包类型推断复杂度
                let currentLocation = locationManager.currentLocation
                ForEach(nearbyParkingLots) { lot in
                    ParkingLotRow(
                        lot: lot,
                        currentLocation: currentLocation
                    ) {
                        selectedLot = lot
                        showingDetail = true
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding(.top, 8)
    }
    
    // MARK: - 计算属性（加显式类型）
    
    // 计算最近的停车场
    private var nearestParkingLot: ParkingLot? {
        guard let currentLocation = locationManager.currentLocation,
              !parkingLotViewModel.filtered.isEmpty else {
            return nil
        }
        
        let result: ParkingLot? = parkingLotViewModel.filtered.min { lot1, lot2 in
            let distance1 = currentLocation.distance(from: lot1.location)
            let distance2 = currentLocation.distance(from: lot2.location)
            return distance1 < distance2
        }
        return result
    }
    
    // 获取附近停车场列表（排除最近的）
    private var nearbyParkingLots: [ParkingLot] {
        guard let nearest = nearestParkingLot else {
            return parkingLotViewModel.filtered
        }
        let list: [ParkingLot] = parkingLotViewModel.filtered.filter { $0.id != nearest.id }
        return list
    }
    
    // 格式化缓存时间
    private func formatCacheTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}

// 最近停车场卡片
struct NearestParkingCard: View {
    let lot: ParkingLot
    let currentLocation: CLLocation
    let onTap: () -> Void
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Text(lot.name)
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 收藏按钮
                            Button(action: {
                                if authViewModel.isAuthenticated {
                                    authViewModel.toggleFavorite(parkingLotId: lot.id)
                                }
                            }) {
                                Image(systemName: authViewModel.isFavorite(parkingLotId: lot.id) ? "heart.fill" : "heart")
                                    .font(.subheadline)
                                    .foregroundColor(authViewModel.isFavorite(parkingLotId: lot.id) ? .red : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.red)
                                .font(.caption)
                            Text(lot.address)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .lineLimit(2)
                        }
                        
                        if let distance = distanceText {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.blue)
                                    .font(.caption)
                                Text(distance)
                                    .font(.subheadline)
                                    .foregroundColor(.blue)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 8) {
                        Text(lot.availabilityText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(availabilityColor)
                        
                        Text(NSLocalizedString("availability"))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                HStack(spacing: 16) {
                    // 设施图标
                    if lot.facilities?.evChargers?.count ?? 0 > 0 {
                        Label("EV", systemImage: "bolt.car.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if lot.facilities?.covered == true {
                        Label(NSLocalizedString("covered_filter"), systemImage: "house.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if lot.facilities?.cctv == true {
                        Label("CCTV", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let priceRules = lot.priceRules, priceRules != "暂未提供" {
                        Text(priceRules)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.blue.opacity(0.05)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var availabilityColor: Color {
        if let hasAvailable = lot.hasAvailableSpaces {
            return hasAvailable ? .green : .red
        }
        return .gray
    }
    
    private var distanceText: String? {
        let distance = currentLocation.distance(from: lot.location)
        if distance < 1000 {
            return String(format: "%.0f%@", distance, NSLocalizedString("meters"))
        } else {
            return String(format: "%.1f%@", distance / 1000, NSLocalizedString("kilometers"))
        }
    }
}

// ParkingLotsListView.swift 中的 ParkingLotRow 結構
struct ParkingLotRow: View {
    let lot: ParkingLot
    let currentLocation: CLLocation?
    let onTap: () -> Void
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    @State private var showingFavoriteAlert = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(lot.name)
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            // 收藏按钮
                            Button(action: {
                                if authViewModel.isAuthenticated {
                                    authViewModel.toggleFavorite(parkingLotId: lot.id)
                                }
                            }) {
                                Image(systemName: authViewModel.isFavorite(parkingLotId: lot.id) ? "heart.fill" : "heart")
                                    .font(.subheadline)
                                    .foregroundColor(authViewModel.isFavorite(parkingLotId: lot.id) ? .red : .gray)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        Text(lot.address)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(lot.availabilityText)
                            .font(.headline)
                            .foregroundColor(availabilityColor)
                        
                        if let distance = distanceText {
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                HStack(spacing: 12) {
                    // 设施图标
                    if lot.facilities?.evChargers?.count ?? 0 > 0 {
                        Label("EV", systemImage: "bolt.car.fill")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    
                    if lot.facilities?.covered == true {
                        Label(NSLocalizedString("covered_filter"), systemImage: "house.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if lot.facilities?.cctv == true {
                        Label("CCTV", systemImage: "camera.fill")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if let priceRules = lot.priceRules, priceRules != "暂未提供" {
                        Text(priceRules)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            // 右鍵/長按菜單
            Button {
                toggleFavorite()
            } label: {
                Label(
                    authViewModel.isFavorite(parkingLotId: lot.id) ?
                    "Remove from Favorites" : "Add to Favorites",
                    systemImage: authViewModel.isFavorite(parkingLotId: lot.id) ?
                    "heart.slash" : "heart"
                )
            }
            
            Button {
                shareParkingLot()
            } label: {
                Label("Share", systemImage: "square.and.arrow.up")
            }
        }
        .onLongPressGesture {
            showingFavoriteAlert = true
        }
        .alert("Favorite", isPresented: $showingFavoriteAlert) {
            Button("Cancel", role: .cancel) { }
            Button(authViewModel.isFavorite(parkingLotId: lot.id) ?
                   "Remove from Favorites" : "Add to Favorites") {
                toggleFavorite()
            }
        } message: {
            Text(authViewModel.isFavorite(parkingLotId: lot.id) ?
                 "Remove \(lot.name) from favorites?" :
                    "Add \(lot.name) to favorites?")
        }
    }
    
    private var availabilityColor: Color {
        if let hasAvailable = lot.hasAvailableSpaces {
            return hasAvailable ? .green : .red
        }
        return .gray
    }
    
    private var distanceText: String? {
        guard let location = currentLocation else { return nil }
        let distance = location.distance(from: lot.location)
        if distance < 1000 {
            return String(format: "%.0f%@", distance, NSLocalizedString("meters"))
        } else {
            return String(format: "%.1f%@", distance / 1000, NSLocalizedString("kilometers"))
        }
    }
    
    private func toggleFavorite() {
        guard authViewModel.isAuthenticated else {
            showingFavoriteAlert = true
            return
        }
        guard authViewModel.currentUser != nil else {
            print("⚠️ 用户对象不存在，无法切换收藏")
            return
        }
        authViewModel.toggleFavorite(parkingLotId: lot.id)
    }
    
    private func shareParkingLot() {
        let shareText = "Check out \(lot.name) at \(lot.address)"
        let activityVC = UIActivityViewController(
            activityItems: [shareText],
            applicationActivities: nil
        )
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}

/// 筛选和排序视图
struct FilterAndSortView: View {
    @EnvironmentObject var viewModel: ParkingLotViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    let currentLocation: CLLocation?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // 筛选选项 - 只显示 EV充电 和 我的收藏
            HStack(spacing: 12) {
                FilterToggle(
                    title: NSLocalizedString("ev_charging_filter"),
                    icon: "bolt.car.fill",
                    isOn: Binding(
                        get: { viewModel.filters.hasEV },
                        set: { newValue in
                            viewModel.filters.hasEV = newValue
                            viewModel.applyFiltersAndSort(currentLocation: currentLocation)
                        }
                    )
                )
                
                if authViewModel.isAuthenticated {
                    FilterToggle(
                        title: NSLocalizedString("my_favorites"),
                        icon: "heart.fill",
                        isOn: Binding(
                            get: { viewModel.filters.onlyFavorites },
                            set: { newValue in
                                // 更新收藏列表
                                viewModel.favoriteParkingLotIds = authViewModel.getFavorites()
                                viewModel.filters.onlyFavorites = newValue
                                viewModel.applyFiltersAndSort(currentLocation: currentLocation)
                            }
                        )
                    )
                }
            }
            
            // 排序选项
            HStack(spacing: 8) {
                Text(NSLocalizedString("sort_by") + ":")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Menu {
                    Button(action: {
                        viewModel.sortBy = .distance
                        viewModel.applyFiltersAndSort(currentLocation: currentLocation)
                    }) {
                        HStack {
                            Text(NSLocalizedString("sort_distance"))
                            if viewModel.sortBy == .distance {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.sortBy = .vacancies
                        viewModel.applyFiltersAndSort(currentLocation: currentLocation)
                    }) {
                        HStack {
                            Text(NSLocalizedString("sort_vacancies"))
                            if viewModel.sortBy == .vacancies {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    
                    Button(action: {
                        viewModel.sortBy = .priceHint
                        viewModel.applyFiltersAndSort(currentLocation: currentLocation)
                    }) {
                        HStack {
                            Text(NSLocalizedString("sort_price"))
                            if viewModel.sortBy == .priceHint {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(sortByText)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
    
    private var sortByText: String {
        switch viewModel.sortBy {
        case .distance: return NSLocalizedString("sort_distance")
        case .vacancies: return NSLocalizedString("sort_vacancies")
        case .priceHint: return NSLocalizedString("sort_price")
        }
    }
}

/// 筛选开关组件
struct FilterToggle: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool
    
    var body: some View {
        Button(action: {
            isOn.toggle()
        }) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(isOn ? .white : .blue)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(isOn ? .white : .primary)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isOn ? Color.blue : Color(.systemGray5))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

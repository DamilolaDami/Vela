
import Foundation
import Combine
import SwiftUI

@MainActor
class BrowserViewModel: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var currentSpace: Space?
    @Published var currentTab: Tab?
    @Published var tabs: [Tab] = []
    @Published var isLoading = false
    @Published var sidebarCollapsed = false
    
    private let createTabUseCase: CreateTabUseCaseProtocol
    private let tabRepository: TabRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(
        createTabUseCase: CreateTabUseCaseProtocol,
        tabRepository: TabRepositoryProtocol
    ) {
        self.createTabUseCase = createTabUseCase
        self.tabRepository = tabRepository
        setupInitialState()
    }
    
    private func setupInitialState() {
        // Create default space
        let defaultSpace = Space(name: "Personal", color: .blue)
        spaces = [defaultSpace]
        currentSpace = defaultSpace
        
        // Load tabs
        loadTabs()
    }
    
    func createNewTab(with url: URL? = nil) {
        createTabUseCase.execute(url: url, in: currentSpace?.id)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to create tab: \(error)")
                    }
                },
                receiveValue: { [weak self] tab in
                    self?.tabs.append(tab)
                    self?.currentTab = tab
                }
            )
            .store(in: &cancellables)
    }
    
    func selectTab(_ tab: Tab) {
        currentTab = tab
    }
    
    func closeTab(_ tab: Tab) {
        tabs.removeAll { $0.id == tab.id }
        if currentTab?.id == tab.id {
            currentTab = tabs.first
        }
    }
    
    func toggleSidebar() {
        withAnimation(.easeInOut(duration: 0.3)) {
            sidebarCollapsed.toggle()
        }
    }
    
    private func loadTabs() {
        guard let spaceId = currentSpace?.id else { return }
        
        tabRepository.getBySpace(spaceId: spaceId)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] tabs in
                    self?.tabs = tabs
                    self?.currentTab = tabs.first
                }
            )
            .store(in: &cancellables)
    }
}

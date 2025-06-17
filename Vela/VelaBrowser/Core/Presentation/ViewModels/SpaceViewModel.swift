import Foundation
import Combine
import SwiftUI

@MainActor
class SpaceViewModel: ObservableObject {
    @Published var spaces: [Space] = []
    @Published var currentSpace: Space?
    @Published var isShowingCreateSpaceSheet: Bool = false
    @Published var isShowingSpaceInfoPopover = false
    @Published var spaceForInfoPopover: Space? = nil
    
    private let spaceRepository: SpaceRepositoryProtocol
    private var cancellables = Set<AnyCancellable>()
    
    private enum UserDefaultsKeys {
        static let lastSelectedSpaceId = "lastSelectedSpaceId"
    }
    
    var spaceColor: Color {
        currentSpace?.color.color ?? Color(NSColor.tertiarySystemFill)
    }
    
    // MARK: - Initialization
    
    init(spaceRepository: SpaceRepositoryProtocol) {
        self.spaceRepository = spaceRepository
        setupInitialState()
        setupBindings()
    }
    
    private func setupInitialState() {
        loadSpaces()
    }
    
    private func setupBindings() {
        $currentSpace
            .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
            .sink { [weak self] space in
                guard let self = self else { return }
                if let spaceId = space?.id {
                    UserDefaults.standard.set(spaceId.uuidString, forKey: UserDefaultsKeys.lastSelectedSpaceId)
                } else {
                    UserDefaults.standard.removeObject(forKey: UserDefaultsKeys.lastSelectedSpaceId)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Space Management
    
    func loadSpaces() {
        spaceRepository.getAllSpaces()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to load spaces: \(error)")
                    }
                },
                receiveValue: { [weak self] spaces in
                    guard let self = self else { return }
                    self.spaces = spaces.isEmpty ? [Space(name: "Personal", color: .blue, isDefault: true)] : spaces
                    
                    // Retrieve the last selected space ID from UserDefaults
                    if let lastSpaceIdString = UserDefaults.standard.string(forKey: UserDefaultsKeys.lastSelectedSpaceId),
                       let lastSpaceId = UUID(uuidString: lastSpaceIdString),
                       let savedSpace = spaces.first(where: { $0.id == lastSpaceId }) {
                        self.currentSpace = savedSpace
                    } else {
                        self.currentSpace = self.spaces.first
                    }
                }
            )
            .store(in: &cancellables)
    }
    
    func createSpace(_ space: Space) {
        spaceRepository.createSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to create space: \(error)")
                    } else {
                        self?.loadSpaces()
                    }
                },
                receiveValue: { [weak self] newSpace in
                    self?.spaces.append(newSpace)
                    self?.currentSpace = newSpace
                }
            )
            .store(in: &cancellables)
    }
    
    func updateSpace(_ space: Space) {
        spaceRepository.updateSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        print("Failed to update space: \(error)")
                    }
                },
                receiveValue: { [weak self] in
                    self?.loadSpaces()
                }
            )
            .store(in: &cancellables)
    }
    
    func deleteSpace(_ space: Space) {
        spaceRepository.deleteSpace(space)
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        print("Failed to delete space: \(error)")
                    } else {
                        self?.loadSpaces()
                        if self?.currentSpace?.id == space.id {
                            self?.currentSpace = self?.spaces.first
                        }
                    }
                },
                receiveValue: { }
            )
            .store(in: &cancellables)
    }
    
    func selectSpace(_ space: Space) {
        currentSpace = space
    }
    
    // MARK: - UI Actions
    
    func showCreateSpaceSheet() {
        isShowingCreateSpaceSheet = true
    }
    
    func hideCreateSpaceSheet() {
        isShowingCreateSpaceSheet = false
    }
    
    func showSpaceInfoPopover(for space: Space) {
        spaceForInfoPopover = space
        isShowingSpaceInfoPopover = true
    }
    
    func hideSpaceInfoPopover() {
        isShowingSpaceInfoPopover = false
        spaceForInfoPopover = nil
    }
}

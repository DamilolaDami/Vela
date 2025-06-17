import SwiftUI
import SwiftData

@Observable
class OnboardingViewModel {
    // MARK: - Properties
    var currentStep: Int = 0
    var showCreateSpace: Bool = false
    var animateContent: Bool = false
    var spaceName: String = ""
    var selectedColor: Space.SpaceColor = .blue
    
    var hasSeenOnboarding: OnboardingState {
        didSet {
            saveOnboardingState()
            print("Onboarding state updated to: \(hasSeenOnboarding)")
        }
    }
    
    private let userDefaultsKey = "hasSeenOnboardingV4"
    
    let steps: [OnboardingStep] = [
        OnboardingStep(
            icon: "safari.fill",
            title: "Meet Vela",
            subtitle: "The browser designed for power users",
            description: "Vela reimagines web browsing with powerful organization tools, intelligent commands, and a clean interface designed for macOS. Let's get you set up in just a few steps.",
            buttonText: "Get Started",
            contentType: .introduction,
            imageName: "overall-walkthrough"
        ),
        OnboardingStep(
            icon: "safari.fill",
            title: "Unlock the\nfull potential",
            subtitle: "Grant permissions for a seamless experience",
            description: "Enable Vela to access key features for a tailored browsing experience, optimized for macOS.",
            buttonText: "Continue",
            contentType: .permissions
        ),
        OnboardingStep(
            icon: "rectangle.3.group.fill",
            title: "Organize with\nTabs & Spaces",
            subtitle: "Keep your workflow organized",
            description: "Group related tabs into Spaces, switch between projects instantly, and maintain perfect organization across all your browsing contexts.",
            buttonText: "Continue",
            contentType: .feature
        ),
        OnboardingStep(
            icon: "command.circle.fill",
            title: "Global Command\nPalette",
            subtitle: "Navigate at the speed of thought",
            description: "Access any tab, bookmark, or action with intelligent search. Context-aware suggestions adapt to your workflow and boost productivity.",
            buttonText: "Continue",
            contentType: .feature,
            imageName: "global-commands"
        ),
        OnboardingStep(
            icon: "plus.circle.fill",
            title: "Create Your\nFirst Space",
            subtitle: "Optional: Set up your workspace",
            description: "Spaces help you separate work, personal browsing, and projects. You can always create one later.",
            buttonText: "Create Space",
            isOptional: true,
            contentType: .createSpace
        ),
        OnboardingStep(
            icon: "checkmark.circle.fill",
            title: "You're All Set!",
            subtitle: "Start browsing with Vela",
            description: "Vela is ready to transform your browsing experience. Press ⌘K anytime to open the command palette.",
            buttonText: "Start Browsing",
            contentType: .completion
        )
    ]
    
    // MARK: - Initialization
    init() {
        // Load persisted state
        if let savedState = UserDefaults.standard.string(forKey: userDefaultsKey),
           let state = OnboardingState(rawValue: savedState) {
            self.hasSeenOnboarding = state
            print("Loaded onboarding state: \(state)")
        } else {
            self.hasSeenOnboarding = .notStarted
            print("No saved onboarding state found, defaulting to: \(hasSeenOnboarding)")
        }
    }
    
    // MARK: - Public Methods
    var totalSteps: Int {
        steps.count
    }
    
    var currentOnboardingStep: OnboardingStep {
        steps[currentStep]
    }
    
    func nextStep() {
        guard currentStep < steps.count - 1 else {
            completeOnboarding()
            return
        }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
            animateContent = false
            if hasSeenOnboarding != .completed {
                hasSeenOnboarding = .inProgress
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 0.3)) {
                self.animateContent = true
            }
        }
    }
    
    func skipStep() {
        nextStep()
    }
    
    func completeOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            hasSeenOnboarding = .completed
            currentStep = steps.count - 1 // Ensure we're on the last step
            animateContent = true
        }
    }
    
    func startOnboarding() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            currentStep = 0
            animateContent = true
            hasSeenOnboarding = .inProgress
        }
    }
    
    func resetOnboarding() {
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep = 0
            animateContent = false
            spaceName = ""
            selectedColor = .blue
            hasSeenOnboarding = .notStarted
        }
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
        print("Onboarding reset, removed state from UserDefaults")
    }
    
    // MARK: - Private Methods
    private func saveOnboardingState() {
        UserDefaults.standard.set(hasSeenOnboarding.rawValue, forKey: userDefaultsKey)
        UserDefaults.standard.synchronize() // Ensure immediate persistence
        print("Saved onboarding state: \(hasSeenOnboarding) with key: \(userDefaultsKey)")
    }
}

// MARK: - Supporting Types
enum OnboardingState: String, Codable {
    case notStarted
    case inProgress
    case completed
}


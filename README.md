# Vela (macOS)

**Vela** is a modern open source, SwiftUI-based macOS browser application built on top of **WebKit**, aiming to reimagine what focused, elegant browsing should feel like. With a strong architectural foundation and modular components, Vela is the beginning of a new kind of browser experience.

---

## 📦 Project Structure

```
Vela/
├── VelaBrowser/
│   ├── App/                # Entry point and app lifecycle management
│   ├── Core/
│   │   ├── Data/           # Data sources, models, and networking
│   │   ├── Domain/         # Business logic, use cases
│   │   └── Presentation/   # UI logic, view models, and bindings
│   └── Shared/
│       ├── Constants/      # Static values and configuration
│       ├── DI/             # Dependency injection setup
│       ├── Handlers/       # Event and input handlers
│       ├── Protocols/      # Interface abstractions
│       ├── Services/       # Platform and system service wrappers
│       ├── Storage/        # Persistence layer
│       └── Utils/          # Utility functions
├── Assets/                 # Images, icons, etc.
├── Info/                   # App configuration files
├── VelaTests/              # Unit tests
└── VelaUITests/            # UI tests and launch tests
```

---

## 🛠 Requirements

- macOS 13+
- Swift 5.9+
- Xcode 15+
- SwiftUI + Combine
- WebKit
- [Kingfisher](https://github.com/onevcat/Kingfisher) 8.3.2 (via Swift Package Manager)

---

## 🚀 Getting Started

1. Clone the repository:
```bash
git clone https://github.com/your-org/vela.git
cd vela
```

2. Open `Vela.xcodeproj` in Xcode.

3. Ensure the correct signing team is selected in the project settings.

4. Build and run the project (⌘R).

---

## 🧪 Testing

- Run **unit tests**: `⌘U` or via the Test navigator.
- Run **UI tests**: Target `VelaUITestsLaunchTests` in the UI test suite.

---

## 🤝 Contributing

We welcome contributions! To assist:

- Fork the repo and clone your copy.
- Follow the architectural patterns in `Core` and `Shared`.
- Write unit or UI tests where appropriate.
- Submit a PR with a clear description.

---

## 📜 License

MIT License © 2025 Vela Authors

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
git clone https://github.com/DamilolaDami/Vela.git
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

We’re excited to welcome contributors! Here’s how you can get started:

### 👣 Steps to Contribute

1. **Fork** this repository.
2. **Clone** your fork:
   ```bash
   https://github.com/DamilolaDami/Vela.git
   ```
3. **Create a new branch** for your feature or fix:
   ```bash
   git checkout -b feature/my-feature
   ```
4. **Write clear code** following the architecture and style.
5. **Add tests** (unit or UI) to support your changes.
6. **Commit** your changes with a meaningful message:
   ```bash
   git commit -m "Add: new navigation controller for Spaces"
   ```
7. **Push** your changes:
   ```bash
   git push origin feature/my-feature
   ```
8. **Open a Pull Request** with a description, screenshots (if UI), and linked issues.

### 🧭 Guidelines

- Follow the MVVM and modular structure.
- Keep PRs focused—small, meaningful changes are easier to review.
- Write descriptive commit messages.
- Document your code where clarity is needed.
- Be kind in code reviews—we’re building something great together.

---

## 📜 License

This project is licensed under the [MIT License](https://opensource.org/licenses/MIT).

### 🔒 Permissions

- ✅ Commercial use
- ✅ Distribution
- ✅ Modification
- ✅ Private use

### ❗ Limitations

- ❌ No liability
- ❌ No warranty

Please see the LICENSE file for full details.

---

> “Built with intention. Shaped by focus.” — The Vela Team

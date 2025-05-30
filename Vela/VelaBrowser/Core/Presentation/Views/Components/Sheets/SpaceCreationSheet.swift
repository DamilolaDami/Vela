//
//  SpaceCreationSheet.swift
//  Vela
//
//  Created by damilola on 5/30/25.
//


import SwiftUI


struct SpaceCreationSheet: View {
    @ObservedObject var viewModel: BrowserViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var spaceName = ""
    @State private var selectedColor: Space.SpaceColor = .blue
    
    var body: some View {
        NavigationView {
            Form {
                Section("Space Details") {
                    TextField("Space Name", text: $spaceName)
                    
                    Picker("Color", selection: $selectedColor) {
                        ForEach(Space.SpaceColor.allCases, id: \.self) { color in
                            HStack {
                                Circle()
                                    .fill(Color.spaceColor(color))
                                    .frame(width: 16, height: 16)
                                Text(color.rawValue.capitalized)
                            }
                            .tag(color)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            .frame(width: 400, height: 200)
            .navigationTitle("New Space")
           // .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createSpace()
                    }
                    .disabled(spaceName.isEmpty)
                }
            }
        }
    }
    
    private func createSpace() {
        let newSpace = Space(name: spaceName, color: selectedColor)
      //  viewModel.createSpace(newSpace)
        dismiss()
    }
}

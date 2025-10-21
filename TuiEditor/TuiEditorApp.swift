//
//  TuiEditorApp.swift
//  TuiEditor
//

import SwiftUI

import Tui

internal import UniformTypeIdentifiers

@main
struct TuiEditorApp: App {
    
    @Environment(\.openWindow) private var openWindow
    @State private var isImporting: Bool = false
    
    // Pull the focused window’s model from FocusedValues
    @FocusedValue(\.editorViewModel) private var focusedEditor: EditorViewModel?

    @ObservedObject var appViewModel = AppViewModel()
    
//    @State var viewModel = EditorViewModel(Bundle.main.url(forResource: "example", withExtension: "tui"))
    
    var body: some Scene {
        WindowGroup {
            EditorView(url: Bundle.main.url(forResource: "example", withExtension: "tui"))
        }
//        WindowGroup(id: "tui-editor", for: Optional<URL>.self) { url in
//            EditorView(url: url.wrappedValue)
//        } defaultValue: {
//            Bundle.main.url(forResource: "example", withExtension: "tui")
//        }
        .commands {
            CommandMenu("Font") {
                Button("Increase", systemImage: "plus") {
                    focusedEditor?.increaseFontSize()
                }
                .keyboardShortcut("+")
                
                Button("Decrease", systemImage: "minus") {
                    focusedEditor?.decreaseFontSize()
                }
                .keyboardShortcut("-")
            }
            CommandMenu("Run") {
                Button("Run", systemImage: "play.fill") {
                    appViewModel.clearLog()
                    focusedEditor?.runTui()
                }
                .keyboardShortcut("R")
            }
            CommandGroup(replacing: .newItem) {
                Button("New") {
                    openWindow(id: "tui-editor", value: nil as URL?)
                }
                .keyboardShortcut("N")
            }
            CommandGroup(after: .newItem) {
                Button("Open", systemImage: "arrow.up.forward.square") {
                    isImporting = true
                }
                .keyboardShortcut("O")
                .fileImporter(
                    isPresented: $isImporting,
                    allowedContentTypes: [.init(filenameExtension: "tui")].compactMap { $0 }
                ) { result in
                    switch result {
                    case .success(let url):
                        // Route to the focused window’s model
                        focusedEditor?.openFile(url)
                        focusedEditor?.runSyntaxHighlighting()
                    case .failure(let error):
                        debugPrint("Error opening file: \(error)")
                    }
                }
                .fileDialogDefaultDirectory(Bundle.main.bundleURL.appending(path: "Contents/Resources"))
                
                Button("Save", systemImage: "square.and.arrow.down") {
                    focusedEditor?.saveFile()
                }
                .keyboardShortcut("S")
            }
        }
        .onChange(of: appViewModel.outputText) { oldValue, newValue in
            focusedEditor?.outputText = newValue
        }
    }

}

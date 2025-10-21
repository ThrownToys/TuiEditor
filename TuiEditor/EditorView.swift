//
//  ContentView.swift
//  TuiEditor
//
//  A simple tui editor
//
/// Far from being a complete IDE, this is just a simple example of including Tui in a swift project.

import SwiftUI
public import AppKit

import Tui

private struct FocusedEditorViewModelKey: FocusedValueKey {
    typealias Value = EditorViewModel
}

extension FocusedValues {
    var editorViewModel: EditorViewModel? {
        get { self[FocusedEditorViewModelKey.self] }
        set { self[FocusedEditorViewModelKey.self] = newValue }
    }
}

struct EditorView: View {
    
    @State var viewModel: EditorViewModel
    
    init(viewModel: EditorViewModel) {
        self.viewModel = viewModel
    }
    
    init(url: URL?) {
        self.viewModel = EditorViewModel(url)
    }
    
    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text("Script:")
                        .font(.headline)
                    ScrollView([.vertical, .horizontal], showsIndicators: true) {
                        HStack(alignment: .top) {
                            Text(viewModel.lineNumbers)
                                .font(.system(size: viewModel.fontSize))
                            TextEditor(text: $viewModel.attributedScriptText, selection: $viewModel.selection)
                                .fixedSize(horizontal: false, vertical: false)
                                .frame(minWidth: 1000, maxWidth: .greatestFiniteMagnitude, minHeight: 500)
                                .font(.system(size: viewModel.fontSize))
                                .onKeyPress { key in
                                    viewModel.keyPressed(key)
                                }
                        }
                        
                    }
                }
                .frame(maxWidth: .infinity)
                VStack(alignment: .leading) {
                    HStack {
                        Text("Output:")
                            .font(.headline)
                        Spacer()
                    }
                    ScrollView {
                        VStack(alignment: .leading) {
                            Text(viewModel.outputText)
                                .font(.system(size: viewModel.fontSize))
                                .textSelection(.enabled)
                                .multilineTextAlignment(.leading)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .defaultScrollAnchor(.bottom)
                    .frame(maxWidth: .infinity)
                    .background(.background.tertiary)
                }
                .frame(maxWidth: .infinity)
            }
            Button {
                viewModel.runTui()
            } label: {
                Text("Run Tui ⌘ R")
            }
            
        }
        .padding()
        .focusedSceneValue(\.editorViewModel, viewModel)
    }
}

extension NSTextView {
    open override var frame: CGRect {
        didSet {
            self.isAutomaticQuoteSubstitutionEnabled = false
        }
    }
}

#Preview {
    EditorView(viewModel: EditorViewModel())
}

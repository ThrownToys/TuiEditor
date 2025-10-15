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
                    HStack {
                        TextEditor(text: $viewModel.attributedScriptText, selection: $viewModel.selection)
                            .font(.system(size: viewModel.fontSize))
                            .onKeyPress { key in
                                viewModel.keyPressed(key)
                            }
//                            .background(alignment: .topLeading) {
//                                VStack {
//                                    ForEach(viewModel.lineNumbers, id: \.self) { lineNumber in
//                                        Text("\(lineNumber)")
//                                    }
//                                    Spacer()
//                                }
//                            }
                    }
                    
//                    CustomTextEditorView()
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

class TextViewController: NSViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        
        let scrollView = NSScrollView()
        let textView = NSTextView()
        textView.backgroundColor = .red
        textView.textColor = .green

        scrollView.documentView = textView
//        scrollView.rulersVisible = true
        
//        scrollView.addFloatingSubview(floatingView, for: .vertical)
        self.view = scrollView
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CustomTextEditorView: NSViewControllerRepresentable {
    func makeNSViewController(context: Self.Context) -> TextViewController {
        TextViewController()
    }
    
    func updateNSViewController(_ nsViewController: TextViewController, context: Self.Context) {
        print("update")
    }
}

#Preview {
    EditorView(viewModel: EditorViewModel())
}

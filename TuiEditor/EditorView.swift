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
                    
//                    CustomTextEditorView(lineCount: $viewModel.lineCount, attributedString: $viewModel.attributedScriptText, fontSize: viewModel.fontSize)
//                        .onKeyPress { key in
//                            viewModel.keyPressed(key)
//                        }
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
    var attributedString: AttributedString
    var textView: NSTextView
    var label: NSTextField
    var scrollView: NSScrollView
    var previousFontSize: CGFloat = 12.0
    
    init(lineCount: Int, attributedString: AttributedString) {
        self.attributedString = attributedString
        self.textView = NSTextView()
        self.scrollView = NSScrollView()
        
        // Configure scroll view for both directions
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = true
        
        // Configure text view for horizontal resizing and no wrapping
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = true
        textView.autoresizingMask = [.width] // height managed by container
        textView.usesAdaptiveColorMappingForDarkAppearance = true
        textView.textContainerInset = .init(width: 15.0, height: 0.0)
        // Critical: disable wrapping and allow unbounded width
        if let container = textView.textContainer {
            container.widthTracksTextView = false
            container.containerSize = NSSize(width: CoreFoundation.CGFloat.greatestFiniteMagnitude, height: CoreFoundation.CGFloat.greatestFiniteMagnitude)
        }
        textView.maxSize = NSSize(width: CoreFoundation.CGFloat.greatestFiniteMagnitude, height: CoreFoundation.CGFloat.greatestFiniteMagnitude)
        textView.minSize = NSSize(width: 0, height: 0)
        textView.textStorage?.setAttributedString(NSAttributedString(attributedString))
        
        // Put textView into the scroll view
        scrollView.documentView = textView
        
        // Optional: add a line number label (kept from your code)
        var string = ""
        for i in 1..<lineCount + 1 {
            string += "\(i)\n"
        }
        label = NSTextField(labelWithString: string)
        label.font = .systemFont(ofSize: 12.0)
        label.translatesAutoresizingMaskIntoConstraints = false
        textView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 0.0),
            label.trailingAnchor.constraint(equalTo: textView.leadingAnchor, constant: 30.0)
        ])
        
        super.init(nibName: nil, bundle: nil)
        self.view = scrollView
    }
    
    func updateAttributedString(attributedString: AttributedString, font: NSFont?) {
        self.attributedString = attributedString
        textView.textStorage?.setAttributedString(NSAttributedString(attributedString))
        textView.font = font ?? .systemFont(ofSize: 12.0)
        label.font = font ?? .systemFont(ofSize: 12.0)
        previousFontSize = Double(font?.pointSize ?? previousFontSize)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

struct CustomTextEditorView: NSViewControllerRepresentable {
    @Binding var lineCount: Int
    @Binding var attributedString: AttributedString
    let fontSize: Double
    
    init(lineCount: Binding<Int>, attributedString: Binding<AttributedString>, fontSize: Double) {
        self._lineCount = lineCount
        self._attributedString = attributedString
        self.fontSize = fontSize
    }
        
    func makeCoordinator() -> CustomTextEditorCoordinator {
        CustomTextEditorCoordinator(fontSize: fontSize)
    }
    
    func makeNSViewController(context: Self.Context) -> TextViewController {
        TextViewController(lineCount: lineCount, attributedString: attributedString)
    }
    
    func updateNSViewController(_ nsViewController: TextViewController, context: Self.Context) {
        nsViewController.updateAttributedString(attributedString: attributedString, font: .systemFont(ofSize: fontSize))
        print("update")
    }
}

class CustomTextEditorCoordinator {
    var font: NSFont {
        NSFont.systemFont(ofSize: fontSize)
    }
    var fontSize: Double
    
    init(fontSize: Double) {
        self.fontSize = fontSize
    }
}

#Preview {
    EditorView(viewModel: EditorViewModel())
}

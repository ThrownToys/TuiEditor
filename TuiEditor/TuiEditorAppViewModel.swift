//
//  TuiEditorAppViewModel.swift
//  TuiEditor
//

internal import Foundation
internal import Combine

class AppViewModel: ObservableObject {
    
    var inputPipe: Pipe? = nil
    var outputPipe: Pipe? = nil
    @Published var outputText: String = ""
    
    var errorLineNumbers: [Int] = []
    
    init() {
        startListeningToStdout()
    }
    
    isolated deinit {
        stopListeningToStdout()
    }
    
    func clearLog() {
        outputText = ""
    }
    
    private func startListeningToStdout() {
        inputPipe = Pipe()
        outputPipe = Pipe()
        
        guard let inputPipe, let outputPipe else { return }
        
        let pipeReadHandle = inputPipe.fileHandleForReading

        dup2(STDOUT_FILENO, outputPipe.fileHandleForWriting.fileDescriptor)
        
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // You can comment out the following line if the log output is excessive, but this will
        // stop you seeing debug information in the editor.
        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePipeNotification), name: FileHandle.readCompletionNotification, object: pipeReadHandle)

        pipeReadHandle.readInBackgroundAndNotify(forModes: [RunLoop.Mode.common])
    }
    
    @objc func handlePipeNotification(notification: Notification) {
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify(forModes: [RunLoop.Mode.common])
        
        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: String.Encoding.ascii) {
            outputPipe?.fileHandleForWriting.write(data)
            outputText.append(str)
            let matches = outputText.matches(of: #/file:debug:([0-9]+)/#)
            var errorLineNumbers: [Int] = []
            for match in matches {
                let lineNumber = Int(match.1)
                if let lineNumber {
                    errorLineNumbers.append(lineNumber)
                }
            }
            self.errorLineNumbers = errorLineNumbers
        }
    }
    
    private func stopListeningToStdout() {
        NotificationCenter.default.removeObserver(self)
    }
}

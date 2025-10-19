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
//        dup2(inputPipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)

        NotificationCenter.default.addObserver(self, selector: #selector(self.handlePipeNotification), name: FileHandle.readCompletionNotification, object: pipeReadHandle)

        pipeReadHandle.readInBackgroundAndNotify(forModes: [RunLoop.Mode.common])
    }
    
    @objc func handlePipeNotification(notification: Notification) {
        inputPipe?.fileHandleForReading.readInBackgroundAndNotify(forModes: [RunLoop.Mode.common])
        
        if let data = notification.userInfo?[NSFileHandleNotificationDataItem] as? Data,
           let str = String(data: data, encoding: String.Encoding.ascii) {
            outputPipe?.fileHandleForWriting.write(data)
            outputText.append(str)
        }
    }
    
    private func stopListeningToStdout() {
        NotificationCenter.default.removeObserver(self)
    }
}

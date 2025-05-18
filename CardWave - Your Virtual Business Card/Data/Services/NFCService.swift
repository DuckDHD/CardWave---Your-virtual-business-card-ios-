import Foundation
import CoreNFC

enum NFCError: Error {
    case notSupported
    case sessionTimeout
    case readError
    case writeError
    case invalidData
    case unknown
}

protocol NFCServiceProtocol {
    func startSendingSession(with contact: Contact) async throws
    func startReceivingSession() async throws -> Contact
    func startBackgroundDetection(with contact: Contact)
    func stopBackgroundDetection()
    var onSessionStarted: (() -> Void)? { get set }
    var onSessionEnded: ((Bool, Error?) -> Void)? { get set }
    var onAutoContactReceived: ((Contact) -> Void)? { get set }
}

@available(iOS 13.0, *)
class NFCService: NSObject, NFCServiceProtocol, NFCNDEFReaderSessionDelegate {
    private var readerSession: NFCNDEFReaderSession?
    private var backgroundReaderSession: NFCNDEFReaderSession?
    private var contact: Contact?
    private var isReceiving = false
    private var continuation: CheckedContinuation<Contact, Error>?
    private var isBackgroundDetectionActive = false
    private var backgroundContact: Contact?
    
    var onSessionStarted: (() -> Void)?
    var onSessionEnded: ((Bool, Error?) -> Void)?
    var onAutoContactReceived: ((Contact) -> Void)?
    
    func startSendingSession(with contact: Contact) async throws {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.notSupported
        }
        
        self.contact = contact
        self.isReceiving = false
        
        return try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                self.readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
                self.readerSession?.alertMessage = "Hold your iPhone near another iPhone to send contact."
                self.readerSession?.begin()
                self.onSessionStarted?()
            }
        }
    }
    
    func startReceivingSession() async throws -> Contact {
        guard NFCNDEFReaderSession.readingAvailable else {
            throw NFCError.notSupported
        }
        
        self.isReceiving = true
        
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            DispatchQueue.main.async {
                self.readerSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: true)
                self.readerSession?.alertMessage = "Hold your iPhone near another iPhone to receive contact."
                self.readerSession?.begin()
                self.onSessionStarted?()
            }
        }
    }
    
    func startBackgroundDetection(with contact: Contact) {
        guard NFCNDEFReaderSession.readingAvailable else {
            return
        }
        
        self.backgroundContact = contact
        self.isBackgroundDetectionActive = true
        
        startBackgroundReaderSession()
    }
    
    func stopBackgroundDetection() {
        isBackgroundDetectionActive = false
        backgroundReaderSession?.invalidate()
        backgroundReaderSession = nil
    }
    
    private func startBackgroundReaderSession() {
        guard isBackgroundDetectionActive, backgroundReaderSession == nil else {
            return
        }
        
        DispatchQueue.main.async {
            self.backgroundReaderSession = NFCNDEFReaderSession(delegate: self, queue: nil, invalidateAfterFirstRead: false)
            self.backgroundReaderSession?.alertMessage = "Contact sharing in progress..."
            self.backgroundReaderSession?.begin()
        }
    }
    
    // MARK: - NFCNDEFReaderSessionDelegate
    
    func readerSession(_ session: NFCNDEFReaderSession, didInvalidateWithError error: Error) {
        // Handle background session invalidation
        if session == backgroundReaderSession {
            backgroundReaderSession = nil
            
            // Restart background session if still active
            if isBackgroundDetectionActive {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.startBackgroundReaderSession()
                }
            }
            return
        }
        
        // Handle regular session invalidation
        let nfcError: NFCError
        
        if let ndefError = error as? NFCReaderError {
            switch ndefError.code {
            case .readerSessionInvalidationErrorFirstNDEFTagRead, .readerSessionInvalidationErrorUserCanceled:
                // These are normal termination cases
                nfcError = .sessionTimeout
            default:
                nfcError = .unknown
            }
        } else {
            nfcError = .unknown
        }
        
        onSessionEnded?(false, nfcError)
        
        if let continuation = self.continuation {
            continuation.resume(throwing: nfcError)
            self.continuation = nil
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetectNDEFs messages: [NFCNDEFMessage]) {
        // Handle background session detection
        if session == backgroundReaderSession {
            processBackgroundDetection(messages: messages)
            return
        }
        
        // Handle regular session detection
        if isReceiving {
            // Process received contact
            guard let message = messages.first,
                  let record = message.records.first,
                  record.typeNameFormat == .media,
                  let payload = String(data: record.payload, encoding: .utf8),
                  let data = payload.data(using: .utf8) else {
                onSessionEnded?(false, NFCError.invalidData)
                continuation?.resume(throwing: NFCError.invalidData)
                continuation = nil
                return
            }
            
            do {
                let contact = try JSONDecoder().decode(Contact.self, from: data)
                onSessionEnded?(true, nil)
                continuation?.resume(returning: contact)
                continuation = nil
            } catch {
                onSessionEnded?(false, NFCError.invalidData)
                continuation?.resume(throwing: NFCError.invalidData)
                continuation = nil
            }
        } else {
            // Sending is handled in didDetect
        }
    }
    
    private func processBackgroundDetection(messages: [NFCNDEFMessage]) {
        // Process received contact in background mode
        guard let message = messages.first,
              let record = message.records.first,
              record.typeNameFormat == .media,
              let payload = String(data: record.payload, encoding: .utf8),
              let data = payload.data(using: .utf8) else {
            return
        }
        
        do {
            let contact = try JSONDecoder().decode(Contact.self, from: data)
            onAutoContactReceived?(contact)
            
            // Send our contact back automatically
            if let backgroundContact = self.backgroundContact {
                sendContactInBackground(backgroundContact)
            }
        } catch {
            // Silently fail in background mode
            print("Failed to decode contact in background mode: \(error)")
        }
    }
    
    private func sendContactInBackground(_ contact: Contact) {
        guard let backgroundReaderSession = backgroundReaderSession,
              let tags = backgroundReaderSession.connectedTag as? [NFCNDEFTag],
              let tag = tags.first else {
            return
        }
        
        backgroundReaderSession.connect(to: tag) { error in
            if let error = error {
                print("Background connection failed: \(error)")
                return
            }
            
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    print("Background query failed: \(error)")
                    return
                }
                
                // Encode contact to JSON
                guard let contactData = try? JSONEncoder().encode(contact),
                      let contactString = String(data: contactData, encoding: .utf8),
                      let payload = contactString.data(using: .utf8) else {
                    print("Failed to encode contact data in background")
                    return
                }
                
                // Create NDEF message
                let record = NFCNDEFPayload(
                    format: .media,
                    type: "application/json".data(using: .utf8)!,
                    identifier: "com.nfccontactshare.contact".data(using: .utf8)!,
                    payload: payload
                )
                let message = NFCNDEFMessage(records: [record])
                
                // Write to tag
                tag.writeNDEF(message) { error in
                    if let error = error {
                        print("Background write failed: \(error)")
                    } else {
                        print("Background contact sent successfully")
                    }
                }
            }
        }
    }
    
    func readerSession(_ session: NFCNDEFReaderSession, didDetect tags: [NFCNDEFTag]) {
        // Handle background session detection
        if session == backgroundReaderSession {
            // Store connected tag for background use
            backgroundReaderSession?.connectedTag = tags
            return
        }
        
        // Handle regular session detection
        guard !isReceiving, let contact = self.contact else { return }
        
        // Connect to first tag
        let tag = tags.first!
        session.connect(to: tag) { error in
            if let error = error {
                session.invalidate(errorMessage: "Connection failed: \(error.localizedDescription)")
                self.onSessionEnded?(false, error)
                return
            }
            
            // Query tag if it contains any messages
            tag.queryNDEFStatus { status, capacity, error in
                if let error = error {
                    session.invalidate(errorMessage: "Query failed: \(error.localizedDescription)")
                    self.onSessionEnded?(false, error)
                    return
                }
                
                // Encode contact to JSON
                guard let contactData = try? JSONEncoder().encode(contact),
                      let contactString = String(data: contactData, encoding: .utf8),
                      let payload = contactString.data(using: .utf8) else {
                    session.invalidate(errorMessage: "Failed to encode contact data")
                    self.onSessionEnded?(false, NFCError.invalidData)
                    return
                }
                
                // Create NDEF message
                let record = NFCNDEFPayload(
                    format: .media,
                    type: "application/json".data(using: .utf8)!,
                    identifier: "com.nfccontactshare.contact".data(using: .utf8)!,
                    payload: payload
                )
                let message = NFCNDEFMessage(records: [record])
                
                // Write to tag
                tag.writeNDEF(message) { error in
                    if let error = error {
                        session.invalidate(errorMessage: "Write failed: \(error.localizedDescription)")
                        self.onSessionEnded?(false, error)
                    } else {
                        session.invalidate()
                        self.onSessionEnded?(true, nil)
                    }
                }
            }
        }
    }
}

// Extension to store connected tag for background use
extension NFCNDEFReaderSession {
    private static var connectedTagKey = "connectedTagKey"
    
    var connectedTag: Any? {
        get {
            return objc_getAssociatedObject(self, &NFCNDEFReaderSession.connectedTagKey)
        }
        set {
            objc_setAssociatedObject(self, &NFCNDEFReaderSession.connectedTagKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
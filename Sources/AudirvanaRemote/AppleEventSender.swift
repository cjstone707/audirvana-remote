import AppKit
import CoreServices

/// Sends raw Apple Events by class/id + keyword parameters, bypassing AppleScript's text
/// parser. Needed for Audirvana's "set playing track" command: its name collides with
/// AppleScript's own `set` keyword and its `type`/`URL` parameter labels also collide with
/// reserved terms, making it impossible to invoke from AppleScript source text.
enum AppleEventSender {
    static func fourCharCode(_ s: String) -> FourCharCode {
        var result: FourCharCode = 0
        for scalar in s.unicodeScalars.prefix(4) {
            result = (result << 8) + FourCharCode(scalar.value)
        }
        return result
    }

    static func send(
        toBundleID bundleID: String,
        eventClass: String,
        eventID: String,
        params: [(keyword: String, descriptor: NSAppleEventDescriptor)]
    ) {
        let target = NSAppleEventDescriptor(bundleIdentifier: bundleID)
        let event = NSAppleEventDescriptor.appleEvent(
            withEventClass: fourCharCode(eventClass),
            eventID: fourCharCode(eventID),
            targetDescriptor: target,
            returnID: AEReturnID(kAutoGenerateReturnID),
            transactionID: AETransactionID(kAnyTransactionID)
        )
        for param in params {
            event.setDescriptor(param.descriptor, forKeyword: fourCharCode(param.keyword))
        }

        var reply = AEDesc()
        _ = AESendMessage(event.aeDesc, &reply, AESendMode(kAENoReply), kAEDefaultTimeout)
        AEDisposeDesc(&reply)
    }
}

import Carbon.HIToolbox
import Cocoa

/// Registers a system-wide Control+Space hotkey using the Carbon HotKey API.
/// This does not require Accessibility permission (unlike a global NSEvent monitor).
final class HotKeyManager {
    private var hotKeyRef: EventHotKeyRef?
    private let onPress: () -> Void

    init(onPress: @escaping () -> Void) {
        self.onPress = onPress
        register()
    }

    deinit {
        if let hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
        }
    }

    private func register() {
        var eventSpec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: OSType(kEventHotKeyPressed)
        )

        InstallEventHandler(GetApplicationEventTarget(), { _, _, userData in
            guard let userData else { return noErr }
            Unmanaged<HotKeyManager>.fromOpaque(userData).takeUnretainedValue().onPress()
            return noErr
        }, 1, &eventSpec, Unmanaged.passUnretained(self).toOpaque(), nil)

        let keyCode: UInt32 = 49 // kVK_Space
        let modifiers: UInt32 = UInt32(cmdKey)
        let hotKeyID = EventHotKeyID(signature: OSType(0x4C4E4348), id: 1) // 'LNCH'
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

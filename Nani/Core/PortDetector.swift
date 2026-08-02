import Foundation
import Combine
import IOKit
import IOKit.usb
import CoreAudio
import IOKit.ps

// MARK: - Port Detector

/// Unified port detection manager that monitors USB, audio, and power events.
/// Publishes port events via Combine for reactive UI updates.
@MainActor
final class PortDetector: ObservableObject {

    // MARK: - Published State

    @Published var portStatuses: [PortType: PortStatus] = [:]
    @Published var lastEvent: PortEvent?

    // MARK: - Event Stream

    let eventSubject = PassthroughSubject<PortEvent, Never>()

    // MARK: - Private

    private var usbNotificationPort: IONotificationPortRef?
    private var addedIterator: io_iterator_t = 0
    private var removedIterator: io_iterator_t = 0
    private var audioDeviceListenerBlock: AudioObjectPropertyListenerBlock?
    private var powerSourceRunLoopSource: CFRunLoopSource?
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    init() {
        // Initialize all port statuses
        for portType in PortType.allCases {
            portStatuses[portType] = PortStatus(
                portType: portType,
                isConnected: false,
                isEnabled: true,
                assignedSoundID: SoundAsset.defaultAssignments[portType]
            )
        }

        startUSBMonitoring()
        startAudioMonitoring()
        startPowerMonitoring()

        // Check initial states
        checkInitialUSBState()
        checkInitialAudioState()
        checkInitialPowerState()
    }
    // No deinit needed for singleton lifecycle

    // MARK: - USB Detection (IOKit)

    /// Monitors USB-C and USB-A device connect/disconnect events via IOKit.
    private func startUSBMonitoring() {
        usbNotificationPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let notificationPort = usbNotificationPort else {
            Log.ports.error("Failed to create IOKit notification port")
            return
        }

        let runLoopSource = IONotificationPortGetRunLoopSource(notificationPort).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .defaultMode)

        // Match all USB devices
        guard let matchingDict = IOServiceMatching(kIOUSBDeviceClassName) else {
            Log.ports.error("Failed to create USB matching dictionary")
            return
        }

        // We need a separate matching dict for removal, because IOServiceAddMatchingNotification consumes and modifies the dictionary
        guard let matchingDictRemove = IOServiceMatching(kIOUSBDeviceClassName) else {
            Log.ports.error("Failed to create USB matching dictionary for removal")
            return
        }

        // Device added
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        let addResult = IOServiceAddMatchingNotification(
            notificationPort,
            kIOFirstMatchNotification,
            matchingDict,
            { (refcon, iterator) in
                let detector = Unmanaged<PortDetector>.fromOpaque(refcon!).takeUnretainedValue()
                Task { @MainActor in
                    detector.handleUSBDevicesAdded(iterator: iterator)
                }
            },
            selfPtr,
            &addedIterator
        )

        if addResult == KERN_SUCCESS {
            // Drain the iterator to arm the notification
            drainIterator(addedIterator)
        }

        // Device removed
        let removeResult = IOServiceAddMatchingNotification(
            notificationPort,
            kIOTerminatedNotification,
            matchingDictRemove,
            { (refcon, iterator) in
                let detector = Unmanaged<PortDetector>.fromOpaque(refcon!).takeUnretainedValue()
                Task { @MainActor in
                    detector.handleUSBDevicesRemoved(iterator: iterator)
                }
            },
            selfPtr,
            &removedIterator
        )

        if removeResult == KERN_SUCCESS {
            drainIterator(removedIterator)
        }

        Log.ports.info("USB monitoring started")
    }

    private func handleUSBDevicesAdded(iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            let portType = classifyUSBDevice(device)
            IOObjectRelease(device)

            if let portType = portType {
                updatePortStatus(portType, isConnected: true)
                let event = PortEvent.connected(portType)
                lastEvent = event
                eventSubject.send(event)
                Log.ports.info("\(portType.displayName, privacy: .public) connected")
            }
        }
    }

    private func handleUSBDevicesRemoved(iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            let portType = classifyUSBDevice(device)
            IOObjectRelease(device)

            if let portType = portType {
                updatePortStatus(portType, isConnected: false)
                let event = PortEvent.disconnected(portType)
                lastEvent = event
                eventSubject.send(event)
                Log.ports.info("\(portType.displayName, privacy: .public) disconnected")
            }
        }
    }

    /// Classify a USB device as USB-C or USB-A based on speed/properties.
    private func classifyUSBDevice(_ device: io_service_t) -> PortType? {
        // Get device speed to help classify
        var properties: Unmanaged<CFMutableDictionary>?
        let result = IORegistryEntryCreateCFProperties(device, &properties, kCFAllocatorDefault, 0)
        guard result == KERN_SUCCESS, let props = properties?.takeRetainedValue() as? [String: Any] else {
            return .usbA  // Default fallback
        }

        // USB 3.x devices on modern Macs are typically USB-C
        if let speed = props["USB Speed"] as? Int, speed >= 5000 {
            return .usbC
        }

        // Check for USB-C specific properties
        if let locationID = props["locationID"] as? Int {
            // Thunderbolt/USB-C ports typically have specific location ID ranges
            // This is a heuristic — exact ranges vary by Mac model
            let portBits = (locationID >> 24) & 0xFF
            if portBits >= 0x01 && portBits <= 0x06 {
                return .usbC
            }
        }

        return .usbA
    }

    private func drainIterator(_ iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            IOObjectRelease(device)
        }
    }

    private func checkInitialUSBState() {
        // Check for currently connected USB devices
        let matchingDict = IOServiceMatching(kIOUSBDeviceClassName)
        var iterator: io_iterator_t = 0
        let result = IOServiceGetMatchingServices(kIOMainPortDefault, matchingDict, &iterator)

        if result == KERN_SUCCESS {
            var usbCCount = 0
            var usbACount = 0

            while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
                if let portType = classifyUSBDevice(device) {
                    switch portType {
                    case .usbC: usbCCount += 1
                    case .usbA: usbACount += 1
                    default: break
                    }
                }
                IOObjectRelease(device)
            }

            IOObjectRelease(iterator)

            if usbCCount > 0 {
                updatePortStatus(.usbC, isConnected: true)
            }
            if usbACount > 0 {
                updatePortStatus(.usbA, isConnected: true)
            }
        }
    }

    // MARK: - Audio Detection (CoreAudio)

    /// Monitors headphone jack and HDMI audio device changes via CoreAudio.
    private func startAudioMonitoring() {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        audioDeviceListenerBlock = { [weak self] (numberAddresses, addresses) in
            Task { @MainActor [weak self] in
                self?.handleAudioDeviceChange()
            }
        }

        let status = AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            DispatchQueue.main,
            audioDeviceListenerBlock!
        )

        // Also listen to device list changes just in case (HDMI hotplug etc)
        var devicesAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        AudioObjectAddPropertyListenerBlock(
            AudioObjectID(kAudioObjectSystemObject),
            &devicesAddress,
            DispatchQueue.main,
            audioDeviceListenerBlock!
        )

        if status == noErr {
            Log.audio.info("Audio monitoring started")
        } else {
            Log.audio.error("Failed to start audio monitoring: \(status)")
        }
    }

    private func handleAudioDeviceChange() {
        let devices = getAudioDevices()
        let defaultOutputDevice = getDefaultOutputDevice()

        var hasHeadphones = false
        var hasHDMI = false

        // Determine if default output is headphones
        if defaultOutputDevice != 0 {
            let defaultName = getAudioDeviceName(defaultOutputDevice)
            if defaultName.localizedCaseInsensitiveContains("headphone") {
                hasHeadphones = true
            }
        }

        for device in devices {
            let name = getAudioDeviceName(device)
            let transportType = getAudioDeviceTransportType(device)

            if transportType == kAudioDeviceTransportTypeHDMI || transportType == kAudioDeviceTransportTypeDisplayPort || name.localizedCaseInsensitiveContains("hdmi") {
                hasHDMI = true
            }
        }

        let wasHeadphoneConnected = portStatuses[.headphoneJack]?.isConnected ?? false
        let wasHDMIConnected = portStatuses[.hdmi]?.isConnected ?? false

        if hasHeadphones != wasHeadphoneConnected {
            updatePortStatus(.headphoneJack, isConnected: hasHeadphones)
            let event: PortEvent = hasHeadphones ? .connected(.headphoneJack) : .disconnected(.headphoneJack)
            lastEvent = event
            eventSubject.send(event)
            Log.audio.info("Headphone Jack \(hasHeadphones ? "connected" : "disconnected", privacy: .public)")
        }

        if hasHDMI != wasHDMIConnected {
            updatePortStatus(.hdmi, isConnected: hasHDMI)
            let event: PortEvent = hasHDMI ? .connected(.hdmi) : .disconnected(.hdmi)
            lastEvent = event
            eventSubject.send(event)
            Log.audio.info("HDMI \(hasHDMI ? "connected" : "disconnected", privacy: .public)")
        }
    }

    private func getAudioDevices() -> [AudioObjectID] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize
        )

        guard status == noErr else { return [] }

        let deviceCount = Int(dataSize) / MemoryLayout<AudioObjectID>.size
        var devices = [AudioObjectID](repeating: 0, count: deviceCount)

        status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &devices
        )

        return status == noErr ? devices : []
    }

    private func getDefaultOutputDevice() -> AudioDeviceID {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var deviceID: AudioDeviceID = 0
        var dataSize = UInt32(MemoryLayout<AudioDeviceID>.size)
        
        let status = AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &propertyAddress,
            0, nil,
            &dataSize,
            &deviceID
        )
        
        return status == noErr ? deviceID : 0
    }

    private func getAudioDeviceName(_ deviceID: AudioObjectID) -> String {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyDeviceNameCFString,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var name: Unmanaged<CFString>?
        var dataSize = UInt32(MemoryLayout<Unmanaged<CFString>>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize,
            &name
        )

        if status == noErr, let cfString = name?.takeRetainedValue() {
            return cfString as String
        }
        return ""
    }

    private func getAudioDeviceTransportType(_ deviceID: AudioObjectID) -> UInt32 {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyTransportType,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        var transportType: UInt32 = 0
        var dataSize = UInt32(MemoryLayout<UInt32>.size)

        let status = AudioObjectGetPropertyData(
            deviceID,
            &propertyAddress,
            0, nil,
            &dataSize,
            &transportType
        )

        return status == noErr ? transportType : 0
    }

    private func checkInitialAudioState() {
        handleAudioDeviceChange()
    }

    // MARK: - Power Detection (IOPowerSources)

    /// Monitors charger connect/disconnect via IOPowerSources.
    private func startPowerMonitoring() {
        let context = Unmanaged.passUnretained(self).toOpaque()

        powerSourceRunLoopSource = IOPSNotificationCreateRunLoopSource({ (context) in
            guard let context = context else { return }
            let detector = Unmanaged<PortDetector>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                detector.handlePowerSourceChange()
            }
        }, context).takeRetainedValue()

        if let source = powerSourceRunLoopSource {
            CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)
            Log.ports.info("Power monitoring started")
        }
    }

    private func handlePowerSourceChange() {
        let isPlugged = isChargerConnected()
        let wasPlugged = portStatuses[.charger]?.isConnected ?? false

        if isPlugged != wasPlugged {
            updatePortStatus(.charger, isConnected: isPlugged)
            let event: PortEvent = isPlugged ? .connected(.charger) : .disconnected(.charger)
            lastEvent = event
            eventSubject.send(event)
            Log.ports.info("Charger \(isPlugged ? "connected" : "disconnected", privacy: .public)")
        }
    }

    private func isChargerConnected() -> Bool {
        guard let snapshot = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(snapshot)?.takeRetainedValue() as? [CFTypeRef] else {
            return false
        }

        for source in sources {
            if let description = IOPSGetPowerSourceDescription(snapshot, source)?.takeUnretainedValue() as? [String: Any] {
                if let powerSource = description[kIOPSPowerSourceStateKey] as? String {
                    return powerSource == kIOPSACPowerValue
                }
            }
        }

        return false
    }

    private func checkInitialPowerState() {
        let isPlugged = isChargerConnected()
        updatePortStatus(.charger, isConnected: isPlugged)
    }

    // MARK: - State Management

    private func updatePortStatus(_ portType: PortType, isConnected: Bool) {
        portStatuses[portType]?.isConnected = isConnected
    }

    func togglePort(_ portType: PortType) {
        portStatuses[portType]?.isEnabled.toggle()
    }

    func assignSound(_ soundID: String, to portType: PortType) {
        portStatuses[portType]?.assignedSoundID = soundID
    }

    // MARK: - Cleanup

    private func stopAllMonitoring() {
        // Remove USB notifications
        if let port = usbNotificationPort {
            IONotificationPortDestroy(port)
        }
        if addedIterator != 0 { IOObjectRelease(addedIterator) }
        if removedIterator != 0 { IOObjectRelease(removedIterator) }

        // Remove audio listener
        if let block = audioDeviceListenerBlock {
            var propertyAddress = AudioObjectPropertyAddress(
                mSelector: kAudioHardwarePropertyDevices,
                mScope: kAudioObjectPropertyScopeGlobal,
                mElement: kAudioObjectPropertyElementMain
            )
            AudioObjectRemovePropertyListenerBlock(
                AudioObjectID(kAudioObjectSystemObject),
                &propertyAddress,
                DispatchQueue.main,
                block
            )
        }

        // Remove power source listener
        if let source = powerSourceRunLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }
}

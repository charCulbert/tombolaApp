import Foundation
import AudioKit
import CoreMIDI

class TombolaMIDI {
    static let shared = TombolaMIDI()
    private let midi = MIDI()
    private var virtualPorts: [MIDIPortRef] = []
    
    private init() {
        setupMIDI()
    }
    
    private func setupMIDI() {
        print("Setting up MIDI...")
        midi.openOutput()
        midi.createVirtualOutputPorts(count: 1, uniqueIDs: nil, names: ["TombolaCollisions"])
        
        // Store the virtual output ports reference
        virtualPorts = midi.virtualOutputs
        print("✅ MIDI setup complete - created \(virtualPorts.count) virtual ports")
    }
    
    func makeNote(velocity: UInt8) {
        // Notes in fifths: C3, G3, D4, A4, E5
        let notes: [UInt8] = [48, 55, 62, 69, 76]
        let note = MIDINoteNumber(notes.randomElement() ?? 48)
        let channel = MIDIChannel(0)
        
        // Note On
        midi.sendNoteOnMessage(noteNumber: note,
                             velocity: velocity,
                             channel: channel,
                             virtualOutputPorts: virtualPorts)
        
        // Schedule Note Off after 100ms
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.midi.sendNoteOffMessage(noteNumber: note,
                                       channel: channel,
                                       virtualOutputPorts: self.virtualPorts)
        }
    }
}

//
//  ViewController.swift
//  VoiceProcessing
//
//  Created by Balázs Kiss on 2021. 04. 14..
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    
    @IBOutlet var configurationChangeLabel: UILabel!

    var configurationChangeCount: Int = 0 {
        didSet {
            configurationChangeLabel.text = "Conf change count: \(configurationChangeCount)"
        }
    }
    
    let audioEngine = AVAudioEngine()
    let player = AVAudioPlayerNode()
    var vpio = false
    var stereoMusicBuffer: AVAudioPCMBuffer = {
        do {
            let audioFileURL = Bundle.main.url(forResource: "stereo-voice", withExtension: "wav")!
            let file = try AVAudioFile(forReading: audioFileURL)
            let buffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length))!
            try file.read(into: buffer)
            return buffer
        } catch let error {
            fatalError("Could not load audio file: \(error.localizedDescription)")
        }
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        addNotificationObservers()
        
        startAudioSession()
        startEngine()
        playStereoMusic()
    }

    func startAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, policy: .default, options: [.defaultToSpeaker, .allowBluetooth])
            
            try AVAudioSession.sharedInstance().setActive(true, options: [.notifyOthersOnDeactivation])
            
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }

    func stopAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }
    
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAudioEngineConfigurationChange),
            name: NSNotification.Name.AVAudioEngineConfigurationChange,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRouteChange),
            name: AVAudioSession.routeChangeNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMediaServicesReset),
            name: AVAudioSession.mediaServicesWereResetNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(self,
           selector: #selector(self.handleInterruption(_:)),
           name: AVAudioSession.interruptionNotification,
           object: AVAudioSession.sharedInstance())
    }
    
    @objc func handleAudioEngineConfigurationChange(notification: NSNotification) {
        DispatchQueue.main.async {
            guard let notifyingEngine = notification.object as? AVAudioEngine, notifyingEngine == self.audioEngine else {
                return
            }
            self.configurationChangeCount += 1
            print("HandleAudioEngineConfigurationChange \(notification.description)")
            self.startEngine()
            self.playStereoMusic()
        }
    }

    @objc func handleRouteChange(notification: Notification) {
        print("HandleRouteChange \(notification.description)")
        print("CurrentRoute \(AVAudioSession.sharedInstance().currentRoute.description)")
    }

    @objc func handleMediaServicesReset() {
        print("HandleMediaServicesReset")
    }
    
    @objc
    func handleInterruption(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
            let typeValue = userInfo[AVAudioSessionInterruptionTypeKey] as? UInt,
            let type = AVAudioSession.InterruptionType(rawValue: typeValue) else { return }
        
        switch type {
        case .began:
            // Interruption began, take appropriate actions
            print("Interuption started")
            stopEngine()
            
            do {
                try AVAudioSession.sharedInstance().setActive(false)
            } catch {
                print("Could not set audio session active: \(error)")
            }
            
        case .ended:
            do {
                try AVAudioSession.sharedInstance().setActive(true)
            } catch {
                print("Could not set audio session active: \(error)")
            }
            print("Interuption ended")
            startEngine()
        @unknown default:
            fatalError("Unknown type: \(type)")
        }
    }

    func startEngine() {
        do {
            audioEngine.attach(player)
            audioEngine.connect(player, to: audioEngine.mainMixerNode, format: nil)

            // First attempt to mitigate
            if !vpio {
                let format = AVAudioFormat(standardFormatWithSampleRate: AVAudioSession.sharedInstance().sampleRate, channels: 2)!
                audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: format)
            } else {
                audioEngine.connect(audioEngine.mainMixerNode, to: audioEngine.outputNode, format: nil)
            }

            
            // let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, channels: 2, interleaved: false)!
            // let format = AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 48000, interleaved: false, channelLayout: T##AVAudioChannelLayout)!
            // try audioEngine.enableManualRenderingMode(.realtime, format: format, maximumFrameCount: 1000)

            try audioEngine.start()

            print("mainMixer input" + String(describing: audioEngine.mainMixerNode.inputFormat(forBus: 0)))
            print("mainMixer output" + String(describing: audioEngine.mainMixerNode.outputFormat(forBus: 0)))
            print("outputNode input" + String(describing: audioEngine.outputNode.inputFormat(forBus: 0)))
            print("outputNode output" + String(describing: audioEngine.outputNode.outputFormat(forBus: 0)))
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }

    func stopEngine() {
        audioEngine.stop()
    }

    func setVoiceProcessingEnabled(_ isEnabled: Bool) {
        do {
            vpio = isEnabled
            try audioEngine.outputNode.setVoiceProcessingEnabled(isEnabled)
        } catch let error {
            print("Error: \(error.localizedDescription)")
        }
    }

    func playStereoMusic() {
        player.scheduleBuffer(self.stereoMusicBuffer, at: nil, options: [.loops], completionHandler: {
            print("player scheduleBuffer completionHandler")
        })
        self.player.play()
    }

    func stopStereoMusic() {
        self.player.stop()
    }
    
    // MARK: - IB Actions

    @IBAction func tappedSetVoiceProcessingOnButton() {
        stopStereoMusic()
        stopEngine()
        stopAudioSession()
        setVoiceProcessingEnabled(true)
        startAudioSession()
        startEngine()
        playStereoMusic()
    }

    @IBAction func tappedSetVoiceProcessingOffButton() {
        stopStereoMusic()
        stopEngine()
        setVoiceProcessingEnabled(false)
        startEngine()
        playStereoMusic()
    }
}


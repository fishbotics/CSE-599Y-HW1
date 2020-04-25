//
//  AudioEngine.swift
//  Mobile Systems Project 1
//
//  Created by Adam Fishman on 4/18/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import Foundation
import AudioKit

let SW_WINDOW = 71

final class AudioEngine : ObservableObject {
    var oscillator: AKOscillator
    @Published var playingTone = false
    let mic: AKMicrophone!
    var mixer = AKMixer()
    var fftTap: AKFFTTap?
    var timer:  Timer!
    let FFT_SIZE = 512
    let sampleRate:double_t = 44100
    var peak_amplitude = 1.0
    
    var calibration_timer: Int = 0
    var all_calibration_amplitudes = [[Double]](
        repeating: [Double](repeating: 0, count: 200),
        count: SW_WINDOW)
    var calibrated_amplitudes = [Double](repeating: 0, count: SW_WINDOW)
    var amplitudes = [Double](repeating: 0, count: SW_WINDOW)
    var waiting_timer: Int = 100
    @Published var calibrating = true
    @Published var gesture: String = "No gesture detected"

    init() {
        oscillator = AKOscillator()
        let muter = AKMixer()
        muter.volume = 0
        mic = AKMicrophone()
        fftTap = AKFFTTap.init(mic)
        mic >>> muter >>> mixer
        oscillator >>> mixer
        AudioKit.output = mixer
        do {
            try AudioKit.start()
        } catch {
            AKLog("File Not Found or AudioKit did not start")
        }
        let emitted_frequency: Double = 18000
        oscillator.frequency = emitted_frequency
        
	// Inspired by this stack overflow answer
	// https://stackoverflow.com/questions/52687711/trying-to-understand-the-output-of-akffttap-in-audiokit
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in

            if self.playingTone {
                // Only use the range that would be affected by the Doppler effect
                let center_bin = Int(emitted_frequency * self.FFT_SIZE / self.sampleRate)
                
                // These represent the bounds of the bandwidth
                for i in (center_bin - SW_WINDOW / 2)...(center_bin + SW_WINDOW / 2) {

                    let re = self.fftTap!.fftData[2 * i]
                    let im = self.fftTap!.fftData[2 * i + 1]
                    let bin = i
                    let normBinMag = 2.0 * sqrt(re * re + im * im) / self.FFT_SIZE
                    let amplitude = (20.0 * log10(normBinMag))
                    let frequency = self.sampleRate * bin / self.FFT_SIZE
                    let idx = bin - (center_bin - SW_WINDOW / 2)
                    self.amplitudes[idx] = amplitude
                    if self.calibrating {
                        self.all_calibration_amplitudes[idx][self.calibration_timer] = amplitude
                    }
                    // print("bin: \(i) \t freq: \(frequency)\t ampl.: \(amplitude)")
                }
                // print("Calibrated: \(self.calibrated_frequency)")
                
                if self.calibrating && self.calibration_timer == 199 {
                    self.calibrating = false
                    for i in 0...(SW_WINDOW - 1) {
                        // Get the median calibration frequencies
                        self.calibrated_amplitudes[i] = self.all_calibration_amplitudes[i].sorted(by: <)[100]
                    }
                } else if self.calibrating {
                    self.calibration_timer += 1
                } else if self.waiting_timer < 100 {
                    self.waiting_timer += 1
                } else {
                    var difference = [Double](repeating: 0, count: SW_WINDOW)
                    var pulling = false
                    var pushing = false
                    for i in 0...(SW_WINDOW - 1) {
                        difference[i] = self.amplitudes[i] - self.calibrated_amplitudes[i]
                        let bin = i + center_bin - SW_WINDOW / 2
                        if difference[i] > 30 {
                            print("bin: \(bin)")
                            if 185 < bin && bin < 207  {
                                pulling = true
                            }
                            if 211 < bin && bin < 232 {
                                pushing = true
                            }
                        }
                    }
                    if (pulling && pushing) {
                        // Do nothing
                    } else if pulling {
                        self.gesture = "pulling"
                        self.waiting_timer = 0
                    } else if pushing {
                        self.gesture = "pushing"
                        self.waiting_timer = 0
                    } else {
                        self.gesture = "No gesture detected"
                        
                    }
                }
            }

            // Now do anything you like with the data
            // Be aware, though, that the amplitude is a negative number
            // the lower, the less input it represents
            // in my tests, the lowest number was around -260
            // Read more on Google about converting the negative
            // number to a positive

        })
    }
    
    func calibrate() {
        if self.playingTone {
            oscillator.stop()
            self.calibration_timer  = 0
            self.calibrating = true
            oscillator.start()
        } else {
            oscillator.start()
        }
        self.playingTone = true
    }
    
    func stop() {
    }
}

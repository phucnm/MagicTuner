//
//  ViewController.swift
//  MagicTuner
//
//  Created by Phuc Nguyen on 9/1/16.
//  Copyright © 2016 Phuc Nguyen. All rights reserved.
//

import UIKit
import AudioKit
import LTMorphingLabel
import GoogleMobileAds

class MainViewController: UIViewController {

    var uiTimer: NSTimer!
    let frequencyVarianceAcceptable: Double = 3.0
    
    @IBOutlet weak var bannerView: GADBannerView!
    @IBOutlet var frequencyLabel: LTMorphingLabel!
    @IBOutlet var noteNameWithSharpsLabel: LTMorphingLabel!
    @IBOutlet var audioInputPlot: EZAudioPlot!
    
    var mic: AKMicrophone!
    var tracker: AKFrequencyTracker!
    var silence: AKBooster!
    
    let noteFrequencies = [16.35,17.32,18.35,19.45,20.6,21.83,23.12,24.5,25.96,27.5,29.14,30.87]
    let noteNamesWithSharps = ["C", "C♯","D","D♯","E","F","F♯","G","G♯","A","A♯","B"]
    let noteNamesWithFlats = ["C", "D♭","D","E♭","E","F","G♭","G","A♭","A","B♭","B"]
    
    var lastFrequencies = [Double]()
    
    func setupPlot() {
        let plot = AKNodeOutputPlot(mic, frame: audioInputPlot.bounds)
        plot.plotType = .Rolling
        plot.shouldFill = true
        plot.shouldMirror = true
        plot.color = UIColor.redColor()
        plot.backgroundColor = UIColor.clearColor()
        audioInputPlot.addSubview(plot)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rateApp(self, immediatly: nil)
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        frequencyLabel.morphingEffect = .Evaporate
        noteNameWithSharpsLabel.morphingEffect = .Evaporate
        
        AKSettings.audioInputEnabled = true
        mic = AKMicrophone()
        //        tracker = AKFrequencyTracker(mic, minimumFrequency: 20, maximumFrequency: 20)
        tracker = AKFrequencyTracker(mic, hopSize: 10, peakCount: 10)
        silence = AKBooster(tracker, gain: 0)
        
        bannerView.adSize = kGADAdSizeSmartBannerPortrait
        bannerView.adUnitID = "ca-app-pub-8354756802921362/9106639930"
        bannerView.rootViewController = self
        let request = GADRequest()
        request.testDevices = ["20886fbbe1ed124b160546ed4750a65c", kGADSimulatorID]
        bannerView.loadRequest(request)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        AudioKit.output = silence
        setupPlot()
        
        startAnalysis()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        stopAnalysis()
    }
    
    func startAnalysis() {
        AudioKit.start()
        uiTimer = NSTimer.scheduledTimerWithTimeInterval(0.1, target: self, selector: #selector(MainViewController.updateUI), userInfo: nil, repeats: true)
    }
    
    func stopAnalysis() {
        AudioKit.stop()
        uiTimer.invalidate()
    }
    
    func updateUI() {
        if tracker.amplitude > 0.1 {
            //print("\(tracker.frequency) abc\(tracker.amplitude)")
            lastFrequencies.append(tracker.frequency)
            updateUIWithDetectedFrequency(tracker.frequency)
            
        } else {
            if lastFrequencies.count > 0 {
                let mostFreq = findMostOccurrence(lastFrequencies)
                //print(mostFreq)
                updateUIWithDetectedFrequency(mostFreq)
                lastFrequencies = [Double]()
            }
        }
//        amplitudeLabel.text = String(format: "%0.2f", tracker.amplitude)
    }
    
    func findMostOccurrence(freqs: [Double]) -> Double {
        var map = [Int : Int]()
        for freq in freqs {
            let intFreq = Int(freq)
            if let mapFreq = map[intFreq] {
                map[intFreq] = mapFreq + 1
            } else {
                map[intFreq] = 1
            }
        }
        
        var maxOccurFreq = 0
        var maxOccur = 0
        
        for key in map.keys {
            if maxOccur < map[key] {
                maxOccur = map[key]!
                maxOccurFreq = key
            }
        }
        
        return Double(maxOccurFreq)
    }
    
    func updateUIWithDetectedFrequency(frequency: Double) {
        frequencyLabel.text = String(format: "%0.1f Hz", tracker.frequency)
        
        var frequency = Float(tracker.frequency)
        while (frequency > Float(noteFrequencies[noteFrequencies.count-1])) {
            frequency = frequency / 2.0
        }
        while (frequency < Float(noteFrequencies[0])) {
            frequency = frequency * 2.0
        }
        
        var minDistance: Float = 10000.0
        var index = 0
        
        for i in 0..<noteFrequencies.count {
            let distance = fabsf(Float(noteFrequencies[i]) - frequency)
            if (distance < minDistance){
                index = i
                minDistance = distance
            }
        }
        let octave = Int(log2f(Float(tracker.frequency) / frequency))
        noteNameWithSharpsLabel.text = "\(noteNamesWithSharps[index])\(octave)"
//        noteNameWithFlatsLabel.text = "\(noteNamesWithFlats[index])\(octave)"
    }

    @IBAction func infoTapped(sender: AnyObject) {
        let alert = UIAlertController(title: "Info", message: "phucnguyenpr@gmail.com", preferredStyle: .Alert)
        
        let ok = UIAlertAction(title: "OK", style: .Cancel) { _ in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
        
        alert.addAction(ok)
        
        presentViewController(alert, animated: true, completion: nil)
    }
    
}


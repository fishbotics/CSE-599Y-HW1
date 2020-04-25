//
//  ContentView.swift
//  Mobile Systems Project 1
//
//  Created by Adam Fishman on 4/18/20.
//  Copyright © 2020 Adam Fishman. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @State var gesture = ""
    @EnvironmentObject var engine: AudioEngine

    var body: some View {
        VStack {
            if (!engine.playingTone) {
                Text("Adam's CSE 599Y Gesture Detection")
                    .font(.title)
                    .foregroundColor(Color.white)
            } else if engine.calibrating {
                Text("Calibrating")
            } else {
                Text(engine.gesture)
                    .font(.title)
                    .foregroundColor(Color.green)
            }
            Button(action: {
                self.calibrate()
            }) {
                if engine.playingTone {
                    Text("Recalibrate")
                } else {
                    Text("Start detection")
                    
                }
            }
        }
    }
    
    func calibrate() {
        self.engine.calibrate()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AudioEngine())
    }
}

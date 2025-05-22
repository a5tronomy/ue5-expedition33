//
//  UbaAgentHelperApp.swift
//  UbaAgentHelper
//
//  Created by Zack Neyland on 1/10/24.
//

import SwiftUI

@main
struct UbaAgentHelperApp: App {
    @State var isRunning = false
    var body: some Scene {
        MenuBarExtra {
            ContentView(status: $isRunning)
                .frame(width: 500, height: 500)
        } label: {
            HStack {
                let configuration = NSImage.SymbolConfiguration(pointSize: 16, weight: .light)
                    .applying(.init(hierarchicalColor: isRunning ? .green : .red))
                
                let image = NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: nil)
                let updateImage = image?.withSymbolConfiguration(configuration)
                
                Image(nsImage: updateImage!) // This works.
                
                //                    let font = NSFont.systemFont(ofSize: 16, weight: .light)
                //                let color = NSColor.red // Attempting to make the text red.
                //                    let attributes: [NSAttributedString.Key: Any] = [
                //                        .font: font,
                //                        .foregroundColor: color
                //                    ]
                
                //                    let attributedString = NSAttributedString(string: "Hello, world!", attributes: attributes)
                
                //                    Text(AttributedString(attributedString)) // This doesn't work.
            }
        }
        .menuBarExtraStyle(.window)
        
        //        MenuBarExtra("UbaAgent Helper")
        //            ) {
        //
        //                }
                WindowGroup {
                    ContentView(status: $isRunning)
                        .navigationTitle("UbaAgent Helper")
        
        
                }
    }
}

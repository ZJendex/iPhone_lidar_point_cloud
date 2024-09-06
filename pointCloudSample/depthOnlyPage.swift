//
//  depthOnlyPage.swift
//  pointCloudSample
//
//  Created by 朱江逸飞 on 9/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import Foundation
import SwiftUI
import MetalKit
import ARKit

struct HelloWorldView: View {
    var arProvider: ARProvider  // Pass the ARProvider to this view
    @State private var minDepth: Float = 0.0  // Minimum depth value (0 meters)
    @State private var maxDepth: Float = 8.0  // Maximum depth value (8 meters)
    
    var body: some View {
        VStack {
            Spacer()  // Push content towards the center vertically
            
            // The DepthView to display real-time depth data
            DepthView(arProvider: arProvider, minDepth: $minDepth, maxDepth: $maxDepth)
                .frame(height: 300)  // Adjust height of the DepthView to your preference
                .background(Color.black)  // Optional: background color to highlight the depth view
                .rotationEffect(Angle(degrees: 90))
            
            Spacer()  // Push content towards the center vertically
            VStack {
                        Text("Min Depth: \(String(format: "%.1f", minDepth)) m")
                        Slider(value: $minDepth, in: 0...maxDepth)  // Control the min depth
                        
                        Text("Max Depth: \(String(format: "%.1f", maxDepth)) m")
                        Slider(value: $maxDepth, in: minDepth...8)  // Control the max depth
                    }
                    .padding()

            Spacer()
        }
        .navigationTitle("Depth View in Gray Scale")
    }
}

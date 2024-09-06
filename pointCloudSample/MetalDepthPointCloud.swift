//
//  MetalDepthPointCloud.swift
//  pointCloudSample
//
//  Created by 朱江逸飞 on 9/6/24.
//  Copyright © 2024 Apple. All rights reserved.
//

import SwiftUI
import MetalKit
import ARKit

extension CVPixelBuffer {
    func toMTLTexture(device: MTLDevice) -> MTLTexture? {
        var texture: MTLTexture? = nil
        var textureCache: CVMetalTextureCache?
        
        // Create a texture cache
        CVMetalTextureCacheCreate(nil, nil, device, nil, &textureCache)
        
        let width = CVPixelBufferGetWidth(self)
        let height = CVPixelBufferGetHeight(self)
        
        // Create a Metal texture from the pixel buffer
        var cvMetalTexture: CVMetalTexture?
        CVMetalTextureCacheCreateTextureFromImage(nil, textureCache!, self, nil, .r32Float, width, height, 0, &cvMetalTexture)
        
        if let cvMetalTexture = cvMetalTexture {
            texture = CVMetalTextureGetTexture(cvMetalTexture)
        }
        
        return texture
    }
}

final class DepthCoordinator: NSObject, MTKViewDelegate {
    var arProvider: ARProvider
    var pipelineState: MTLRenderPipelineState!
    var commandQueue: MTLCommandQueue!
    var samplerState: MTLSamplerState!
    
    init(arProvider: ARProvider) {
        self.arProvider = arProvider
        super.init()
        setupMetal()
    }
    
    func setupMetal() {
        guard let device = MTLCreateSystemDefaultDevice() else { return }
        
        // Set up the Metal pipeline
        let library = device.makeDefaultLibrary()
        let vertexFunction = library?.makeFunction(name: "vertexShader")
        let fragmentFunction = library?.makeFunction(name: "depthFragmentShader")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipelineDescriptor.depthAttachmentPixelFormat = .depth32Float
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            fatalError("Unable to create pipeline state: \(error)")
        }
        
        commandQueue = device.makeCommandQueue()
        
        // Set up the sampler descriptor
        let samplerDescriptor = MTLSamplerDescriptor()
        samplerDescriptor.minFilter = .linear
        samplerDescriptor.magFilter = .linear
        samplerDescriptor.sAddressMode = .clampToEdge
        samplerDescriptor.tAddressMode = .clampToEdge

        // Create the sampler state
        samplerState = device.makeSamplerState(descriptor: samplerDescriptor)
    }
    
    func draw(in view: MTKView) {
        guard let currentDrawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else { return }
        
        // Get the depth data from ARProvider
        guard let depthPixelBuffer = arProvider.lastArData?.depthImage else { return }
        
        // Convert CVPixelBuffer to Metal texture
        guard let depthTexture = depthPixelBuffer.toMTLTexture(device: view.device!) else { return }
        
        // Create a command buffer and a render command encoder
        let commandBuffer = commandQueue.makeCommandBuffer()
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(pipelineState)
        
        // Set the depth texture for the fragment shader
        renderEncoder?.setFragmentTexture(depthTexture, index: 0)
        renderEncoder?.setFragmentSamplerState(samplerState, index: 0)
        
        // Draw a full-screen quad to render the depth data
        renderEncoder?.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        renderEncoder?.endEncoding()
        commandBuffer?.present(currentDrawable)
        commandBuffer?.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resizing if necessary
    }
}

struct DepthView: UIViewRepresentable {
    var arProvider: ARProvider
    
    func makeCoordinator() -> DepthCoordinator {
        return DepthCoordinator(arProvider: arProvider)
    }
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.device = MTLCreateSystemDefaultDevice()
        mtkView.delegate = context.coordinator
        mtkView.clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 1.0) // Black background
        mtkView.colorPixelFormat = .bgra8Unorm // Default color format
        mtkView.depthStencilPixelFormat = .depth32Float // Depth format
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Update view if necessary
    }
}

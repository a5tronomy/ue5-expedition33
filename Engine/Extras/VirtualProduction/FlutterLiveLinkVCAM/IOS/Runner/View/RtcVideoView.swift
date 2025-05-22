// Copyright Epic Games, Inc. All Rights Reserved.

import Foundation
import MetalKit
import WebRTC

/**
 Native implementation of the Flutter RtcVideoView.
 Listens to a FlutterRtcVideoViewController and displays the associated video track.
 */
class RtcVideoView: NSObject {
  /// The view rendered to the screen.
  let videoView = RTCMTLVideoView()
  
  /// Display link used to set the desired refresh rate.
  private var refreshRateHint : CADisplayLink?
  
  /// The current track to display.
  private var track: RTCVideoTrack?
  
  init(
    frame: CGRect,
    viewId: Int64,
    creationParams: Dictionary<String, Any?>,
    messenger: FlutterBinaryMessenger?
  ) {
    super.init()
    
    videoView.backgroundColor = UIColor.clear
    videoView.videoContentMode = .scaleAspectFit
    videoView.isEnabled = true
    videoView.isHidden = false
    
    setRefreshRateFps(fps: 60)
    
    guard let controllerId: Int64 = creationParams["controllerId"] as? Int64 else {
      fatalError("No/invalid controller ID provided")
    }
    
    guard let controller = FlutterRtcVideoViewControllerApi
      .instance?
      .videoViewControllerManager
      .get(id: controllerId) else {
      fatalError("Controller #\(controllerId) does not exist")
    }
    
    controller.track?.add(videoView)
    controller.addListener(listener: self)
  }
  
  deinit {
    resetRefreshRateFps()
  }
  
  private func setRefreshRateFps(fps: Int) {
      self.resetRefreshRateFps()
      
      // Attempt to force the display refresh rate to the 60-120hz range for WebRTC video streaming (it seems iOS does not auto detect the rate of received frames and adjust)
      self.refreshRateHint = CADisplayLink(target: self, selector: #selector(refreshRateCallback))
      self.refreshRateHint?.preferredFrameRateRange = CAFrameRateRange(minimum: Float(fps), maximum: Float(fps), preferred: Float(fps))
      self.refreshRateHint?.add(to: .main, forMode: .common)
      
      for subview in videoView.subviews {
        if let mtlView = subview as? MTKView {
            mtlView.preferredFramesPerSecond = fps
        }
      }
  }
  
  @objc func refreshRateCallback(_ displayLink: CADisplayLink) {
    videoView.renderFrame(nil)
  }
  
  private func resetRefreshRateFps() {
      self.refreshRateHint?.remove(from: .main, forMode: .common)
      self.refreshRateHint?.invalidate()
      self.refreshRateHint = nil
  }
}

extension RtcVideoView: FlutterPlatformView {
  func view() -> UIView {
    return videoView
  }
}

extension RtcVideoView: FlutterRtcVideoViewControllerListener {
  func videoViewController(didChangeVideoTrack track: RTCVideoTrack?) {
    self.track?.remove(videoView)
    self.track = track
    track?.add(videoView)
    
    videoView.renderFrame(nil)
  }
}

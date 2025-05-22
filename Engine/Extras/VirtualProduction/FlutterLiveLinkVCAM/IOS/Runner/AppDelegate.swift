// Copyright Epic Games, Inc. All Rights Reserved.

import UIKit
import Flutter
import WebRTC

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  var peerConnectionApi: FlutterRtcPeerConnectionApi?
  var dataChannelApi: FlutterRtcDataChannelApi?
  var videoViewControllerApi: FlutterRtcVideoViewControllerApi?
  var arSessionApi: FlutterArSessionApi?
  var tentacleApi: FlutterTentacleApi?
  var gamepadApi: FlutterGamepadApi?
  
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    RTCInitializeSSL()
    
    GeneratedPluginRegistrant.register(with: self)
    
    // Register RtcVideoView platform view
    let videoViewRegistrar: FlutterPluginRegistrar? = self.registrar(forPlugin: "RtcVideoView")
    if (videoViewRegistrar == nil) {
      fatalError("Failed to register RtcVideoView plugin")
    }
    
    videoViewRegistrar?.register(
      RtcVideoViewFactory(
        messenger: videoViewRegistrar!.messenger()
      ),
      withId: "com.epicgames.live_link_vcam.view.RtcVideoView"
    )
    
    // Register Pigeon APIs
    let binaryMessenger = (window?.rootViewController as! FlutterViewController).binaryMessenger
    
    peerConnectionApi = FlutterRtcPeerConnectionApi(binaryMessenger: binaryMessenger)
    dataChannelApi = FlutterRtcDataChannelApi(binaryMessenger: binaryMessenger)
    videoViewControllerApi = FlutterRtcVideoViewControllerApi(binaryMessenger: binaryMessenger)
    arSessionApi = FlutterArSessionApi(binaryMessenger: binaryMessenger)
    tentacleApi = FlutterTentacleApi(binaryMessenger: binaryMessenger)
    gamepadApi = FlutterGamepadApi(binaryMessenger: binaryMessenger)
  
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
  
  override func applicationWillTerminate(_ application: UIApplication) {
    peerConnectionApi?.disposeAll()
  }
}

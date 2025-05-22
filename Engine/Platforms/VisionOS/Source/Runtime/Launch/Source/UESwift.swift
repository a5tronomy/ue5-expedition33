import SwiftUI
import CompositorServices

struct SwiftUIView: View {
	var onClick: () -> Void = {}

	@Environment(\.openImmersiveSpace) var openImmersiveSpace

	@State private var buttonDisabled = false

	func Open()
	{
		Task
		{
			buttonDisabled = true
			await openImmersiveSpace(id: "ImmersiveSpace")
		}
	}
	
	let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
	
	var body: some View {
		
	VStack(spacing: 8) {
	  Text("SwiftUI in Unreal!")
		.font(.title)
		.bold()
	  Button(action: {
		Open()
//		onClick()
	  }
	  , label: {
		  Text("Test Button")
		})
		.disabled(buttonDisabled)

	}
	.onReceive(timer) { t2 in
		print("timer!")
		timer.upstream.connect().cancel()
		Open()
	}
  }
}

struct UEContentConfiguration: CompositorLayerConfiguration {
	func makeConfiguration(
		capabilities: LayerRenderer.Capabilities,
		configuration: inout LayerRenderer.Configuration
	)
	{
		/*
		//let supportsFoveation = capabilites.supportsFoveation
		//let supportedLayouts = supportedLayouts(options: supportsFoveation ? [.foveationEnabled] : [])
		let supportedColorFormats = capabilities.supportedColorFormats
		let supportedDepthFormats = capabilities.supportedDepthFormats
		print("Supported Color Formats: ")
		supportedColorFormats.forEach { colorFormat in
			print(colorFormat.rawValue)
		}
		print("Supported Depth Formats: ")
		supportedDepthFormats.forEach { depthFormat in
			print(depthFormat.rawValue)
		}
		*/
		
		configuration.layout = .shared
		//configuration.layout = .dedicated // separate texture for each eye.  We may need to switch when we implement foveated rendering.
		configuration.isFoveationEnabled = false
		
		// HDR support // Might want to switch based on project settings.
		//configuration.colorFormat = .rgba16Float
		configuration.colorFormat = .bgra8Unorm_srgb
		
		//configuration.depthFormat = .depth32Float  			//PF_R32_FLOAT   			// This is correct for mobile forward
		configuration.depthFormat = .depth32Float_stencil8 		//PF_DepthStencil   // This is correct for deferred
//PFSWITCH
		
		configuration.defaultDepthRange = [Float.greatestFiniteMagnitude, 0.1]
	}
}

// unused at the moment, but this is how UE can open a SwiftUI view form the Obj-C side
class HostingViewFactory: NSObject
{
	static var onStartImmersive: (LayerRenderer) -> Void = { layer in }

	@objc static func MakeSwiftUIView(OnClick: @escaping (() -> Void)) -> UIViewController
	{
	  return UIHostingController(rootView: SwiftUIView(onClick: OnClick))
	}
}

#if UE_USE_SWIFT_UI_MAIN

@main
struct UESwiftApp: App {
	
	@UIApplicationDelegateAdaptor(IOSAppDelegate.self) var delegate
	
	var body: some Scene
	{
		WindowGroup
		{
			SwiftUIView()
		}

		ImmersiveSpace(id: "ImmersiveSpace")
		{
			// this will make a CompositorLayer that can pull a Metal drawable out for UE to render to
			CompositorLayer(configuration: UEContentConfiguration())
			{
				// on button click, tell Unreal the layer is ready and can continue
				layerRenderer in
					FSwiftAppBootstrap.KickoffWithCompositingLayer(layerRenderer)
			}
		}
		//.upperLimbVisibility(.hidden)
		.upperLimbVisibility(.visible)
	}
}

#endif

//#Preview {
//    SwiftUIView()
//}

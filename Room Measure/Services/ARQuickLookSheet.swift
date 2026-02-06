import SwiftUI
import QuickLook

struct ARQuickLookSheet: UIViewControllerRepresentable {
    let usdzURL: URL
    @Environment(\.dismiss) private var dismiss
    
    func makeCoordinator() -> Coordinator {
        Coordinator(dismiss: dismiss, url: usdzURL)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let host = UIViewController()
        host.view.backgroundColor = .black
        
        let preview = QLPreviewController()
        preview.dataSource = context.coordinator
        preview.delegate = context.coordinator
        
        DispatchQueue.main.async {
            host.present(preview, animated: false)
        }
        return host
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    class Coordinator: NSObject, QLPreviewControllerDataSource, QLPreviewControllerDelegate {
        let url: URL
        let dismiss: DismissAction
        
        init(dismiss: DismissAction, url: URL) {
            self.dismiss = dismiss
            self.url = url
        }
        
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        
        func previewController(_ controller: QLPreviewController,
                               previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
        
        func previewControllerDidDismiss(_ controller: QLPreviewController) {
            dismiss()
        }
    }
}

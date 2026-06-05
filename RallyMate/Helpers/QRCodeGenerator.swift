import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit

enum QRCodeGenerator {
    private static let context = CIContext(options: [.useSoftwareRenderer: true])

    static func image(from string: String) -> Image? {
        guard !string.isEmpty else { return nil }

        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let output = filter.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

        if let cgImage = context.createCGImage(scaled, from: scaled.extent) {
            return Image(uiImage: UIImage(cgImage: cgImage))
        }

        return Image(uiImage: UIImage(ciImage: scaled))
    }
}

import AppKit
import CoreGraphics

func printDisplayModes() {
    let mainDisplay = CGMainDisplayID()
    guard let modes = CGDisplayCopyAllDisplayModes(mainDisplay, nil) as? [CGDisplayMode] else { return }
    
    for mode in modes {
        let w = mode.width
        let h = mode.height
        let pw = mode.pixelWidth
        let ph = mode.pixelHeight
        let isHiDPI = (w != pw) || (h != ph)
        print("\(w)x\(h) (Pixel: \(pw)x\(ph)) HiDPI: \(isHiDPI)")
    }
}
printDisplayModes()

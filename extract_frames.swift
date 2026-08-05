import Foundation
import AVFoundation

let args = CommandLine.arguments
guard args.count >= 3 else {
    print("Usage: extract_frames <video_path> <output_dir>")
    exit(1)
}

let videoPath = args[1]
let outputDir = args[2]

let url = URL(fileURLWithPath: videoPath)
let asset = AVAsset(url: url)
let generator = AVAssetImageGenerator(asset: asset)
generator.appliesPreferredTrackTransform = true
generator.requestedTimeToleranceBefore = .zero
generator.requestedTimeToleranceAfter = .zero

let duration = CMTimeGetSeconds(asset.duration)
guard duration > 0, !duration.isNaN else {
    print("Invalid duration")
    exit(1)
}

let fm = FileManager.default
try? fm.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

// Extract a frame every 1 second
var times: [NSValue] = []
var t = 0.0
while t < duration {
    times.append(NSValue(time: CMTime(seconds: t, preferredTimescale: 600)))
    t += 1.0
}

let group = DispatchGroup()
var count = 0

generator.generateCGImagesAsynchronously(forTimes: times) { requestedTime, image, actualTime, result, error in
    defer { group.leave() }
    
    if let img = image, result == .succeeded {
        let seconds = Int(CMTimeGetSeconds(requestedTime))
        let path = "\(outputDir)/frame_\(seconds).jpg"
        let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL, "public.jpeg" as CFString, 1, nil)
        if let dest = dest {
            CGImageDestinationAddImage(dest, img, nil)
            CGImageDestinationFinalize(dest)
            count += 1
        }
    } else if let error = error {
        print("Error at \(CMTimeGetSeconds(requestedTime)): \(error)")
    }
}

for _ in times {
    group.enter()
}
group.wait()

print("Extracted \(count) frames to \(outputDir)")

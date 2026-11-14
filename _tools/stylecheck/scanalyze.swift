// Analyzes the shots of the StyleCheck window. Using the geometry from the window report it crops the sections and
// measures what can be checked without eyes:
//   fill    - the filled part of a progress bar: the longest row of saturated pixels against the bar width;
//   busy    - the indeterminate bar in each frame: the length of the moving segment and its start, in points;
//   visible - the visible size of a control in points: the rows and columns with pixels unlike the section background.
// Arguments: the window report, a directory for the crops, the window shots in order (at least one)
import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct Rect {
    var x, y, w, h: Int
}

final class Bitmap {
    let image: CGImage
    let width: Int
    let height: Int
    var pixels: [UInt8]

    init?(path: String) {
        guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else { return nil }

        self.image = image
        width = image.width
        height = image.height
        pixels = [UInt8](repeating: 0, count: image.width * image.height * 4)

        let (w, h) = (width, height)
        pixels.withUnsafeMutableBytes { buffer in
            let context = CGContext(data: buffer.baseAddress, width: w, height: h, bitsPerComponent: 8, bytesPerRow: w * 4,
                                    space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            context?.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
        }
    }

    func rgb(_ x: Int, _ y: Int) -> (Double, Double, Double) {
        let i = (min(max(y, 0), height - 1) * width + min(max(x, 0), width - 1)) * 4
        return (Double(pixels[i]) / 255, Double(pixels[i + 1]) / 255, Double(pixels[i + 2]) / 255)
    }

    func accent(_ x: Int, _ y: Int) -> Bool {
        let (red, green, blue) = rgb(x, y)
        let high = max(red, green, blue), low = min(red, green, blue)
        return high > 0.25 && (high - low) / high > 0.35
    }

    func save(_ r: Rect, to path: String) {
        let area = CGRect(x: r.x, y: r.y, width: r.w, height: r.h).intersection(CGRect(x: 0, y: 0, width: width, height: height))

        guard let cropped = image.cropping(to: area),
              let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: path) as CFURL,
                                                                UTType.png.identifier as CFString, 1, nil) else { return }

        CGImageDestinationAddImage(destination, cropped, nil)
        CGImageDestinationFinalize(destination)
    }
}

func difference(_ a: (Double, Double, Double), _ b: (Double, Double, Double)) -> Double {
    max(abs(a.0 - b.0), abs(a.1 - b.1), abs(a.2 - b.2))
}

let args = CommandLine.arguments
guard args.count >= 4, let report = try? String(contentsOfFile: args[1], encoding: .utf8) else {
    print("usage: scanalyze report.txt outdir shot1.png [shot2.png ...]")
    exit(1)
}

let outdir = args[2]
let shots = args[3...].compactMap { Bitmap(path: $0) }

guard let first = shots.first else {
    print("no readable shots")
    exit(1)
}

try? FileManager.default.createDirectory(atPath: outdir, withIntermediateDirectories: true)

var scale = 2.0
var top = 0.0
var rects: [(name: String, rect: Rect)] = []

for line in report.split(separator: "\n") {
    let fields = line.split(separator: " ")

    if line.hasPrefix("stylecheck ready") {
        for field in fields {
            let pair = field.split(separator: "=")
            if pair.count == 2, pair[0] == "scale" { scale = Double(pair[1]) ?? scale }
            if pair.count == 2, pair[0] == "top" { top = Double(pair[1]) ?? top }
        }
    } else if fields.count == 7, fields[1] == "rect", let x = Int(fields[3]), let y = Int(fields[4]),
              let w = Int(fields[5]), let h = Int(fields[6]) {
        rects.append((String(fields[2]), Rect(x: x, y: y, w: w, h: h)))
    }
}

// the report gives points from the window content, a shot is in pixels from the window frame
func pixels(_ r: Rect, margin: Int = 0) -> Rect {
    Rect(x: Int(Double(r.x - margin) * scale), y: Int((top + Double(r.y - margin)) * scale),
         w: Int(Double(r.w + 2 * margin) * scale), h: Int(Double(r.h + 2 * margin) * scale))
}

func pad(_ name: String) -> String {
    name.padding(toLength: 22, withPad: " ", startingAt: 0)
}

func points(_ value: Int) -> String {
    String(format: "%.1f", Double(value) / scale)
}

// the longest continuous row of saturated pixels: (length, start) in pixels
func longestRun(_ bitmap: Bitmap, _ r: Rect) -> (Int, Int) {
    var best = (0, 0)

    for y in r.y ..< r.y + r.h {
        var start = -1

        for x in r.x ... r.x + r.w {
            if x < r.x + r.w && bitmap.accent(x, y) {
                if start < 0 { start = x }
            } else if start >= 0 {
                if x - start > best.0 { best = (x - start, start - r.x) }
                start = -1
            }
        }
    }

    return best
}

// the background is sampled left of the control, outside its rectangle but inside the section
func visible(_ r: Rect) -> (Double, Double) {
    let background = first.rgb(r.x - Int(4 * scale), r.y + r.h / 2)
    var (left, right, upper, lower) = (Int.max, Int.min, Int.max, Int.min)

    for y in r.y ..< r.y + r.h {
        for x in r.x ..< r.x + r.w where difference(first.rgb(x, y), background) > 0.03 {
            left = min(left, x)
            right = max(right, x)
            upper = min(upper, y)
            lower = max(lower, y)
        }
    }

    if left > right {
        return (0, 0)
    }

    return (Double(right - left + 1) / scale, Double(lower - upper + 1) / scale)
}

first.save(Rect(x: 0, y: 0, w: first.width, h: first.height), to: "\(outdir)/window.png")

for (name, rect) in rects {
    if name.hasPrefix("sc_group_") {
        first.save(pixels(rect, margin: 4), to: "\(outdir)/\(name).png")
        continue
    }

    if ["sc_table", "sc_tree", "sc_list"].contains(name) {
        first.save(pixels(rect, margin: 2), to: "\(outdir)/\(name).png")
        continue
    }

    if name.contains("_pb_") {
        let area = pixels(rect)

        if name.hasSuffix("busy") {
            let runs = shots.map { shot -> String in
                let (length, start) = longestRun(shot, area)
                return "\(points(length))@\(points(start))"
            }
            print("busy    \(pad(name)) " + runs.joined(separator: "  "))
        } else {
            print("fill    \(pad(name)) " + String(format: "%.2f", Double(longestRun(first, area).0) / Double(area.w)))
        }

        continue
    }

    // the focus ring is drawn outside the edit, so the focused edit gets a margin
    let margin = name == "sc_edit_focused" ? 6 : 0
    let (w, h) = visible(pixels(rect, margin: margin))
    print("visible \(pad(name)) " + String(format: "%5.1f x %4.1f   (widget %d x %d)", w, h, rect.w, rect.h))
}

#!/usr/bin/env python3
"""Execute the production Swift geometry with Foundation on a macOS runner."""
from pathlib import Path
import subprocess
import tempfile

root = Path(__file__).resolve().parents[2]
source = (root / 'submodules/TelegramUI/Components/AudioWaveformComponent/Sources/AudioWaveformComponent.swift').read_text()
geometry = source.split('// BEGIN PEARL WAVEFORM GEOMETRY\n', 1)[1].split('// END PEARL WAVEFORM GEOMETRY', 1)[0]
harness = r'''
func check(_ samples: [UInt16], count: Int, trailingByte: Bool = false) {
    var bytes = samples.withUnsafeBytes { Data($0) }
    if trailingByte { bytes.append(255) }
    let actual = pearlWaveformSampleHeights(samples: bytes, count: count)
    if count <= 0 {
        precondition(actual.isEmpty)
        return
    }
    // Independent reference: for each output column, find its input samples.
    let maximum = CGFloat(samples.max() ?? 0)
    let expected: [CGFloat] = (0..<count).map { column in
        let peak = samples.enumerated().filter { $0.offset * count / max(1, samples.count) == column }.map { $0.element }.max() ?? 0
        return min(18.0, CGFloat(peak) * 18.0 / max(1.0, maximum))
    }
    precondition(actual.count == expected.count)
    for (a, b) in zip(actual, expected) {
        precondition(a.isFinite && a >= 0 && a <= 18.0)
        precondition(abs(a - b) < 0.000001)
    }
}
let cases: [[UInt16]] = [[], [0], [65535], [0, 65535, 1], [10, 20, 30, 20, 10]]
for count in [-1, 0, 1, 2, 25, 80, 160] {
    for samples in cases {
        check(samples, count: count)
        check(samples, count: count, trailingByte: true)
    }
}
var seed: UInt64 = 42
for iteration in 0..<500 {
    var samples: [UInt16] = []
    for _ in 0..<(iteration % 211) {
        seed = seed &* 6364136223846793005 &+ 1
        samples.append(UInt16(truncatingIfNeeded: seed >> 32))
    }
    check(samples, count: 1 + iteration % 120, trailingByte: iteration % 2 == 0)
}
print("PASS: production waveform geometry, 570 boundary/randomized cases; no UI/FPS claim")
'''
with tempfile.TemporaryDirectory(prefix='pearl-waveform-') as directory:
    test = Path(directory) / 'main.swift'
    test.write_text('import Foundation\n' + geometry + '\n' + harness)
    subprocess.run(['xcrun', 'swift', str(test)], check=True)

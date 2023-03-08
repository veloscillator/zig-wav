# zig-wav

Simple, efficient wav decoding + encoding in Zig.

![CI](https://github.com/veloscillator/zig-wav/actions/workflows/build.yml/badge.svg)


## Features

- Read and write wav files.
- Convert samples to desired type while reading to avoid extra steps.
- Focus on performance and flexibility.
- Fail gracefully on bad input.


## Usage

`zig-wav` may require a recent nightly build of Zig.

Add `zig-wav` to your `build.zig.zon`:
```zig
.{
    .name = "your-project",
    .version = "0.0.1",
    .dependencies = .{
        .wav = .{
            .url = "https://github.com/veloscillator/zig-wav/archive/<LATEST GIT COMMIT ID>.tar.gz",
            .hash = "<SHA2 HASH>",
        }
    },
}
```
`zig build` will tell you the right sha2 if you guess wrong.

Add to your `build.zig`:
```zig
const wav_mod = b.dependency("wav", .{ .target = target, .optimize = optimize }).module("wav");
exe.addModule("wav", "wav_mod");
```


### Decoding

```zig
const std = @import("std");
const wav = @import("wav");

pub fn main() !void {
    var file = try std.fs.cwd().openFile("boom.wav", .{});
    defer file.close();

    var buf_reader = std.io.bufferedReader(file.reader());
    var decoder = try wav.decoder(buf_reader.reader());

    var data: [64]f32 = undefined;
    while (true) {
        // Read samples as f32. Channels are interleaved.
        const samples_read = try decoder.read(f32, &data);

        // < ------ Do something with samples in data. ------ >

        if (samples_read < data.len) {
            break;
        }
    }
}
```

### Encoding

```zig
const std = @import("std");
const wav = @import("wav");

/// Generate mono wav file that plays 10 second sine wave.
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const alloc = gpa.allocator();

    var file = try std.fs.cwd().createFile("givemeasine.wav", .{});
    defer file.close();

    const sample_rate: usize = 44100;
    const num_channels: usize = 1;
    
    var data = try alloc.alloc(f32, 10 * sample_rate);
    defer alloc.free(data);

    generateSine(@intToFloat(f32, sample_rate), data);

    // Write out samples as 16-bit PCM int.
    var encoder = try wav.encoder(i16, file.writer(), file.seekableStream(), sample_rate, num_channels);
    try encoder.write(f32, data);
    try encoder.finalize(); // Don't forget to finalize after you're done writing.
}

/// Naive sine with pitch 440Hz.
fn generateSine(sample_rate: f32, data: []f32) void {
    const radians_per_sec: f32 = 440.0 * 2.0 * std.math.pi;
    var i: usize = 0;
    while (i < data.len) : (i += 1) {
        data[i] = 0.5 * std.math.sin(@intToFloat(f32, i) * radians_per_sec / sample_rate);
    }
}
```


## Demo

See `zig-soundio` for a playable demo (currently Window/macOS only):
```bash
git clone --recurse https://github.com/veloscillator/zig-soundio.git
cd zig-soundio
zig build demo-wav -- path/to/file.wav
```


## Future Work

- [ ] Handle `WAVFORMATEXTENSIBLE` format code https://msdn.microsoft.com/en-us/library/ms713497.aspx
- [ ] Handle 32-bit aligned i24.
- [ ] Add dithering option to deal with quantization error.
- [ ] Compile to big-endian target.
- [ ] Handle big-endian wav files.
- [ ] Encode/decode metadata via `LIST`, `INFO`, etc. chunks.

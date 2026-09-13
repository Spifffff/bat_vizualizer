# BatViz

A Windows desktop app for viewing and analyzing bat echolocation recordings. BatViz loads 192 kHz WAV files, shows
a waveform and a color spectrogram side by side, and lets you play back, zoom, export and (via the bundled BatIdent
tool) identify bat species in your recordings.

![BatViz main window showing waveform and spectrogram](docs/screenshots/main-window.png)

## Features

- Waveform and spectrogram view of WAV recordings, with independent zoom and cursor placement
- Playback with adjustable speed / time-expansion and gain, applied live during playback
- Multiple spectrogram color schemes: Viridis, Inferno, Magma, Plasma, Cividis, Mako, Rocket, Spectral, Turbo, Hot
  and grayscale (normal and inverted)
- Export the current view as a PNG (waveform, spectrogram, or both combined)
- Export a zoomed selection as an MP3 (via LAME)
- **BatIdent**: a Windows GUI front-end for [BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer),
  running batch species identification over a folder of recordings, with results shown per file and per species,
  and translated common names (Dutch, English, German, French, Spanish)

## For users

### Requirements

- Windows (32-bit application)
- [VLC media player](https://www.videolan.org/vlc/) installed, for audio playback (BatViz looks for `libvlc.dll` in
  the standard VLC install locations)
- `lame_enc.dll` next to `BatViz.exe`, only needed for MP3 export (already included in the [release](../release)
  folder; otherwise download from [lame.buanzo.org](https://lame.buanzo.org/#lamewindl))
- For species identification: a working install of
  [BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer) (Python + `bat_ident.py`)

### Installation

1. Download the latest release, or grab the prebuilt binaries from the [release](../release) folder.
2. Keep `BatViz.exe`, `BatIdent.exe`, `lame_enc.dll` and the `resources` folder together in the same directory.
3. Install VLC if you don't already have it, so playback works.
4. Run `BatViz.exe`.

### Usage

- **Open a file**: use File > Open (or drag a WAV file onto the window) to load a recording. The waveform appears
  on top, the spectrogram below.
- **Zoom and navigate**: select a region on the waveform to zoom the spectrogram into that range; use the
  transport controls to move between files in a folder.
- **Playback**: press play to hear the recording; adjust time-expansion (speed) and gain, which apply
  immediately even while playing.
- **Color scheme**: pick a spectrogram color scheme from the toolbar/menu to suit the recording or your preference.
- **Export**:
  - Save the current waveform, spectrogram, or both as a PNG.
  - Save the current zoomed selection as an MP3.
- **Identify species**: open BatIdent, point it at a folder of recordings and your BattyBirdNET-Analyzer
  installation, and run the analysis. Results (species, confidence, counts) are shown per file, with common names
  translated to your selected language.

![BatIdent results after analyzing a folder of recordings](docs/screenshots/batident.png)

## For developers

### Tech stack

- Delphi (VCL, Win32), developed with Delphi 12
- [LibVLC](https://www.videolan.org/vlc/) for audio playback, bound dynamically at runtime (see
  [LibVLC.pas](LibVLC.pas))
- [LAME](https://lame.sourceforge.io/) for MP3 encoding (see [Mp3Writer.pas](Mp3Writer.pas))
- BatIdent is a GUI wrapper around [BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer)'s
  `bat_ident.py`, which it drives as an external process from [BatIdentForm.pas](BatIdentForm.pas)

### Project structure

| File | Purpose |
|---|---|
| [BatViz.dpr](BatViz.dpr) | Entry point for the main viewer application |
| [BatIdent.dpr](BatIdent.dpr) | Entry point for the standalone species identification tool |
| [MainForm.pas](MainForm.pas) | Main viewer window: file handling, zoom, playback, export |
| [BatIdentForm.pas](BatIdentForm.pas) | BatIdent UI: folder selection, analysis options, results |
| [BusyForm.pas](BusyForm.pas) | Modal busy indicator shown during longer operations |
| [WavReader.pas](WavReader.pas) | WAV file parsing and sample access |
| [FFT.pas](FFT.pas) | Fast Fourier transform used to build the spectrogram |
| [Spectrogram.pas](Spectrogram.pas) | Spectrogram computation and color mapping |
| [SpectrogramPainter.pas](SpectrogramPainter.pas) | Renders the spectrogram bitmap |
| [WaveformPainter.pas](WaveformPainter.pas) | Renders the waveform bitmap |
| [WaveOutPlayer.pas](WaveOutPlayer.pas) | Audio playback via LibVLC |
| [Mp3Writer.pas](Mp3Writer.pas) | MP3 export via LAME |
| [PngExport.pas](PngExport.pas) | PNG export of waveform/spectrogram bitmaps |
| [BatSpeciesTranslations.pas](BatSpeciesTranslations.pas) | Species common-name translations |

### Building

1. Install Delphi 12 (or compatible) with the VCL Win32 platform.
2. Open `BatViz.dproj` (or `BatIdent.dproj`) in the Delphi IDE.
3. Build/Run. No third-party Delphi packages are required; LibVLC and LAME are loaded dynamically at runtime, not
   linked at compile time.
4. To test playback and MP3 export locally, make sure VLC is installed and `lame_enc.dll` sits next to the
   compiled exe.

### Contributing

Issues and pull requests are welcome. A few conventions used in this codebase:

- 2-space indentation, no manual alignment of adjacent lines
- Keep lines under 140 characters
- Prefer small, focused commits with a clear single-line message

## License

See [LICENSE](LICENSE) for details.

## Acknowledgments

- [VideoLAN VLC](https://www.videolan.org/vlc/) for audio playback
- [LAME](https://lame.sourceforge.io/) for MP3 encoding
- [BattyBirdNET-Analyzer](https://github.com/rdz-oss/BattyBirdNET-Analyzer) for bat species classification and the
  species/label data used for name translation

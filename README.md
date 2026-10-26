# Qt build tools and patches

Build scripts and patches we use to build Qt 6.8.5 ourselves and ship it with our apps on macOS and Windows. AnyToISO 4.0 and Macs Fan Control 1.5.23 use only this Qt version.

Copy the contents of this repository into the official Qt source tree (`qt-everywhere-src-6.8.5`, overwriting existing files) and run the script from there.

### macOS

Needs [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12). Qt is built universal (x86_64 + arm64) and installed into `/usr/local/Qt-6.8.5` unless another directory is given. The fixes the sources need on current macOS and Xcode are kept in `patches`, each with its reason and upstream origin in its header, and are applied by the script:

```sh
perl compile_mac.pl [install_dir] [--build-multimedia --ffmpeg-dir=DIR] [--build-pdf] [--build-graphs]
```

### Windows

Needs [VS2022 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/). Run one of the `compile_win_*.bat` wrappers or the script itself:

```sh
perl compile_win.pl amd64|x86 install_dir [--build-multimedia --ffmpeg-dir=DIR] [--build-pdf|--build-webengine] [--build-graphs]
```

QtNetwork is linked against openssl-3.0.13, pre-compiled in `_tools`; delete the extracted `openssl-*` folder and it will be compiled again.

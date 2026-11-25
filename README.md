# Qt build tools and patches

Build scripts and patches we use to build Qt 6.8.5 ourselves and ship it with our apps on macOS and Windows. AnyToISO 4.0 and Macs Fan Control 1.5.23 use only this Qt version.

Copy the contents of this repository into the official Qt source tree (`qt-everywhere-src-6.8.5`, overwriting existing files) and run the script from there.

### macOS

Needs [Xcode](https://apps.apple.com/us/app/xcode/id497799835?mt=12). Qt is built universal (x86_64 + arm64) and installed into `/usr/local/Qt-6.8.5` unless another directory is given. The fixes the sources need on current macOS and Xcode are kept in `patches`, each with its reason and upstream origin in its header, and are applied by the script in the order of their names; a patch may build on an earlier one, and its header says so:

```sh
perl compile_mac.pl [install_dir] [--build-multimedia --ffmpeg-dir=DIR] [--build-pdf] [--build-graphs]
```

[qt-mac-ui-test](https://github.com/crystalidea/qt-mac-ui-test) checks the QMacStyle patches on the built Qt: a window with the controls they change next to the same AppKit controls, and a script that shoots it in the light and dark appearance and measures the result.

### Windows

Needs [VS2022 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/). Our Windows builds are made with the [qt6windows7](https://github.com/crystalidea/qt6windows7) backport applied on top of the sources, which is what keeps them running on Windows 7, 8 and 8.1; copy that repository's folders over the Qt checkout before building. Run one of the `compile_win_*.bat` wrappers or the script itself:

```sh
perl compile_win.pl amd64|x86 install_dir [--build-multimedia --ffmpeg-dir=DIR] [--build-pdf|--build-webengine] [--build-graphs]
```

QtNetwork is linked against openssl-3.0.13, pre-compiled in `_tools`; delete the extracted `openssl-*` folder and it will be compiled again.

At the end of the build the release libraries of the installation are signed by `sign_qt_install.pl`, with the signtool wrapper from `%MY_COMMON%\deploy\bin`. Windows 11 with Smart App Control on refuses to load a library without a valid signature, which leaves the application without its Qt. The script takes the installation directory and can be run on its own — after a build that had no token in the reader, or on a Qt installed earlier; `--list` names the libraries it would sign and signs nothing:

```sh
perl sign_qt_install.pl install_dir [--list]
```

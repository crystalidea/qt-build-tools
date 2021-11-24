# Qt build tools and patches

This is a set of build tools and required patches to build Qt yourself and distribute it along with your app on macOS and Windows.

### macOS

For macOS we currently distribute two binaries:

- Modern, compiled with [Qt 5.15.7](5.15.7) for macOS 10.13+. If you do not own a commercial license, you can still use [Qt 5.15.2](5.15.2), the folder contains number of macOS-related patches (found in the Qt issues tracker) in order to be compiled and used normally on modern macOS versions (e.g. Big Sur or Monterey).

- Legacy, compiled with [Qt 5.6.3](5.6.3) for macOS 10.7-10.12. Qt contains number of patches (found in the Qt issues tracker) in order to be compiled and used normally. To compile Qt itself we used macOS 10.13 and XCode 8. 

Compiling your app with both modern and legacy Qt can be done on modern macOS (10.15 Catalina or 11 Big Sur) and [XCode 12](https://apps.apple.com/us/app/xcode/id497799835?mt=12).

### Windows

On Windows you need [VS2019 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/). QtNetwork module is compiled using openssl-1.1.1k which is pre-compiled but once you delete the folder, it will be compiled again.

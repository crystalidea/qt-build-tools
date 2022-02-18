# Qt build tools and patches

This is a set of build tools and required patches to build Qt yourself and distribute it along with your app on macOS and Windows.

### macOS

For macOS we currently distribute two binaries:

- Modern, compiled with [Qt 5.15.8](5.15.8) for macOS 10.13+. If you do not own a commercial license, you can still use [Qt 5.15.2](5.15.2), the folder contains number of mostly macOS-related patches already applied in order to be compiled and used normally on modern macOS versions (e.g. Big Sur or Monterey). 

- Legacy, compiled with [Qt 5.6.3](5.6.3) for macOS 10.7-10.12. The folder contains several macOS-related patches ([QTBUG-40583](https://bugreports.qt.io/browse/QTBUG-40583), [QTBUG-18624](https://bugreports.qt.io/browse/QTBUG-18624), [QTBUG-52536](https://bugreports.qt.io/browse/QTBUG-52536), [QTBUG-63451](https://bugreports.qt.io/browse/QTBUG-63451) ) already applied in order to be compiled and used normally. For compilation we use macOS 10.13 and XCode 8. 

To apply patches and compile Qt the same as we do, simply copy the contents of the folder ([Qt 5.15.2](5.15.2) or [Qt 5.6.3](5.6.3)) to the official Qt source tree (overwriting existing files of cause).

Compiling your app with both modern and legacy Qt can be done on modern macOS and [XCode 12](https://apps.apple.com/us/app/xcode/id497799835?mt=12) (not tried 13 just yet).

### Windows

On Windows you need [VS2019 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/). QtNetwork module is compiled using openssl-1.1.1k which is pre-compiled but once you delete the folder, it will be compiled again.

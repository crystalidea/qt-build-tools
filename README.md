# Qt build tools and patches

This is a set of build tools and required patches to build Qt yourself and distribute it along with your app on macOS and Windows.

### macOS

For macOS we currently distribute two binaries:

- Modern, compiled with [Qt 5.15.16](5.15.16) for macOS 10.13+. If you do not own a commercial license, you can use older [Qt 5.15.x](https://crystalidea.com/blog/qt-5-15-lts-commercial-source-code).

- Legacy, compiled with [Qt 5.6.3](5.6.3) for macOS 10.7-10.12. The folder contains several macOS-related patches ([QTBUG-40583](https://bugreports.qt.io/browse/QTBUG-40583), [QTBUG-18624](https://bugreports.qt.io/browse/QTBUG-18624), [QTBUG-52536](https://bugreports.qt.io/browse/QTBUG-52536), [QTBUG-63451](https://bugreports.qt.io/browse/QTBUG-63451) ) already applied in order to be compiled and used normally. To compile Qt 5.6.3 we use macOS 10.13 and XCode 8.

To apply patches and compile Qt the same as we do, simply copy the contents of the folder ([Qt 5.15.16](5.15.16) or [Qt 5.6.3](5.6.3)) to the official Qt source tree (overwriting existing files of cause).

Compiling your app with both modern and legacy Qt can be done on modern macOS with [XCode](https://apps.apple.com/us/app/xcode/id497799835?mt=12).

When compiling a project with Qt 5.6.3 on arm64 host machine some additional steps are required in your .pro file:

```bash
# compiler flags:
QMAKE_CXXFLAGS += "-arch x86_64"
QMAKE_CFLAGS += "-arch x86_64"
QMAKE_LFLAGS += "-arch x86_64"
# linker flags, required to support 10.7, otherwise minimum deployment target is 10.9
QMAKE_LFLAGS += "-stdlib=libc++"
```

### Windows

On Windows you need [VS2019 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/). QtNetwork module is compiled using openssl-1.1.1k which is pre-compiled but once you delete the folder, it will be compiled again.

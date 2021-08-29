# Qt build tools and patches

This is a set of build tools and required patches to build Qt yourself and distribute it along with your app.

For macOS we currently distribute two binaries:

- Modern, compiled with [Qt 5.15.2](5.15.2) for macOS 10.13+. Qt contains number of patches (found in the Qt issues tracker) in order to be compiled and used normally. If you own a commercial license it's recommended to use [Qt 5.15.5](5.15.5) where all those issues (and many others) were fixed already.

- Legacy, compiled with [Qt 5.6.3](5.6.3) for macOS 10.7-10.12. Qt contains number of patches (found in the Qt issues tracker) in order to be compiled and used normally. To compile Qt itself we used macOS 10.13 and XCode 8. 

Compiling your app with both modern and legacy Qt can be done on modern macOS (10.15 Catalina or 11 Big Sur) and [XCode 12](https://apps.apple.com/us/app/xcode/id497799835?mt=12).

On Windows you need [VS2019 Community Edition](https://visualstudio.microsoft.com/downloads/) and [Perl](https://strawberryperl.com/).


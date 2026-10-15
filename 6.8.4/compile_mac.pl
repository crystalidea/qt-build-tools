#!/usr/bin/perl
# macOS counterpart of compile_win.pl. Copy this folder into the Qt source root
# (qt-everywhere-src-6.8.4) and run it from there:
#
#   perl compile_mac.pl [install_dir] [--build-pdf] [--build-multimedia --ffmpeg-dir=DIR] [--build-graphs]
#
# install_dir defaults to /usr/local/Qt-<version>. Qt is built universal
# (x86_64 + arm64) against the SDK of the selected Xcode.
#
# FFmpeg for --build-multimedia comes from --ffmpeg-dir: a prefix with include/ and
# lib/ holding universal dylibs with @rpath install names - the 3rdParty
# _build/qt6-8/ffmpeg-qt prefix built by 3rdParty/_mac/ffmpeg.sh. The dylibs are
# installed into Qt's lib/ (QT_DEPLOY_FFMPEG): Qt 6.8 on macOS defaults to the
# ffmpeg backend and does not fall back to darwin when FFmpeg cannot be loaded,
# so without them QtMultimedia has no backend at all. From lib/ the plugin finds
# them and macdeployqt copies them into the app bundle.
#
# --build-pdf builds QtPdf out of qtwebengine after Qt itself is installed, the same
# way compile_win.pl does. It needs node.js, python3 with html5lib, gperf, bison
# and flex.
use strict;
use warnings;
use Cwd;
use File::Basename;
use File::Path qw(remove_tree);
use Getopt::Long;
use Time::HiRes qw(gettimeofday tv_interval);

# Start time
my $start_time = [gettimeofday];

my $ffmpeg_dir;
my $build_multimedia = 0;
my $build_graphs = 0;
my $build_pdf = 0;

GetOptions(
    'ffmpeg-dir=s'     => \$ffmpeg_dir,
    'build-multimedia' => \$build_multimedia,
    'build-graphs'     => \$build_graphs,
    'build-pdf'        => \$build_pdf,
) or die "Error in command line arguments\n";

# Define the modules to skip - the same set as compile_win.pl
my @skipped_modules = qw(
    qthttpserver qtlocation qtspeech qtgrpc qt3d qtactiveqt qtcharts qtcoap
    qtconnectivity qtdatavis3d qtdoc qtlottie qtmqtt qtnetworkauth qtopcua
    qtpositioning qtremoteobjects qtscxml qtsensors qtserialbus qtserialport
    qttranslations qtvirtualkeyboard qtwayland qtwebchannel qtwebengine
    qtwebsockets qtwebview qtquickeffectmaker qtquicktimeline qtquick3d
    qtquick3dphysics
);

push @skipped_modules, 'qtmultimedia' if (!$build_multimedia);
push @skipped_modules, 'qtgraphs' if (!$build_graphs);
push @skipped_modules, 'qtdeclarative' if (!$build_pdf);

# Subroutine to check if a command exists in PATH
sub command_exists {
    my ($cmd) = @_;
    my $output = `which $cmd 2>/dev/null`;
    return $? == 0;
}

# Subroutine to run a command and stream its output in real-time
sub run_command {
    my ($cmd) = @_;
    print "Running: $cmd\n";
    open(my $pipe, '-|', "$cmd 2>&1") or die "Error: Unable to execute '$cmd'.\n";
    while (my $line = <$pipe>) {
        print $line;
    }
    close($pipe);
    if ($? != 0) {
        die "Error: Command '$cmd' failed.\n";
    }
}

sub dir_is_empty {
    my ($dir) = @_;
    opendir(my $dh, $dir) or return 0;
    my @entries = grep { $_ ne '.' && $_ ne '..' } readdir($dh);
    closedir($dh);
    return !@entries;
}

# Replace $from with $to in $file. A file that already has $to is left alone, so
# re-running the script on the same source tree is fine; anything else means the
# sources are not the ones the patch was written for.
sub patch_source {
    my ($file, $from, $to) = @_;
    open(my $in, '<', $file) or die "Error: Unable to read '$file'.\n";
    my $text = do { local $/; <$in> };
    close($in);

    my $at = index($text, $from);
    if ($at < 0) {
        return if (index($text, $to) >= 0);
        die "Error: '$file' is not what the patch expects, check the patch in compile_mac.pl\n";
    }
    substr($text, $at, length($from)) = $to;

    open(my $out, '>', $file) or die "Error: Unable to write '$file'.\n";
    print $out $text;
    close($out);
    print "Patched $file\n";
}

die "Error: run this script from the Qt source root (no 'configure' / 'qtbase' here)\n"
    if (!-e "configure" || !-d "qtbase");

# Check for ninja
if (!command_exists('ninja')) {
    die "Error: 'ninja' is not installed or not in the PATH. You can use 'brew install ninja' command\n";
}

# Check for cmake
if (!command_exists('cmake')) {
    die "Error: 'cmake' is not installed or not in the PATH. You can use 'brew install cmake' command\n";
}

# QtPdf (Chromium) requirements - check them now rather than an hour into the build
if ($build_pdf) {
    foreach my $tool (qw(node python3 gperf bison flex)) {
        die "Error: '$tool' is required for --build-pdf but is not in the PATH\n" if (!command_exists($tool));
    }
    system("python3 -c 'import html5lib' 2>/dev/null") == 0
        or die "Error: --build-pdf needs html5lib: python3 -m pip install --user html5lib\n";

    # Chromium 122 (QtPdf) predates the macOS 15.4+ SDKs, whose system headers
    # define TARGET_OS_MAC everywhere, so two classic Mac OS branches now fire by
    # mistake: zlib turns fdopen into NULL, which breaks the SDK's own fdopen
    # declaration, and libpng includes the long gone <fp.h>. Apply what upstream
    # did - qtbase already ships the fixed zlib 1.3.1 and libpng 1.6.49.
    my $chromium = "qtwebengine/src/3rdparty/chromium/third_party";

    patch_source("$chromium/zlib/zutil.h", <<'FROM', <<'TO');
#if defined(MACOS) || defined(TARGET_OS_MAC)
#  define OS_CODE  7
#  ifndef Z_SOLO
#    if defined(__MWERKS__) && __dest_os != __be_os && __dest_os != __win32_os
#      include <unix.h> /* for fdopen */
#    else
#      ifndef fdopen
#        define fdopen(fd,mode) NULL /* No fdopen() */
#      endif
#    endif
#  endif
#endif
FROM
#if defined(MACOS)
#  define OS_CODE  7
#endif
TO

    patch_source("$chromium/libpng/pngpriv.h", <<'FROM', <<'TO');
#  include <float.h>

#  if (defined(__MWERKS__) && defined(macintosh)) || defined(applec) || \
    defined(THINK_C) || defined(__SC__) || defined(TARGET_OS_MAC)
   /* We need to check that <math.h> hasn't already been included earlier
    * as it seems it doesn't agree with <fp.h>, yet we should really use
    * <fp.h> if possible.
    */
#    if !defined(__MATH_H__) && !defined(__MATH_H) && !defined(__cmath__)
#      include <fp.h>
#    endif
#  else
#    include <math.h>
#  endif
FROM
#  include <float.h>

#  include <math.h>
TO
}

if ($build_multimedia) {
    die "Error: --ffmpeg-dir is required to build multimedia\n" if (!defined $ffmpeg_dir);
    die "Error: ffmpeg dir '$ffmpeg_dir' has no include/ and lib/\n"
        if (!-d "$ffmpeg_dir/include" || !-d "$ffmpeg_dir/lib");
}

my $current_dir = getcwd;
my $build_dir = "qt6-build";
my $pdf_build_dir = "qtwebengine-pdf-build";

# configure's default prefix is /usr/local/Qt-<version>, so this must match the
# version of the source tree the script is run from.
my $qt_version  = "6.8.4";
my $install_dir = $ARGV[0] // "/usr/local/Qt-$qt_version";

foreach my $dir ($build_dir, $pdf_build_dir) {
    die "Error: $dir already exists from the previous build\n" if (-d $dir);
}

# An empty install dir is what a previous failed run of this script leaves behind
if (-d $install_dir && !dir_is_empty($install_dir)) {
    die "Error: $install_dir already exists from the previous build\n";
}

# The SDK of the selected Xcode, so that the SDK and the compiler come from the
# same Xcode. A bare 'xcrun --show-sdk-path' may point at the CommandLineTools SDK.
my $sdk_path = `xcrun --sdk macosx --show-sdk-path`;
chomp $sdk_path;
die "Error: cannot locate the macOS SDK (xcrun --sdk macosx --show-sdk-path)\n" if (!-d $sdk_path);

# One sudo prompt up front instead of one at the end of a multi-hour build: create
# the install dir and hand it to the current user, so that every 'cmake --install'
# below runs unprivileged.
if (!-d $install_dir) {
    if (-w dirname($install_dir)) {
        mkdir $install_dir or die "Error: Unable to create '$install_dir'.\n";
    } else {
        my $user = getpwuid($<);
        print "Creating $install_dir (needs sudo)...\n";
        system("sudo", "mkdir", "-p", $install_dir) == 0 or die "Error: Unable to create '$install_dir'.\n";
        system("sudo", "chown", "$user:staff", $install_dir) == 0 or die "Error: Unable to chown '$install_dir'.\n";
    }
}

# CMake arguments shared by Qt itself and the QtPdf module build.
# NOTE: if CMAKE_OSX_ARCHITECTURES is empty, Qt is defaults to x86_64 on an arm64
# machine, which is not what described in the docs: https://doc.qt.io/qt-6/macos-building.html
# CMAKE_IGNORE_PREFIX_PATH hides Homebrew: an Intel Homebrew in /usr/local carries
# x86_64-only openssl / zstd / brotli, which configure would otherwise pick up -
# breaking the arm64 slice and making Qt depend on /usr/local/lib at runtime.
my @cmake_args = (
    '-DCMAKE_OSX_ARCHITECTURES="x86_64;arm64"',
    "-DCMAKE_OSX_SYSROOT=\"$sdk_path\"",
    '-DCMAKE_IGNORE_PREFIX_PATH="/usr/local;/opt/homebrew"',
    '-DBUILD_TESTING=OFF',
);

mkdir $build_dir or die "Error: Unable to create directory '$build_dir'.\n";
chdir $build_dir or die "Error: Unable to change directory to '$build_dir'.\n";

# Prepare the configuration command
my $skip_modules_string = join(' ', map { "-skip $_" } @skipped_modules);

my $configure_cmd = "../configure -prefix \"$install_dir\" $skip_modules_string -no-framework -no-openssl -- @cmake_args";
$configure_cmd .= " -DFFMPEG_DIR=\"$ffmpeg_dir\" -DQT_DEPLOY_FFMPEG=TRUE" if ($build_multimedia);

# Configure the build
print "Configuring the build...\n";
run_command($configure_cmd);

# Build Qt6
print "Building Qt6...\n";
run_command("cmake --build . --parallel");

# End time
my $end_time = [gettimeofday];
my $elapsed = tv_interval($start_time, $end_time);
# Convert elapsed time to mm:ss format
my $minutes = int($elapsed / 60);
my $seconds = $elapsed % 60;
# Format the output
printf("Compilation time: %02d:%02d\n", $minutes, $seconds);

print "Installing Qt6...\n";
run_command("cmake --install .");

chdir $current_dir or die "Error: Unable to change directory to '$current_dir'.\n";
remove_tree($build_dir);

if ($build_pdf) {
    print "Building QtPdf...\n";
    mkdir $pdf_build_dir or die "Error: Unable to create directory '$pdf_build_dir'.\n";
    chdir $pdf_build_dir or die "Error: Unable to change directory to '$pdf_build_dir'.\n";

    run_command("\"$install_dir/bin/qt-configure-module\" ../qtwebengine -- -DFEATURE_qtwebengine_build=OFF @cmake_args");
    run_command("cmake --build . --parallel");
    run_command("cmake --install .");

    chdir $current_dir or die "Error: Unable to change directory to '$current_dir'.\n";
    remove_tree($pdf_build_dir);
}

$elapsed = tv_interval($start_time, [gettimeofday]);
printf("Total time: %02d:%02d\n", int($elapsed / 60), $elapsed % 60);

print "Qt6 has been successfully built and installed to $install_dir.\n";

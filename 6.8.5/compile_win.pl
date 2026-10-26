# from https://wiki.qt.io/Building_Qt_Multimedia_with_FFmpeg
# FFmpeg for --build-multimedia comes from --ffmpeg-dir (preferred: the 3rdParty
# _build\ffmpeg-qt prefix, with include\ + lib\ + bin\) or, legacy, from --vcpkg-dir
# (vcpkg install ffmpeg[core,swresample,swscale,avdevice]:x64-windows).
#
# --build-webengine builds the whole qtwebengine module (QtWebEngine + QtPdf), so it
# supersedes --build-pdf, which builds QtPdf only. Both are amd64-only and require the
# extra host tools listed at https://doc.qt.io/qt-6/qtwebengine-platform-notes.html

use strict;
use Cwd;
use Path::Tiny;
use IPC::Cmd qw[can_run run];
use Getopt::Long;

# check requirements:
die "Cannot proceed without the '_tools' folder'" if (!-e "_tools");

my $current_dir = getcwd;
my $prefix_dir = path($current_dir)->parent(1); # one level up
$current_dir =~ s#/#\\#g; # convert separators to Windows-style
$prefix_dir =~ s#/#\\#g; # convert separators to Windows-style

my $arch = $ARGV[0];
my $install_dir = $ARGV[1];
my $vcpkg_dir;
my $ffmpeg_dir;
my $build_multimedia = 0;
my $build_graphs = 0;
my $build_pdf = 0;
my $build_webengine = 0;

GetOptions(
    'vcpkg-dir=s'    => \$vcpkg_dir,
    'ffmpeg-dir=s'   => \$ffmpeg_dir,
    'build-multimedia'   => \$build_multimedia,
    'build-graphs'   => \$build_graphs,
    'build-pdf'   => \$build_pdf,
    'build-webengine'   => \$build_webengine,
) or die "Error in command line arguments\n";

$arch = "amd64" if ($arch eq ''); # amd64 is nothing is specified, can be x86

die "Error: Please specify architecture (x86 or amd64)" if ($arch ne "x86" && $arch ne "amd64"); # die if user specified anything except x86 or amd64
die "Error: Please specify install dir as second parameter" if (!$install_dir);
die "Error: istall dir '$install_dir' already exists" if (-d $install_dir);

my $build_dir = "_qt6-build-$arch";

die "Error: build dir '$build_dir' already exists" if (-d $build_dir);

if ($arch eq 'x86')
{
    # This version of the script is not able to build x86 qtwebengine on a 64-bit machine"
    # need to override target_cpu='x86' somehow: https://www.chromium.org/developers/gn-build-configuration/

    print "Warning: qtwebengine is not built for x86, skipping --build-webengine\n" if ($build_webengine);
    print "Warning: qtpdf is not built for x86, skipping --build-pdf\n" if ($build_pdf);

    $build_pdf = 0;
    $build_webengine = 0;
}

# qtwebengine (unlike the QtPdf-only build) needs a couple of host tools that are not
# shipped in '_tools': https://doc.qt.io/qt-6/qtwebengine-platform-notes.html
if ($build_webengine)
{
    my $python = can_run('python') || can_run('python3');

    die "Error: python (3.8+) is required to build qtwebengine, but was not found in PATH" if (!$python);

    # a 'python3' found in PATH is often just the Microsoft Store stub, so actually run the
    # interpreter instead of trusting the file name - this checks both at once
    die "Error: '$python' cannot import html5lib, run 'python -m pip install html5lib'" if (!run(command => [$python, '-c', 'import html5lib']));

    die "Error: node.js (14+) is required to build qtwebengine, but was not found in PATH" if (!can_run('node'));

    # building the whole module already gives us QtPdf, no need for a second pass
    $build_pdf = 0;
}

if (defined $vcpkg_dir)
{
    $vcpkg_dir .= "\\installed\\x64-windows" if ($arch eq 'amd64');
    $vcpkg_dir .= "\\installed\\x86-windows" if ($arch eq 'x86');

    die "vcpkg dir $vcpkg_dir doesn't exist" if (!-e "$vcpkg_dir");
}

# FFmpeg prefix for the multimedia build: prefer an explicit --ffmpeg-dir (e.g. the
# 3rdParty _build\ffmpeg-qt prefix), else fall back to the vcpkg install dir. Qt's
# FindFFmpeg is pointed at it via -DFFMPEG_DIR below.
my $ffmpeg_prefix = defined $ffmpeg_dir ? $ffmpeg_dir : $vcpkg_dir;

die "either --ffmpeg-dir or --vcpkg-dir is required to build multimedia" if ($build_multimedia && !defined $ffmpeg_prefix);
die "ffmpeg dir '$ffmpeg_prefix' doesn't exist" if ($build_multimedia && !-e "$ffmpeg_prefix");

my $openssl_version = "3.0.13"; # supported until 7th September 2026
my $openssl_download = "https://www.openssl.org/source/openssl-$openssl_version.tar.gz";
my $openssl_arch = $arch eq "amd64" ? "WIN64A" : "WIN32";
my $openssl_dir = "$current_dir\\openssl-$openssl_version-$openssl_arch";
my $openssl_7z = "openssl-$openssl_version-$openssl_arch.7z";

# will create a batch file

my $batfile = 'compile_win.bat';

open BAT, '>', $batfile;

printLineToBat ("SET PATH=%PATH%;%cd%\\_tools;%cd%\\_tools\\cmake\\bin"); # add folders to the path for 7z, wget, cmake, etc
printLineToBat ("CALL \"C:\\Program Files\\Microsoft Visual Studio\\2022\\Community\\VC\\Auxiliary\\Build\\vcvarsall.bat\" $arch");
printLineToBat ("SET _ROOT=%cd%");
printLineToBat ("SET PATH=%_ROOT%\\qtbase\\bin;%_ROOT%\\gnuwin32\\bin;%PATH%"); # http://doc.qt.io/qt-5/windows-building.html
printLineToBat ("SET OPENSSL_LIBS=-lUser32 -lAdvapi32 -lGdi32 -llibcrypto -llibssl");

printLineToBat ("cd _tools");
printLineToBat ("7z x cmake.7z -aoa -y");

printLineToBat ("7z x $openssl_7z -o$openssl_dir -y") if (-e "_tools\\$openssl_7z");
printLineToBat ("cd ..");

printLineToBat ("IF EXIST $build_dir GOTO SECOND_STEP");
printLineToBat ("mkdir $build_dir");
printLineToBat (":SECOND_STEP");
printLineToBat ("cd $build_dir");

printLineToBat ("if \"%~1\"==\"step2\" goto step2");

# step1: compile openssl and do configure. For some reason, can't continue script execution after configure, have to make step2
printLineToBat ("IF EXIST $openssl_dir\\build GOTO OPENSSL_ALREAD_COMPILED");
printLineToBat ("wget --no-check-certificate $openssl_download");
printLineToBat ("7z x openssl-$openssl_version.tar.gz");
printLineToBat ("7z x openssl-$openssl_version.tar -o$openssl_dir -y");
printLineToBat ("mv $openssl_dir\\openssl-$openssl_version\\* $openssl_dir");
printLineToBat ("rmdir $openssl_dir\\openssl-$openssl_version"); # empty now
printLineToBat ("rm openssl-$openssl_version.tar.gz");
printLineToBat ("rm openssl-$openssl_version.tar");
printLineToBat ("cd $openssl_dir"); # go to openssl dir
printLineToBat ("perl Configure VC-$openssl_arch no-asm no-shared no-tests --prefix=%cd%\\build --openssldir=%cd%\\build");
printLineToBat ("nmake");
printLineToBat ("nmake install");
# do some clean up:
printLineToBat ("rm test\\*.exe");
printLineToBat ("rm test\\*.pdb");
printLineToBat ("rm test\\*.obj");
printLineToBat ("del /s /f /q out32");
printLineToBat ("del /s /f /q out32.dbg");
printLineToBat ("cd .."); # go back to qtbase

printLineToBat (":OPENSSL_ALREAD_COMPILED");

# openssl: see https://bugreports.qt.io/browse/QTBUG-65501

my $skipped_modules = "qthttpserver qtlocation qtspeech qtgrpc qt3d qtactiveqt qtcharts qtcoap qtconnectivity qtdatavis3d qtdoc qtlottie qtmqtt qtnetworkauth qtopcua qtpositioning qtremoteobjects qtscxml qtsensors qtserialbus qtserialport qttranslations qtvirtualkeyboard qtwayland qtwebchannel qtwebengine qtwebsockets qtwebview";
$skipped_modules .= " qtquickeffectmaker qtquicktimeline qtquick3d qtquick3dphysics";

$skipped_modules.=' qtmultimedia' if (!$build_multimedia);
$skipped_modules.=' qtgraphs' if (!$build_graphs);

if (!$build_pdf && !$build_webengine)
{
    $skipped_modules .= ' qtdeclarative';
}

# qtwebengine is compiled as a separate module once Qt itself is installed (see below),
# so the modules it links against have to be un-skipped here
my %required_modules;

if ($build_webengine)
{
    $required_modules{$_} = 1 foreach ('qtwebchannel', 'qtpositioning');
}

my $skipped_modules_cmd;

foreach (split(/\s/, $skipped_modules)) {
    next if ($required_modules{$_});

    $skipped_modules_cmd .= "-skip $_ ";
}

my $configure_cmd = "..\\configure -prefix $install_dir -opensource -debug-and-release -confirm-license -opengl desktop -nomake tests -nomake examples";

# append skip modules
$configure_cmd .= " $skipped_modules_cmd";

# append openssl related parameters
$configure_cmd .= " -openssl-linked -- -DOPENSSL_ROOT_DIR=\"$openssl_dir\\build\" -DOPENSSL_INCLUDE_DIR=\"$openssl_dir\\build\\include\" -DOPENSSL_USE_STATIC_LIBS=ON";

# append ffmpeg dir when building multimedia
$configure_cmd .= " -DFFMPEG_DIR=$ffmpeg_prefix" if ($build_multimedia);

printLineToBat ($configure_cmd);

printLineToBat ("goto :EOF");

# step 2:
printLineToBat (":step2");

printLineToBat ("cmake --build . --parallel");

printLineToBat ("IF ERRORLEVEL 1 (");
printLineToBat ("echo Build failed with error %ERRORLEVEL%.");
printLineToBat ("EXIT /B %ERRORLEVEL%");
printLineToBat (")");

printLineToBat ("cmake --install . --config Release");
printLineToBat ("cmake --install . --config Debug");

# clean up
printLineToBat ("cd .."); # since we're now in 'qt6-build' for some reason
printLineToBat ("rmdir $build_dir /s /q");

# remove _tools folder from the installation directory
printLineToBat ("rmdir $install_dir\\_tools /s /q");

# NEW: let's build the PDF module

if ($build_pdf)
{
    printLineToBat ("rmdir _qtwebengine-pdf-build-$arch /s /q"); # remove the folder from the previous builds!
    printLineToBat ("mkdir _qtwebengine-pdf-build-$arch");
    printLineToBat ("cd _qtwebengine-pdf-build-$arch");

    printLineToBat ("$install_dir\\bin\\qt-configure-module.bat ../qtwebengine -- -DFEATURE_qtwebengine_build=OFF && cmake --build . --parallel && cmake --install . --config Release && cmake --install . --config Debug")
}

# and the whole webengine module (Chromium included), which also gives us QtPdf

if ($build_webengine)
{
    printLineToBat ("rmdir _qtwebengine-build-$arch /s /q"); # remove the folder from the previous builds!
    printLineToBat ("mkdir _qtwebengine-build-$arch");
    printLineToBat ("cd _qtwebengine-build-$arch");

    printLineToBat ("$install_dir\\bin\\qt-configure-module.bat ../qtwebengine && cmake --build . --parallel && cmake --install . --config Release && cmake --install . --config Debug")
}

close BAT;

system ($batfile);
system ("$batfile step2");

system ("pause");

sub printLineToBat
{
	print BAT "$_[0]\n";
}


use strict;
use Cwd;
use Path::Tiny;
use IPC::Cmd qw[can_run run];

# check requirements:
die "Cannot proceed without the '_tools' folder'" if (!-e "_tools");

my $current_dir = getcwd;
my $prefix_dir = path($current_dir)->parent(1); # one level up
$current_dir =~ s#/#\\#g; # convert separators to Windows-style
$prefix_dir =~ s#/#\\#g; # convert separators to Windows-style

my $arch = $ARGV[0];
my $openssl_v_major = "1.1.1"; # The 1.1.1 series is Long Term Support (LTS) release, supported until 11th September 2023
my $openssl_v_minor = "k";
my $openssl_version = "$openssl_v_major$openssl_v_minor";
my $openssl_download = "https://www.openssl.org/source/openssl-$openssl_version.tar.gz";
my $openssl_arch = $arch eq "amd64" ? "WIN64A" : "WIN32";
my $openssl_dir = "$current_dir\\openssl-$openssl_version-$openssl_arch";
my $openssl_7z = "openssl-$openssl_version-$openssl_arch.7z";

$arch = "x86" if ($arch eq ''); # specify x86 is nothing is specified
die "Please specify architecture (x86 or amd64)" if ($arch ne "x86" && $arch ne "amd64"); # die if user specified anything except x86 or amd64

# will create a batch file

my $batfile = 'compile_win.bat';

open BAT, '>', $batfile;

printLineToBat ("SET PATH=%PATH%;%cd%\\_tools;%cd%\\_tools\\cmake\\bin"); # add folders to the path for 7z, wget, cmake, etc
printLineToBat ("CALL \"C:\\Program Files (x86)\\Microsoft Visual Studio\\2019\\Community\\VC\\Auxiliary\\Build\\vcvarsall.bat\" $arch");
printLineToBat ("SET _ROOT=%cd%");
printLineToBat ("SET PATH=%_ROOT%\\qtbase\\bin;%_ROOT%\\gnuwin32\\bin;%PATH%"); # http://doc.qt.io/qt-5/windows-building.html
printLineToBat ("SET OPENSSL_LIBS=-lUser32 -lAdvapi32 -lGdi32 -llibcrypto -llibssl");

printLineToBat ("cd _tools");
printLineToBat ("7z x cmake.7z -aoa -y");

printLineToBat ("7z x $openssl_7z -o$openssl_dir -y") if (-e "_tools\\$openssl_7z");
printLineToBat ("cd ..");

printLineToBat ("IF EXIST qt6-build GOTO SECOND_STEP");
printLineToBat ("mkdir qt6-build");
printLineToBat (":SECOND_STEP");
printLineToBat ("cd qt6-build");

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

my $skipped_modules = "qt3d qtactiveqt qtcharts qtcoap qtconnectivity qtdatavis3d qtdeclarative qtdoc qtlottie qtmqtt qtmultimedia qtnetworkauth qtopcua qtpositioning qtquick3d qtquicktimeline qtremoteobjects qtscxml qtsensors qtserialbus qtserialport qtshadertools qtsvg qttranslations qtvirtualkeyboard qtwayland qtwebchannel qtwebengine qtwebsockets qtwebview";

my $skipped_modules_cmd;

foreach (split(/\s/, $skipped_modules)) {
    $skipped_modules_cmd .= "-skip $_ ";
}

printLineToBat ("..\\configure -prefix C:\\qt6 -opensource -debug-and-release -confirm-license -opengl desktop -nomake tests -nomake examples $skipped_modules_cmd -openssl-linked -- -DOPENSSL_ROOT_DIR=\"$openssl_dir\\build\" -DOPENSSL_INCLUDE_DIR=\"$openssl_dir\\build\\include\" -DOPENSSL_USE_STATIC_LIBS=ON");

printLineToBat ("goto :EOF");

# step 2:
printLineToBat (":step2");

printLineToBat ("cmake --build . --parallel");
printLineToBat ("cmake --install . --config Release");
printLineToBat ("cmake --install . --config Debug");

# clean up
printLineToBat ("cd .."); # since we're now in 'qt6-build' for some reason
printLineToBat ("rmdir qt6-build /s /q");

close BAT;

system ($batfile);
system ("$batfile step2");

system ("pause");

sub printLineToBat
{
	print BAT "$_[0]\n";
}
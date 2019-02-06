use strict;

die "Cannot proceed without the 'bin' folder'" if (!-e "bin");

my $arch = $ARGV[0];
my $openssl_v_major = "1.1.1"; # The 1.1.1 series is Long Term Support (LTS) release, supported until 11th September 2023
my $openssl_v_minor = "a";
my $openssl_version = "$openssl_v_major$openssl_v_minor";
my $openssl_dir = "openssl-$openssl_version"; 
my $openssl_download = "https://www.openssl.org/source/openssl-$openssl_version.tar.gz";
my $openssl_arch = $arch eq "amd64" ? "WIN64A" : "WIN32";

$arch = "x86" if ($arch eq ''); # specify x86 is nothing is specified
die "Please specify architecture (x86 or amd64)" if ($arch ne "x86" && $arch ne "amd64"); # die if user specified anything except x86 or amd64

# will create a batch file

my $batfile = 'compile_win.bat';

open BAT, '>', $batfile;

printLineToBat ("SET PATH=%PATH%;%cd%\\bin"); # add bin folder to the path for 7z and wget
printLineToBat ("CALL \"C:\\Program Files (x86)\\Microsoft Visual Studio\\2017\\Community\\VC\\Auxiliary\\Build\\vcvarsall.bat\" $arch");
printLineToBat ("SET _ROOT=%cd%");
printLineToBat ("SET PATH=%_ROOT%\\qtbase\\bin;%_ROOT%\\gnuwin32\\bin;%PATH%"); # http://doc.qt.io/qt-5/windows-building.html

printLineToBat ("cd qtbase");
printLineToBat ("if \"%~1\"==\"step2\" goto step2");

# step1: compile openssl and do configure. For some reason, can't continue script execution after configure, have to make step2
printLineToBat ("IF EXIST $openssl_dir\\build GOTO OPENSSL_ALREAD_COMPILED");
printLineToBat ("wget --no-check-certificate $openssl_download");
printLineToBat ("7z x openssl-$openssl_version.tar.gz");
printLineToBat ("7z x openssl-$openssl_version.tar");
printLineToBat ("rm openssl-$openssl_version.tar.gz");
printLineToBat ("rm openssl-$openssl_version.tar");
printLineToBat ("cd $openssl_dir");
printLineToBat ("perl Configure VC-$openssl_arch no-asm no-shared no-tests --prefix=%cd%\\build --openssldir=%cd%\\build");
printLineToBat ("nmake");
printLineToBat ("nmake install");
printLineToBat (":OPENSSL_ALREAD_COMPILED");
# go back to  qtbase
printLineToBat ("cd ..");

# -developer-build creates an in-source build for developer usage.
# openssl: see https://bugreports.qt.io/browse/QTBUG-65501
printLineToBat ("configure -opensource -developer-build -confirm-license -opengl desktop -mp -nomake tests -nomake examples -I \"%cd%\\$openssl_dir\\build\\include\" -openssl-linked OPENSSL_LIBS=\"%cd%\\$openssl_dir\\build\\lib\\libssl.lib %cd%\\$openssl_dir\\build\\lib\\libcrypto.lib -lcrypt32 -lws2_32 -lAdvapi32 -luser32\"");
printLineToBat ("goto :EOF");

# step 2:
printLineToBat (":step2");

printLineToBat ("nmake");
printLineToBat ("cd ..\\qttools");
printLineToBat ("..\\qtbase\\bin\\qmake");
printLineToBat ("nmake");
printLineToBat ("cd ..\\qtbase");
printLineToBat ("cd .."); # go up to qt dir
# openssl clean up
printLineToBat ("cd qtbase");
printLineToBat ("cd $openssl_dir");
printLineToBat ("del /s /f /q out32");
printLineToBat ("del /s /f /q out32.dbg");
printLineToBat ("cd ..");
printLineToBat ("cd ..");
# the rest
printLineToBat ("del *.obj /s /f");
printLineToBat ("del *.ilk /s /f");
printLineToBat ("del *.pch /s /f");
printLineToBat ("del Makefile* /s /f");

close BAT;

system ($batfile);
system ("$batfile step2");

system ("pause");

sub printLineToBat
{
	print BAT "$_[0]\n";
}
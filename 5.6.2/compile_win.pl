use strict;

my $arch = $ARGV[0];
my $openssl_v_major = "1.0.2"; # The 1.0.2 series is Long Term Support (LTS) release, supported until 31st December 2019
my $openssl_v_minor = "l";
my $openssl_version = "$openssl_v_major$openssl_v_minor";
my $openssl_dir = "openssl-$openssl_version"; 
my $openssl_download = "https://www.openssl.org/source/old/$openssl_v_major/openssl-$openssl_version.tar.gz";
my $openssl_arch = $arch eq "amd64" ? "WIN64A" : "WIN32";
my $openssl_do_ms = $arch eq "amd64" ? "do_win64a" : "do_ms";

die "Please specify architecture (x86 or amd64)" if ($arch ne "x86" && $arch ne "amd64");

# will create a batch file

my $batfile = 'compile_win.bat';

open BAT, '>', $batfile;

printLineToBat ("CALL \"C:\\Program Files (x86)\\Microsoft Visual Studio 12.0\\VC\\vcvarsall.bat\" $arch");
printLineToBat ("cd qtbase");
printLineToBat ("wget $openssl_download");
printLineToBat ("tar -xvzf openssl-$openssl_version.tar.gz");
printLineToBat ("rm openssl-$openssl_version.tar.gz");
printLineToBat ("cd $openssl_dir");
# build debug
printLineToBat ("perl Configure no-asm no-shared --prefix=%cd%\\Debug --openssldir=%cd%\\Debug debug-VC-$openssl_arch");
printLineToBat ("call ms\\$openssl_do_ms");
printLineToBat ("nmake -f ms\\nt.mak");
printLineToBat ("nmake -f ms\\nt.mak install");
printLineToBat ("xcopy tmp32.dbg\\lib.pdb Debug\\lib\\"); # Telegram does it.
printLineToBat ("nmake -f ms\\nt.mak clean");
# now release
printLineToBat ("perl Configure no-asm no-shared --prefix=%cd%\\Release --openssldir=%cd%\\Release VC-$openssl_arch");
printLineToBat ("call ms\\$openssl_do_ms");
printLineToBat ("nmake -f ms\\nt.mak");
printLineToBat ("nmake -f ms\\nt.mak install");
printLineToBat ("xcopy tmp32\\lib.pdb Release\\lib\\"); # Telegram does it.
printLineToBat ("nmake -f ms\\nt.mak clean");
# go back to  qtbase
printLineToBat ("cd ..");
printLineToBat ("SET _ROOT=%cd%");
printLineToBat ("SET PATH=%_ROOT%\\qtbase\\bin;%_ROOT%\\gnuwin32\\bin;%PATH%"); # http://doc.qt.io/qt-5/windows-building.html
printLineToBat ("configure -opensource -confirm-license -opengl desktop -mp -nomake tests -nomake examples -target xp  -I \"%cd%\\$openssl_dir\\Release\\include\" -openssl-linked OPENSSL_LIBS_DEBUG=\"%cd%\\$openssl_dir\\Debug\\lib\\ssleay32.lib %cd%\\$openssl_dir\\Debug\\lib\\libeay32.lib\" OPENSSL_LIBS_RELEASE=\"%cd%\\$openssl_dir\\Release\\lib\\ssleay32.lib %cd%\\$openssl_dir\\Release\\lib\\libeay32.lib\"");
printLineToBat ("nmake");
printLineToBat ("cd ..\\qttools");
printLineToBat ("qmake");
printLineToBat ("nmake");
printLineToBat ("cd ..\\qtwinextras");
printLineToBat ("qmake");
printLineToBat ("nmake");
printLineToBat ("cd ..\\qtbase");
printLineToBat ("nmake docs");
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
#system ("del $batfile");
system ("pause");

sub printLineToBat
{
	print BAT "$_[0]\n";
}
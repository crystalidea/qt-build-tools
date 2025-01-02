#!/usr/bin/perl
use strict;
use warnings;

# Define the modules to skip
my @skipped_modules = qw(
    qthttpserver qtlocation qtspeech qtgrpc qt3d qtactiveqt qtcharts qtcoap
    qtconnectivity qtdatavis3d qtdoc qtlottie qtmqtt qtnetworkauth qtopcua
    qtpositioning qtremoteobjects qtscxml qtsensors qtserialbus qtserialport
    qtsvg qttranslations qtvirtualkeyboard qtwayland qtwebchannel qtwebengine
    qtwebsockets qtwebview qtquickeffectmaker qtquicktimeline qtquick3d
    qtquick3dphysics qtgraphs
);

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

# Check for ninja
if (!command_exists('ninja')) {
    die "Error: 'ninja' is not installed or not in the PATH. You can use 'brew install ninja' command\n";
}

# Check for cmake
if (!command_exists('cmake')) {
    die "Error: 'cmake' is not installed or not in the PATH. You can use 'brew install cmake' command\n";
}

my $build_dir = "qt6-build";

if (-d $build_dir) {
    die "Error: $build_dir already exists from the previous build\n";
}

mkdir $build_dir or die "Error: Unable to create directory '$build_dir'.\n";
chdir $build_dir or die "Error: Unable to change directory to '$build_dir'.\n";

# Prepare the configuration command
my $skip_modules_string = join(' ', map { "-skip $_" } @skipped_modules);

# Configure the build
print "Configuring the build...\n";
run_command("../configure $skip_modules_string -- -DCMAKE_OSX_ARCHITECTURES=\"x86_64;arm64\"");

# Build Qt6
print "Building Qt6...\n";
run_command("cmake --build . --parallel");

# Install Qt6
print "Installing Qt6...\n";
run_command("cmake --install .");

print "Qt6 has been successfully built and installed.\n";
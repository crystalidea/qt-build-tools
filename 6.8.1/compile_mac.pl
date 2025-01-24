#!/usr/bin/perl
use strict;
use warnings;
use Time::HiRes qw(gettimeofday tv_interval);

# Start time
my $start_time = [gettimeofday];

# Define the modules to skip
my @skipped_modules = qw(
    qthttpserver qtlocation qtspeech qtgrpc qt3d qtactiveqt qtcharts qtcoap
    qtconnectivity qtdatavis3d qtdoc qtlottie qtmqtt qtnetworkauth qtopcua
    qtpositioning qtremoteobjects qtscxml qtsensors qtserialbus qtserialport
    qtsvg qttranslations qtvirtualkeyboard qtwayland qtwebchannel qtwebengine
    qtwebsockets qtwebview qtquickeffectmaker qtquicktimeline qtquick3d
    qtquick3dphysics qtgraphs qtmultimedia qtdeclarative qtlanguageserver qtshadertools qttools
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

# Subroutine to run a command with optional elevation
sub run_command_with_sudo {
    my ($cmd) = @_;
    print "Running: $cmd\n";
    open(my $pipe, '-|', "sudo $cmd 2>&1") or die "Error: Unable to execute '$cmd' with sudo.\n";
    while (my $line = <$pipe>) {
        print $line;
    }
    close($pipe);
    if ($? != 0) {
        die "Error: Command '$cmd' with sudo failed.\n";
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
my $install_dir = "/usr/local/Qt-6.8.1";

if (-d $build_dir) {
    die "Error: $build_dir already exists from the previous build\n";
}

if (-d $install_dir) {
    die "Error: $install_dir already exists from the previous build\n";
}

mkdir $build_dir or die "Error: Unable to create directory '$build_dir'.\n";
chdir $build_dir or die "Error: Unable to change directory to '$build_dir'.\n";

# Prepare the configuration command
my $skip_modules_string = join(' ', map { "-skip $_" } @skipped_modules);

# Configure the build
print "Configuring the build...\n";

my $build_archs = "-DCMAKE_OSX_ARCHITECTURES=\"x86_64;arm64\""; 
# NOTE: if $build_archs is empty, Qt is defaults to x86_64 on an arm64 machine, which is not what described in the docs:
# https://doc.qt.io/qt-6/macos-building.html
my $build_etc = "-DBUILD_TESTING=OFF";

run_command("../configure $skip_modules_string -no-framework -- $build_archs $build_etc");

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

# Install Qt6 with sudo
print "Installing Qt6 with elevated privileges...\n";
run_command_with_sudo("cmake --install .");

print "Qt6 has been successfully built and installed.\n";
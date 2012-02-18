#!/usr/bin/perl

our $VERSION = 0.1;

use Getopt::Std;

my $out_format = 'default';
my $out_file = 'eBook';
my @in_files;

my $help_msg = <<END;
  Options:
    -h              Display this help
    -t [mobi|epub]  Define type of output, default is 'epub'
    -o [filename]   Set filename for the resulting eBook, default is 'eBook'

    [file|dir]      Multiple filenames or directories containing POD

    NOTICE: write the options (t,o) before the list of POD files or dirs

  Examples:
    programname -t mobi file1 file2
    programname -t epub dir1 dir2
    programname file*

END

my %opts;
getopts('ht:o:', \%opts);

if (exists $opts{h}) {
    print $help_msg;
    exit 0;
}

if (exists $opts{t}) {
    if ($opts{t} eq 'mobi') {
        $out_format = 'Mobi';
        $out_file  .= '.mobi';
    }
    elsif ($opts{t} eq 'epub') {
        $out_format = 'EPub';
        $out_file  .= '.epub';
    }
    else {
        die "ERROR: type '$opts{t}' is not supported\n";
    }
}
else {
    # choose default
    $out_format = 'EPub';
    print "Choose default type: '$out_format'\n";
}

if (exists $opts{o}) {
    $out_file = $opts{o};
}

print "Output format will be '$out_format'\n";

if (@ARGV < 1) {
    die "ERROR: no input files found, see help for usage:\n\n$help_msg";
}

print "I'll work on this files:\n";
print '    ';
print join "\n    ", @ARGV;
print "\n";

foreach my $file (@ARGV) {
    unless (-e $file) {
        die "ERROR: '$file' does not exist\n";
    }

    if (-d $file) {
        push (@in_files, { type => 'Dir', path => $file });
    }
    elsif (-f $file and -r $file) {
        push (@in_files, { type => 'File', path => $file });
    }
    else {
        die "ERROR: '$file' is not a regular file or directory\n";
    }
}

print "Input is ok. Starting EPublisher\n\n";

use EPublisher;
use EPublisher::Target::Plugin::Mobi;

my $publisher = EPublisher->new(
    config => { FromCMD => { source => \@in_files,
                          target => { type => $out_format,
                                      output => $out_file
                                    }
                        }
              },
    debug  => sub {
        print "@_\n";
    },  
);

$publisher->run( [ 'FromCMD' ] );


#!/usr/bin/perl

our $VERSION = 0.1;

use Getopt::Std;

my $out_format = 'default';
my $out_file = 'eBook';
my @in_files;

my $help_msg = <<END;
  Main Options:
    -h             Display this help
    -f [mobi|epub] Define format of output, default is 'epub'
    -o filename    Set filename for the resulting eBook, default is 'eBook'

  Options for Individualization:
    -t title       Title of the book (meta information)
    -a author      Author of the book (meta information)
    -c path        Image for a cover of the book
    -s html-string Primitive HTML for a cover of the book
    -e encoding    Encoding                                TODO

    [file|dir]      Multiple filenames or directories containing POD

    NOTICE: write the options (t,o) before the list of POD files or dirs

  Short Examples:
    programname -f mobi file1 file2
    programname -f epub dir1 dir2
    programname file*

  Full Example:
    programname -f mobi \\
                -c ./cover.jpg \\
                -s '<h1>The Camel</h1><p>The Coding Camle Guide</p>' \\
                -t 'The Camel' \\
                -a 'Boris Daeppen' \\
                -o 'the_camle.mobi' \\
                ./*.pod

END

my %opts;
getopts('hf:o:c:s:t:a:', \%opts);

if (exists $opts{h}) {
    print $help_msg;
    exit 0;
}

if (exists $opts{f}) {
    if ($opts{f} eq 'mobi') {
        $out_format = 'Mobi';
        $out_file  .= '.mobi';
    }
    elsif ($opts{f} eq 'epub') {
        $out_format = 'EPub';
        $out_file  .= '.epub';
    }
    else {
        die "ERROR: type '$opts{f}' is not supported\n";
    }
}
else {
    # choose default
    $out_format = 'EPub';
    $out_file  .= '.mobi';
    print "Choose default type: '$out_format'\n";
}

if (exists $opts{o}) {
    $out_file = $opts{o};
}

print "Output format will be '$out_format'\n";
print "Output filename will be '$out_file'\n";

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

my %config = (
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

if (exists $opts{c}) {
    $config{config}{FromCMD}{target}{imgcover} = $opts{c};
}

if (exists $opts{s}) {
    $config{config}{FromCMD}{target}{htmcover} = $opts{s};
}

if (exists $opts{t}) {
    $config{config}{FromCMD}{target}{title} = $opts{t};
}

if (exists $opts{a}) {
    $config{config}{FromCMD}{target}{author} = $opts{a};
}

print "The option-hash I pass to EPublisher:\n";
use Data::Dumper;
print Dumper(\%config);

my $publisher = EPublisher->new( %config );

$publisher->run( [ 'FromCMD' ] );


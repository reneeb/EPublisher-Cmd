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
                   (only sopported by the mobi output format)
    -e encoding    Encoding (e.g. utf-8)
    -p             TOC entries from POD heading, otherwise sourcename

    [file|dir]      Multiple filenames or directories containing POD

    NOTICE: write the options _before_ the list of POD files or dirs

  Short Examples:
    programname -f mobi file1 file2
    programname -f epub dir1 dir2
    programname file*

  Full Example:
    programname -f mobi \\
                -p \\
                -c ./cover.jpg \\
                -s '<h1>The Camel</h1><p>The Coding Camle Guide</p>' \\
                -t 'The Camel' \\
                -a 'Boris Daeppen' \\
                -o 'the_camel.mobi' \\
                -e utf-8 \\
                ./*.pod

END

my %opts;
getopts('hpf:o:c:s:t:a:e:', \%opts);

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
        if (exists $opts{p}) {
            push (@in_files,{type =>'Dir', path => $file, title => 'pod' });
        }
        else {
            push (@in_files, { type => 'Dir', path => $file });
        }
    }
    elsif (-f $file and -r $file) {
        if (exists $opts{p}) {
            push (@in_files,{type =>'File', path => $file, title => 'pod'});
        }
        else {
            push (@in_files, { type => 'File', path => $file});
        }
    }
    else {
        die "ERROR: '$file' is not a regular file or directory\n";
    }
}

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
    print "adding cover image: $opts{c}\n";
    $config{config}{FromCMD}{target}{cover} = $opts{c};
}

if (exists $opts{s}) {
    print "adding cover html: $opts{s}\n";
    $config{config}{FromCMD}{target}{htmcover} = $opts{s};
}

if (exists $opts{t}) {
    print "adding book title: $opts{t}\n";
    $config{config}{FromCMD}{target}{title} = $opts{t};
}

if (exists $opts{a}) {
    print "adding author: $opts{a}\n";
    $config{config}{FromCMD}{target}{author} = $opts{a};
}

if (exists $opts{e}) {
    print "adding encoding: $opts{e}\n";
    $config{config}{FromCMD}{target}{encoding} = $opts{e};
}

print "All options parsed. Here is the option-hash I pass to EPublisher:\n";
use Data::Dumper;
print Dumper($config{config}{FromCMD});

print "Starting EPublisher...\n\n";

use EPublisher;
use EPublisher::Target::Plugin::Mobi;

my $publisher = EPublisher->new( %config );

$publisher->run( [ 'FromCMD' ] );

print "DONE\n";


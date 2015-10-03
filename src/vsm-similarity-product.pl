#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper qw (Dumper);


## Total dokumen (argumen cmd / terminal)
my $totalDoc = $ARGV[0] || 1000;
# $totalDoc = 1000 if not defined $totalDoc;

## File total frekuensi seluruh dokumen (argumen cmd / terminal)
my $totalFreqDoc = $ARGV[1] || "../data/total-word-freq.dat";
# $totalFreqDoc = "total-word-freq.dat" if not defined $totalFreqDoc;

## File detail frekuensi sebagain dokumen (argumen cmd / terminal)
my $freqDetailDoc = $ARGV[2] || "../data/words-freq.dat";
# $freqDetailDoc = "words-freq.dat" if not defined $freqDetailDoc;


#### INPUT DATA FREKUENSI KATA SELURUH DOKUMEN
open (TFREQ, $totalFreqDoc) or die "can't open file total frequency.";

## Container untuk total frekuensi tiap kata dalam
## seluruh dokumen
my %totalWordFreq = ();

## Container untuk list kata yang ada
my @wordList;

while (<TFREQ>) {
    chomp;

    my @line = split /;/;

    ## Baris 1 = list kata, 2 = total frekuensi
    if ($. eq 1) {
        ## Simpan list kata
        @wordList = @line;
    } else {
        ## Simpan frekuensi total tiap kata
        for (my $i = 0; $i < scalar @line; $i++) {
            # print Dumper \$wordList[ $i ];
            $totalWordFreq{ $wordList[ $i ] } = $line[ $i ];
        }
    }
}

close TFREQ;

# print Dumper \@wordList;
# print Dumper \%totalWordFreq;


#### INPUT DATA FREQKUENSI TIAP DOKUMEN
open (FREQLIST, $freqDetailDoc) or die "can't open file.";

my %freqList = ();

while (<FREQLIST>) {
    chomp;

    my @line = split /;/;
    my %data;
    my $total = 0;

    for (my $i = 0; $i < scalar @line; $i++) {
        $total += $line[ $i ];

        # push @data, $line[ $i ];
        $data{ $wordList[ $i ] } = $line[ $i ];
    }

    # push @data, $total;
    $data{ "total" } = $total;
    $freqList{ $. } = { %data };
}

close FREQLIST;

# print Dumper \%freqList;
# print $freqList{ 1 }{ "mahasiswa" };


#### HITUNG IDF
my %idf = ();

foreach my $word (@wordList) {
    $idf{ $word } = log2($totalDoc / $totalWordFreq{ $word });
}

# print Dumper \%idf;


#### HITUNG TF-IDF
my %tfIdf = ();

for (my $i = 1; $i <= scalar keys %freqList; $i++) {
    foreach my $word (@wordList) {
        my $tf = $freqList{ $i }{ $word } / $freqList{ $i }{ "total" };

        $tfIdf{ $i }{ $word } = $tf * $idf{ $word };
    }
}

# print Dumper \%tfIdf;


print ":: TF-IDF ::\n";

### table header
printf("%13s", "Dokumen/Kata");

foreach my $word (@wordList) {
    printf("%13s", $word);
}

print "\n";

### table content
foreach my $doc (sort keys %freqList) {
    printf("%13s", "D$doc");

    foreach my $word (@wordList) {
        printf("%13.3f", $tfIdf{ $doc }{ $word });
    }

    print "\n";
}

print "\n";


#### COMPUTE SIMILARITY
print "Query ? ";
chomp(my $query = <STDIN>);

my @queries = split /\s/, $query;

my %result = ();

### Similarity Product / Inner Product

foreach my $doc (sort keys %freqList) {
    my $total = 0;

    foreach my $word (@queries) {
        $total += $idf{ $word } * $tfIdf{ $doc }{ $word };
    }

    $result{ $doc } = $total;
}

print "\n";
print ":: Hasil ::\n";
print "[Similarity Product / Inner Product]\n";

my ($best, $worst, $min, $max) = (1, 1, $result{1}, $result{1});

foreach my $doc (sort keys %result) {
    printf("D%d : %.3f\n", $doc, $result{ $doc });

    if ($min > $result{ $doc }) {
        $min = $result{ $doc };
        $worst = $doc;
    }

    if ($max < $result{ $doc }) {
        $max = $result{ $doc };
        $best = $doc;
    }
}
print "\n";
print "=> Dokumen paling relevan       : D$best\n";
print "=> Dokumen paling tidak relevan : D$worst\n";

################################################################################

sub log2 {
    my $n = shift;
    return log($n) / log(2);
}

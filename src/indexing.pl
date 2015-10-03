#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);


#### Main Program

my $doc = "../data/Koleksi.dat";
# my $stw = "../data/stopwords-ina.dat";
my $res = "../data/hasil.txt";
my $index = "../data/indeks.txt";

## preprocessing
my %list = indexing($doc, $res, $index);

# print Dumper \%list;

say "selesai.";

####

sub indexing {
    ## open dokumen awal
    open(FILE, "$_[0]") or die "can't open data source";

    ## open stopwords file
    # open(STOP,"$_[2]") or die "can't open ";

    ## open file hasil reduksi
    open(RESULT, "> $_[1]") or die "can't open result file";

    ## open file indeks kata
    open(INDEX, "> $_[2]") or die "can't open index file";

    ## simpan list stopwords dalam hash
    # my %stopwords = ();

    # while(<STOP>) {
    #     chomp;
    #     $stopwords{$_} = 1;
    # }

    # frekuensi total
    my %termfreq = ();

    # total seluruh dokumen
    my $totalDoc = 0;

    # frekuensi tiap docid - docno
    my %result = ();

    # frekuensi per dokumen
    my %hashKata = ();

    # nomor dokumen
    my $curr_doc_id;
    my $curr_doc_no;

    # total frekuensi tiap dokumen
    my $totalFreqEachDoc = 0;

    while(<FILE>) {
        chomp;
        s/\s+/ /gi;

        ## update informasi docid
        if (/<DOCID>/) {
            s/<.*?>/ /gi;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;

            $curr_doc_id = $_;
        }

        ## update informasi docno
        if (/<DOCNO>/) {
            s/<.*?>/ /gi;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;

            ## inisialisasi ulang hashkata dan nomor dokumen tiap dokumen baru
            %hashKata = ();
            $curr_doc_no = $_;
            $totalDoc += 1;
        }

        if (/<\/DOC>/) {
            ## simpan frekuensi tiap kata dalam tiap docid - docno
            $result{$curr_doc_id}{$curr_doc_no} = { %hashKata };
            ## simpan total frekuensi kata dalam tiap docid - docno
            $result{$curr_doc_id}{$curr_doc_no}{"totalFreqEachDoc"} = $totalFreqEachDoc;

            ## kosongkan daftar frekuensi kata untuk dokumen selanjutnya
            %hashKata = ();
            $totalFreqEachDoc = 0;
        }

        if (/<TEXT>/../<\/TEXT>/) {
            s/<.*?>/ /gi;
            s/[#\%\$\&\/\\,;:!?\.\@+`'"\*()_{}^=|]/ /g;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;
            tr/[A-Z]/[a-z]/;

            ## tokenisasi
            my @splitKorpus = split;

            foreach my $kata(@splitKorpus) {
                ## cek kata apakah termasuk dalam list stopwords
                # unless (exists($stopwords{$kata})) {
                    if (exists($hashKata{$kata})) {
                        $hashKata{$kata} += 1;
                    } else {
                        $hashKata{$kata} = 1;
                    }

                    if (exists($termfreq{$kata})) {
                        $termfreq{$kata} += 1;
                    } else {
                        $termfreq{$kata} = 1;
                    }
                # }
            }

            ## increment jumlah frekuensi kata dalam dokumen
            $totalFreqEachDoc += scalar @splitKorpus;
        }
    }

    ## hitung idf
    my %IDF = ();

    foreach my $word (keys %termfreq) {
        $IDF{$word} = $termfreq{$word} / $totalDoc;
    }

    ## hitung tf-idf
    foreach my $docid (sort keys %result) {
        foreach my $docno (sort keys %{ $result{$docid} }) {
            say RESULT "<DOCID> $docid </DOCID>";
            say RESULT "<DOCNO> $docno </DOCNO>";

            foreach my $word (sort keys %{ $result{$docid}{$docno} }) {
                if ($word ne "totalFreqEachDoc") {
                    my $currTotalFreq = $result{$docid}{$docno}{"totalFreqEachDoc"};
                    my $TFIDF = $result{$docid}{$docno}{$word} / $currTotalFreq * $IDF{$word};

                    printf RESULT "%20s : %.9f\n", $word, $TFIDF;
                }
            }

            say RESULT "";
        }
    }

    foreach my $word (sort {$termfreq{$b} <=> $termfreq{$a}
        or $b cmp $a} keys %termfreq) {
        printf INDEX "%20s : %4d\n", $word, $termfreq{$word};
    }

    ## tutup file
    # close STOP;
    close FILE;
    close RESULT;
    close INDEX;

    return %result;
}

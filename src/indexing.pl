#!/usr/bin/perl

use strict;
use warnings;

use feature "say";
use Data::Dumper qw (Dumper);


#### Main Program

my $doc = "../data/Koleksi.dat";
my $stw = "../data/stopwords-ina.dat";
my $res = "../data/Indeks.txt";
my $fin = "../data/Rangkuman.txt";

## preprocessing
my %list = indexing($doc, $res, $fin, $stw);

print Dumper \%list;

say "selesai.";

####

sub indexing {
    ## open dokumen awal
    open(FILE, "$_[0]") or die "can't open ";

    ## open stopwords file
    open(STOP,"$_[3]") or die "can't open ";

    ## open file hasil reduksi
    open(INDEX,"> $_[1]") or die "can't open ";

    ## open file output rangkuman
    open(RESULT,"> $_[2]") or die "can't open ";

    ## simpan list stopwords dalam hash
    my %stopwords = ();

    while(<STOP>) {
        chomp;
        $stopwords{$_} = 1;
    }

    # frekuensi total
    my %termfreq = ();
    my %result = ();

    # frekuensi per dokumen
    my %hashKata = ();

    # nomor dokumen
    my $curr_doc_no;

    my %total_sentence = ();

    while(<FILE>) {
        chomp;
        s/\s+/ /gi;
        ## simpan informasi mengenai nomor dokumen
        if(/<DOCNO>/) {
            ## cek size hashkata (workaround utk pemrosesan dokumen pertama)
            my $size = keys %hashKata;
            if ($size > 0) {
                $result{$curr_doc_no} = { %hashKata };
            }

            s/<.*?>/ /gi;
            s/\s+/ /gi;
            s/^\s+//;
            s/\s+$//;

            say INDEX;
            ## inisialisasi ulang hashkata dan nomor dokumen tiap dokumen baru
            %hashKata = ();
            $curr_doc_no = $_;
            $total_sentence{$curr_doc_no} = 0;
        }

        if(/<TITLE>/../<\/DOC>/) {
            chomp;
            if(/<\/DOC>/) {
                ## output kata dan frekuensi tiap dokumen ke file
                foreach my $hasil(sort {$hashKata{$b} <=> $hashKata{$a}
                    or $a cmp $b} keys %hashKata) {
                    say INDEX "$hasil;$hashKata{$hasil}";
                }

                # jumlah kalimat per dokumen
            }

            if(/<TEXT>/../<\/TEXT>/) {
                my $line = $_;
                $line =~ s/<.*?>/ /gi;
                $line =~ s/\s+/ /gi;
                $line =~ s/^\s+//;
                $line =~ s/\s+$//;
                $total_sentence{$curr_doc_no} += scalar(split /\./, $line);
            }

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
                unless (exists($stopwords{$kata})) {
                    if (exists($hashKata{$kata})) {
                        $hashKata{$kata} += 1;
                    } else {
                        $hashKata{$kata} = 1;
                    }

                    if (exists($termfreq{$kata})) {
                        $termfreq{$kata} += 1;
                    } else {
                        $termfreq{$kata} += 1;
                    }
                }
            }
        }
    }

    ## tutup file
    close STOP;
    close FILE;
    close INDEX;

    # daftar 20 kata paling atas
    say RESULT "=> Daftar 20 kata paling atas : ";
    my $jumlah = 1;
    foreach my $kata (sort {$termfreq{$b} <=> $termfreq{$a}
        or $a cmp $b} keys %termfreq) {
        if($jumlah > 20) {
            last;
        }
        say RESULT "$jumlah. $kata : $termfreq{$kata}";
        $jumlah += 1;
    }

    # daftar 20 kata paling bawah
    $jumlah = 1;
    say RESULT "\n=> Daftar 20 kata paling bawah : ";
    foreach my $kata (sort {$termfreq{$a} <=> $termfreq{$b}
        or $b cmp $a} keys %termfreq) {
        if($jumlah > 20) {
            last;
        }
        say RESULT "$jumlah. $kata : $termfreq{$kata}";
        $jumlah += 1;
    }

    my $total_sentence_count = 0;
    # jumlah kalimat per dokumen
    say RESULT "\n=> Jumlah kalimat per dokumen : ";
    foreach my $doc (sort keys %total_sentence) {
        say RESULT "$doc : $total_sentence{$doc}";
        $total_sentence_count += $total_sentence{$doc};
    }

    # jumlah kalimat yang ada dalam seluruh dokumen
    say RESULT "\n=> Jumlah kalimat seluruh dokumen : $total_sentence_count";

    close RESULT;

    return %result;
}

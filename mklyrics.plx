#!/usr/bin/perl
#
# NAME
#       mklyrics - simplify HTML lyrics transcriptions
#
# SYNOPSIS
#       mklyrics TITLETAG FILE...
#
# OPTIONS
#       TITLETAG is used to specify the name of the HTML tag in which the title
#       of the song(s) can be found. As of now it must be a properly formed
#       HTML tag such as <h1>...</h1> (to use this you would run »mklyrics h1
#       foo.html«).
#
# DESCRIPTION
#       This program is a quite Q&D attempt to strip a lot superflous code etc.
#       from lyrics transcriptions. It produces a simple transcription by
#       stripping a lot of superflous things from one or several more advanced
#       one(s).
#
#       The processed files are re-capitalized (existing capitalization is not
#       touched, so if you encounter a file with only CAPITALS it won't be
#       treated very well...).
#
#       Titles (of songs)
#           Each word is capitalized, except words given in
#           @Non_Capitalized_In_Titles (which you may want to add words to).
#
#       Special words
#           All words found in @Capitalized_Words is recapitalized to match the
#           capitalization found there. (You may want to add words, such as
#           names of people, places and holidays etc - just remember that words
#           occuring here will *always* be capitalized as specified, so take
#           care with any word that may have a non-capitalized homonym.)
#
#       Initial letter
#           The initial letter of each line is capitalized.
#
#       HTML Entities
#           (Such as »&nbsp;«, »&auml;« etc.) Should you find any of these that
#           aren't correctly converted then just insert (or change) the code in
#           question in the %HTML_Entity hash. Should be pretty
#           straightforward.
#
# NOTES
#       The program is set up so that it should be easy to add things to it and
#       change it as desired. Right now it does nothing to interpret the HTML
#       tags <p> and <br>, which may be A Bad Thing (possibly) - that should be
#       easy to fix however.
#
# AUTHOR
#       Zrajm C Akfohg <zrajm@klingonska.org>. This program is distributed
#       under the GNU Public License.
#
# HISTORY
#       [2002-10-29] and [2002-10-30] - Wrote initial (sloppy) code. This began
#       as a one-liner using more and more regexes with sed, and grep and perl.
#       Since I decided I should be able to reuse the code I turned into a
#       simple perl script. This is the result.
#
#
# FOOTNOTE: HEADLINE CAPITALIZATION
#       Let's start with the orange book, CMS (Chicago Manual of Style). It
#       states in 7.127, "In regular title capitalization, also known as
#       headline style, the first and last words and all nouns, pronouns,
#       adjectives, verbs, adverbs, and subordinating conjunctions (if,
#       because, as, that, etc.) are capitalized." 
#
#       The words »Is« (verb) and »It« (pronoun) should be capitalized, while
#       conjuctions such as »and« and »or« should not. Prepositions such as
#       »in«, »on« and »of« should neither be capitalized.
#

$title_tag = shift @ARGV;
if (-e $title_tag) {
    warn "Hey! Your 1st argument is the name of a file!\n";
    warn "(It should be the name of the HTML tag\n";
    die "which surrounds the title of each song.)\n";
}

# These words should always be capitalized
# (capitalize them if they aren't)
@Capitalized_Words = qw(
    I
    Ani
    DiFranco
);
@Non_Capitalized_In_Titles = qw(
    a   and
    of  or
    the to
);
%HTML_Entity = (
    nbsp => " ",
);



$LC = "a-zåäöé";
$UC = "A-ZÅÄÖÉ";
sub LC($) { local ($_)=@_; eval "tr/$UC/$LC/"; $_ }   # lc
sub UC($) { local ($_)=@_; eval "tr/$LC/$UC/"; $_ }   # uc

%UC_Words = map { LC $_ => $_ } @Capitalized_Words;
$UC_Words = join "|", sort keys %UC_Words;
%LC_Words = map { $_ => 1 } @Non_Capitalized_In_Titles;
$HTML     = join "|", sort keys %HTML_Entity;



undef $/;                                      # slurp mode
@title = ();                                   #
@text  = ();
foreach $file (@ARGV) {

    # open and read file
    open file or next;                         #
    $line = <file>;                            #
    close file;                                #

    # process file
    for ($line) {
        s{\r}{}g foreach $line;                # remove CR:s (char 13)
        s{<pre.*?>\s*}{}gi;                    #
        s{\b($UC_Words)\b}{                    # capitalize some words
            $UC_Words{lc $1}                   #
        }giex;                                 #
        s{<$title_tag>                         # grab title
            \s*(.*?)\s*                        #
          </$title_tag>\s*                     #
        }{                                     #
            # split title into words ($word[1] is 1st word,
            # $word[0] contains preceding non-word chars)
            my @word = split /(?<!['$LC$UC])(?=['$LC$UC])/i, $1;
            unshift @word, "" if /[$LC$UC]/;   # make sure 1st on non-word

            # always capitalize first and last word
            for (@word[1], @word[$#word]) {    #
                next if /[$UC]/;               # skip words w/ uppers
                s/([$LC])/UC $1/e;             # Uppercase 1st letter
            }                                  #

            # capitalize other words
            # if not on exception list
            for (@word[2], @word[$#word-1]) {  #
                next if /[$UC]/;               # skip words w/ uppers
                s/([$LC])([$LC]*)/             # repl 1st and rest of word
                    $LC_Words{$1.$2} ?         #   with capitalized word
                              $1.$2: UC($1).$2;#   if word is not on
                /xe;                           #   the exception list
            }                                  #

            # put together and output
            $_ = join "", @word;               # put title together
            push @title, $_;                   # store in title list
            "\n\n".@title.". $_\n\n";          # output
        }gex;                                  #
        s{<title>.*?</title>}{}sg;             # strip title
        s#<.*?>##g;                            # kill remaining HTML tags
        s#&($HTML);#$HTML_Entity{$1}#ge;
    }



    push @text, $line;
}

    $text = join "", @text;
    foreach ($text) {
        s{^[  	]+}{}gm; s{[  	]+$}{}gm;       # kill space at beg/end of line
        s{^\s+}{}s;  s{\s+$}{\n}s;                         # kill space at beg/end of file
        s#^('?)([a-z])#$1.UC $2#gem;                  # capitalize 1st letter on line
        s#\n{4,}#\n\n\n#g;
#        s#$#¶#gm;
    }

    $/ = "\n";
    my $time = `date -I`;
    chomp $time;
    print "[$time] deHTMLized by script by Zrajm C Akfohg\n";
    print "\n";
    print "Artist: Album_Name [Number]\n";
    print "(c)Year Record_Label\n";
    print "\n";
    foreach (0..$#title) {
        printf "%2u. %s\n", $_+1, $title[$_];
    }
    print "\n\n";
    print $text;
    print "\n";
    print "[[eof]]\n";


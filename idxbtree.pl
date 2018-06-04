#!/usr/bin/perl

# By Michael Chaney, Michael Chaney Consulting Corporation
# Copyright 2005, Michael Chaney Consulting Corporation, All Rights Reserved
#
# Input is presumed to be sorted, creates a b-tree on disk.  We are
# assuming that the entire index can be held in memory a couple of times
# with no problem.  This is not a general b-tree writer, however, it
# will make a perfectly balanced b-tree.

use strict;

use POSIX qw(ceil);

# Use an odd number of words
my $max_words_per_level=199;
my $words_per_level;
my $debug=0;

# force it to be an odd number
$max_words_per_level |= 1;

my ($idxdir,$filename)=@ARGV;
if (!$idxdir || !$filename) { die "Usage: $0 dir file"; }

my (%words, @words);

my ($file);

open F, "<${filename}" or die "Cannot open file: $!";
$file=join('',<F>);
close F;

$file=~s/\s+//g;

print STDERR "Got entire file\n" if $debug;

my ($word, $keys, $key, $positions, $f, $row);

while ($file=~/\G.*?'(.*?)':.*?\{(.*?)\}/g) {
	($word, $keys)=($1,$2);
	$words{$word}={};
	push @words, $word;
	#print STDERR "Working with ${word}\n" if $debug;
	while ($keys=~/\G.*?'(.*?)':\[(.*?)\]/g) {
		($key,$positions)=($1,$2);
		# getting a simple count
		$words{$word}->{$key}=scalar(split(/,/,$positions));
	}
}

print STDERR "Parsed file, writing index\n" if $debug;

# Now, let's figure out how many levels and words per level to make a
# balanced btree.
my $word_count=scalar @words;
if ($word_count<$max_words_per_level) {
	$words_per_level=$word_count;
} elsif ($word_count<($max_words_per_level + ($max_words_per_level * ($max_words_per_level + 1)))) {
	# There are just two levels, so we need to determine how many words
	# per level will make a nicely balanced tree.  I could do this by
	# using the solution to the quadratic equation, but since there'll
	# never be more than $max_words_per_level iterations I'm just going
	# to do some BFI ghetto code.
	my $x;
	for ($x = $max_words_per_level ; $x>0 ; $x--) {
		my $words_for_x=($x+($x*($x+1)));
		last if ($word_count==$words_for_x);
		if ($word_count>$words_for_x) {
			$x++; last;
		}
	}
	$words_per_level=$x;
} elsif ($word_count<($max_words_per_level + ($max_words_per_level * ($max_words_per_level + 1)) + ($max_words_per_level * ($max_words_per_level + 1) * ($max_words_per_level + 1)))) {
	# three levels
	my $x;
	for ($x = $max_words_per_level ; $x>0 ; $x--) {
		my $words_for_x=($x + ($x * ($x + 1)) + ($x * ($x + 1) * ($x + 1)));
		last if ($word_count==$words_for_x);
		if ($word_count>$words_for_x) {
			$x++; last;
		}
	}
	$words_per_level=$x;
} else {
	printf STDERR "Let's be real - you're trying to index too much stuff and I'm not going to do it without some extra programming :)\n";
	exit 1;
}

printf STDERR "Word count: %d, Words per level: %d\n", $word_count, $words_per_level if $debug;

chdir($idxdir);
part(0, \@words);

if (0) {
	foreach $word (sort keys %words) {
		print "'${word}': {\n";
		foreach $key (sort keys %{$words{$word}}) {
			printf("\t'%s': %d,\n", $key, $words{$word}->{$key});
		}
		print "},\n";
	}
}

# If the number of items is > $words_per_level, we'll partition and recurse.
# The array is partitioned into $words_per_level+1 groups, and we
# recurse with each one.  There are three items:
# ${num}.txt - all keys at this level
# ${num}/(nums).txt - subkeys - recurse into here
# _${num}/(nums).txt - key lookup files - each file has keys for a word

sub part {
	my $num=shift;
	my $items=shift;

	return if (scalar @$items == 0);

	printf STDERR "Num: %d  Items: %d\n", $num, scalar @$items if ($debug);

	my (@mywords, @levelkeys, $level, $word, $spread, $pivot, $subnum, $key, $row);

	if ((scalar @$items) > $words_per_level+1) {
		mkdir "${num}", 0755;
		chdir("${num}");
		printf STDERR "Moving to %d\n", $num if ($debug);
	
		$pivot=int((scalar @$items)/2);

		$spread = (scalar @$items)/($words_per_level+1);
		printf STDERR "WPL: %d  Spread: %.2f\n", $words_per_level, $spread if ($debug);
		push @levelkeys, $pivot;
		for ($level = 1 ; (scalar @levelkeys) < $words_per_level ; $level++) {
			push @levelkeys, $pivot-int($spread*$level);
			push @levelkeys, $pivot+int($spread*$level);
		}

		@levelkeys=sort {$a<=>$b} @levelkeys;
		printf STDERR "Split this level at: %s\n", join(',',@levelkeys) if $debug;

		$subnum=0;
		my ($bottom, $top);

		$bottom=0;
		foreach $level (@levelkeys) {
			$top=$level-1;
			push @mywords, $items->[$level];
			if ($top>$bottom) { part($subnum, [ @$items[$bottom..$top] ]); }
			$subnum++;
			$bottom=$level+1;
		}

		$top=(scalar @$items) - 1;
		part($subnum, [ @$items[$bottom..$top] ]);

		chdir('..');
		printf STDERR "Popping up\n" if ($debug);
	} else {
		@mywords=@$items;
		printf STDERR "Leaf node with %d items\n", scalar @$items if ($debug);
	}

	open F, ">${num}.txt" or die "Cannot write idx file: $!";
	print F "['", join("','",@mywords), "'];";
	close F;
	mkdir "_${num}", 0755;
	for ($subnum = 0; $subnum<scalar @mywords ; $subnum++) {
		open F, ">_${num}/${subnum}.txt" or die "Cannot write key file _${num}/${subnum}.txt: $!";
		print F "{\n";
		$row=0;
		foreach $key (sort keys %{$words{$mywords[$subnum]}}) {
			print F ",\n" if ($row>0);
			printf F "\t%d:%d", $key, $words{$mywords[$subnum]}->{$key};
			$row++;
		}
		print F "\n};";
		close F;
	}
}

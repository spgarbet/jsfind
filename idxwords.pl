#!/usr/bin/perl

use strict;

my $filename_is_key=1;
my $record_position=1;

my (%words,$key);

if ($ARGV[0]) {
	idx_dir([$ARGV[0]]);
	print_idx();
} else {
	die "Usage: $0 directory";
}

sub idx_dir {
	my $path=shift;
	my $dirname=join('/',@$path);

	my $dir;
	opendir $dir, $dirname or die "Cannot open ${dirname}: $!";
	my @files=();

	while (my $file=readdir($dir)) {
		push @files, $file if ($file ne '.' && $file ne '..');;
	}

	closedir $dir;

	foreach my $file (@files) {
		if ( -d "${dirname}/${file}") {
			idx_dir([ @$path, $file]);
		} else {
			idx_file($path,$file);
		}
	}
}

sub idx_file {
	my $path=shift;
	my $filename=shift;
	my $dirname=join('/',@$path);
	open F, "<${dirname}/${filename}"
		or die "Cannot open ${dirname}/${filename}: $!";
	my $allwords=join(' ',<F>);
	close F;

	my $key;
	if ($filename_is_key) {
		($key)=($filename=~m/^(.*?)(?:\.(?:txt|html))$/i);
	} else {
		$key="${dirname}/${filename}";
	}
	my $pos=0;
	$allwords=~s/[^\w_: \-]//g;
	$allwords=lc($allwords);
	my @allwords=split(/\s+/, $allwords);
	foreach my $word (@allwords) {
		if (!exists $words{$word}) { $words{$word}={}; }
		if (!exists $words{$word}->{$key}) {
			if ($record_position) {
				$words{$word}->{$key}=();
			} else {
				$words{$word}->{$key}=0;
			}
		}
		if ($record_position) {
			push @{$words{$word}->{$key}},$pos;
		} else {
			$words{$word}->{$key}++;
		}
		$pos++;
	}
}

my ($row, $keyrow, $posrow);

sub print_idx {
	print "{\n";
	$row=0;
	if ($record_position) {
		foreach my $word (sort keys %words) {
			print ",\n" if ($row>0);
			print "'$word': {\n";
			$keyrow=0;
			foreach my $key (sort keys %{$words{$word}}) {
				print ",\n" if ($keyrow>0);
				print "\t'$key': [";
				print join(',',@{$words{$word}->{$key}});
				print "]";
				$keyrow++;
			}
			print "\n}";
			$row++;
		}
	} else {
		foreach my $word (sort keys %words) {
			print ",\n" if ($row>0);
			print "'$word': {\n";
			$keyrow=0;
			foreach my $key (sort keys %{$words{$word}}) {
				print ",\n" if ($keyrow>0);
				print "\t'$key': ";
				print $words{$word}->{$key};
				$keyrow++;
			}
			print "\n}";
			$row++;
		}
	}
	print "\n};\n";
}

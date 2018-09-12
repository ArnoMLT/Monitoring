#!/usr/bin/perl


use strict;
use warnings;

our $global_opts;

sub source {
    my $name = shift;

    open my $fh, "<", $name
        or die "could not open $name: $!";

    while (<$fh>) {
        chomp;

		if ($_ !~ /^[^[:print:]]*\s*[#]/ && $_ !~ /^[^[:print:]]*\s*$/){
			my ($k, $v) = split /=/, $_, 2;
			$v =~ s/^(['"])(.*)\1/$2/; #' fix highlighter
			$global_opts->{$k} = $v;
		}
    }
	close $fh;
}

source "/usr/lib/nagios/plugins/itbs/etc/config.cfg";

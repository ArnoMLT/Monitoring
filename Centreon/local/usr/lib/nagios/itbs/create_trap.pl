#!/usr/bin/perl

# Usage :
# create_trap.pl <hostname> <trapfile_content>

my $spoolFolder = "/var/spool/centreontrapd/"; # ajouter les droits en modif sur le repertoire
#my $spoolFolder = "/tmp/";

# hostname (1er arg)
$hostname = shift(@ARGV) // "debug";
$trapfile_name = "$hostname-" . time;

print $trapfile_name;

# reste des arguments
$trap_content = join(" ", @ARGV);

#separation des lignes suivant le marqueur "??"
my $trapfile_content = "";
my @trapsplit = split (/\?\?/, $trap_content);
foreach (@trapsplit) {
	$trapfile_content .= "$_\n";
}

my $TRAP_FILE = "${spoolFolder}${trapfile_name}"; # chemin

#print "\ntrapfile_name : $trapfile_name\n\n\n";
#print "\nTRAP_FILE : $TRAP_FILE\n";

open(TRAPFILE, "> $TRAP_FILE");

print(TRAPFILE $trapfile_content);

close(TRAPFILE);


# $1 = host, $2 = service, $3 = trap
#printf "[%lu] PROCESS_SERVICE_CHECK_RESULT;$1;$2;$status;$3" $now > $commandfile
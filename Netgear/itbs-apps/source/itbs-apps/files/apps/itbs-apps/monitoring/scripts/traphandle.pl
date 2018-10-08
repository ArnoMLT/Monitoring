#!/usr/bin/perl

# ITBS - 13/04/2018
# v 1.0

# Traphandler pour snmptrapd
# Permet l'envoi d'un rapport NSCA (NAGIOS)
# d'apres la trap SNMP recue sur <STDIN>

use strict;
use Sys::Hostname;

################################
################################

# Valeurs par defaut
our $hostname = hostname;
our $result   = "3";
our $alias    = "test_nsca";
our $dstHostname = "178.23.36.169";
our $configFile = "/etc/send_nsca.cfg";
our $send_nsca = "send_nsca -H $dstHostname -c $configFile";

# Surcharge avec les variable du fichier de conf
do "/apps/itbs-apps/monitoring/config/traphandle.conf";

################################
################################

local $/ = "\n";

my $timestamp = time;

#my $timestamprandom = time . (int(rand(899999)) + 100000);  # FILE
#my $trapfile_name = "nsclient-trap-$timestamprandom";       # FILE

#my $TRAP_FILE = "/tmp/$trapfile_name";                      # FILE
my $trapfile_content = "$timestamp??";

#open(TRAPFILE, "> $TRAP_FILE");                             # FILE

#print(TRAPFILE "$timestamp\n");                             # FILE

# Lit <STDIN>, supprime le caractere de fin de ligne, et annule les quotes
# Place le code '??' pour marquer la fin de ligne (caracteres interdits dans centreon)
while(<STDIN>) {
	$_ =~ s/\r?\n$//;
	$_ =~ s/"/\\"/g;
	$_ =~ s/'/\\'/g;
#	print(TRAPFILE "$_\n");                                 # FILE
	$trapfile_content .= "$_??";
}

#close(TRAPFILE);                                            # FILE

# creation de la commandline pour send_nsca
my $message  = "$trapfile_content";
my $commandLine = "printf \"%s\t%s\t%s\t%s\n\" \"$hostname\" \"$alias\" \"$result\" \"$message\" \| $send_nsca";
print "$commandLine\n";  # DEBUG

# Envoi du rapport
system ($commandLine);

#!/bin/perl

use strict;
use warnings;

use Data::Dumper;

use File::Basename;
use Cwd qw(abs_path);
use lib dirname (abs_path(__FILE__));
use NSClient;


my $nsclient = NSClient->new();


my $fichier_nsclient = '/cygdrive/c/Users/MLT/Desktop/nsclient.ini';
if ($nsclient->read_from_file ($fichier_nsclient)){
	print "OK\n";
	
}else{
	print "KO\n";
}

#my $string = "{settings}{default}";
#print $tab_config->$string;

#print Dumper(get_section_href($tab_config, "/settings/nrpe"));

print Dumper($nsclient->{config_href});
#print Dumper(get_section_href($tab_config, "/settings/scheduler/schedules"));

my $hash_test = {settings=>
					{
						nrpe=>{
							default => {
								key1=>"value1",
								key2=>"value2"
							},
							config => {}
						}
					}
				};
#merge_hash($tab_config, $hash_test);
#print Dumper($tab_config);
	
#print Dumper(get_section_href($tab_config, "/settings/nrpe"));
#print Dumper(get_section_value($tab_config, "/settings/nrpe/default", "key2"));

print "============= ECRITURE =================\n";

$nsclient->write_to_file ("/cygdrive/c/Users/MLT/Desktop/nsclient_new.ini");
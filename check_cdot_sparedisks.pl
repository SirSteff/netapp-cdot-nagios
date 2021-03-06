#!/usr/bin/perl

# --
# check_cdot_sparedisk - Check NetApp System Spare Disks
# Copyright (C) 2013 noris network AG, http://www.noris.net/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl.txt.
# --

use strict;
use warnings;

use lib "/usr/lib/netapp-manageability-sdk-5.1/lib/perl/NetApp";
use NaServer;
use NaElement;
use Getopt::Long;

GetOptions(
    'hostname=s' => \my $Hostname,
    'username=s' => \my $Username,
    'password=s' => \my $Password,
    'help|?'     => sub { exec perldoc => -F => $0 or die "Cannot execute perldoc: $!\n"; },
) or Error("$0: Error in command line arguments\n");

sub Error {
    print "$0: " . $_[0] . "\n";
    exit 2;
}
Error('Option --hostname needed!') unless $Hostname;
Error('Option --username needed!') unless $Username;
Error('Option --password needed!') unless $Password;

my $s = NaServer->new( $Hostname, 1, 3 );
$s->set_transport_type("HTTPS");
$s->set_style("LOGIN");
$s->set_admin_user( $Username, $Password );

my $output = $s->invoke("storage-disk-get-iter");

if ($output->results_errno != 0) {
    my $r = $output->results_reason();
    print "UNKNOWN: $r\n";
    exit 3;
}

my $disks = $output->child_get("attributes-list");
my @result = $disks->children_get();

my $not_zeroed;

foreach my $disk (@result) {

    my $raid_info = $disk->child_get("disk-raid-info");
    my $type = $raid_info->child_get_string("container-type");

    if($type eq "spare"){
        my $spare_info = $raid_info->child_get("disk-spare-info");
        my $zeroed = $spare_info->child_get_string('is-zeroed');

        if($zeroed eq "false"){
            $not_zeroed++;
        }
    }
}

if ($not_zeroed){
    print "$not_zeroed spare disk(s) not zeroed\n";
    exit 2;
}
else {
    print "All spare disks zeroed\n";
    exit 0;
}

__END__

=encoding utf8

=head1 NAME

check_cdot_spare_disk - Checks Spare Disks

=head1 SYNOPSIS

check_cdot_sparedisk.pl --hostname HOSTNAME \
    --username USERNAME --password PASSWORD

=head1 DESCRIPTION

Checks if there are some nonzeroed disks

=head1 OPTIONS

=over 4

=item --hostname FQDN

The Hostname of the NetApp to monitor

=item --username USERNAME

The Login Username of the NetApp to monitor

=item --password PASSWORD

The Login Password of the NetApp to monitor

=item -help

=item -?

to see this Documentation

=back

=head1 EXIT CODE

3 if timeout occured
2 if there are some nonzeroed disks
0 if everything is ok

=head1 AUTHORS

 Alexander Krogloth <git at krogloth.de>


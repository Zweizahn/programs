#!/usr/bin/perl
#
# Last change 	23.Jul 2013
# Author	Erik Blosze
#
use strict;
use warnings;
use feature ':5.10';

# Definition  scalar variables: _U means upstream, _D downstream
my $NrOutlines  = 0;
my $NrLines     = 0;
my $NrMalLines  = 0;
my $NrUp        = 0;
my $NrDown      = 0;
# Definition  result hashes
my (%WWPN_U, %LUNs_U, %VIDs_U, %Targets_U);
my (%WWPN_D, %LUNs_D, %VIDs_D, %Targets_D);

#### Subroutines ####
sub CONVERT	# Extracts data inbetween the brackets []
{
	my $A = shift;
 	chop($A);		# removes the trailing ] bracket
	my @C = split(/\[/,$A); # Removes everything from the start of the string till [
	return $C[1];
}

sub INSERT 	# Inserts the data and increases the count
{
	my ($WWPN, $ARRAY) = @_;
	my @KEYS   = keys %$ARRAY;
	my $ADD    = "YES";
	foreach my $KEY (@KEYS) {
		if ($WWPN eq $KEY) {
			$ARRAY->{$KEY}++;
			$ADD = "NO";
			last;
		}
	}

	if ($ADD eq "YES") {
		$ARRAY->{$WWPN} = 1;
	}
	return;
}

sub OUTPUT	# Prints the output
{
	my ($TEXT,$HASH) = @_;
	say "** $TEXT **";
# Next sort is 1. numerical for value, 2. string for key
	foreach (sort {($HASH->{$a} <=> $HASH->{$b}) || ($a cmp $b)} keys %$HASH) {
		printf "%-23s %11d\n",$_,$HASH->{$_};
	}
	say "";
	return;
}

#### Main programm ####
my $LENGHT=scalar @ARGV;
if ($LENGHT == 0) {
	die "Usage: countwwpn.pl <messages file>"
}


my $FILE=$ARGV[0];
open my $FILEHANDLE,$FILE or die "File \"$FILE\" does not exist\n";	#Check if file exists
if (-d $FILE) {
	 die "File \"$FILE\" is not a file but a directory\n";
}


while (<$FILEHANDLE>) {
	$NrLines++;
	if (!m/SCSI command abort/) {next}; 	#Leave while loop if no SCSI command abort can be found
	chomp;
	my @FIELDS = split;
	my $LENGTH = scalar @FIELDS;
	if ($LENGTH < 14) {next}; 		#Leave while loop if no SCSI command abort can be found
	my $STATUS = $FIELDS[13];
	my $WWPN   = CONVERT($FIELDS[14]);
	my $TARGET = CONVERT($FIELDS[17]);
	my $LUN    = CONVERT($FIELDS[11]);
	my $VID    = CONVERT($FIELDS[12]);
	if ($STATUS =~ /80000/) { 		#Downstream
		$NrOutlines++;
		$NrDown++;
		if (defined ($WWPN)) {INSERT($WWPN,\%WWPN_D);}
		if (defined ($TARGET)) {INSERT($TARGET,\%Targets_D);}
		INSERT($LUN,\%LUNs_D);
		INSERT($VID,\%VIDs_D);
	} elsif ($STATUS =~ /200000/) { 	#Upstream
		$NrOutlines++;
		$NrUp++;
		if (defined ($WWPN)) {INSERT($WWPN,\%WWPN_U);}
		if (defined ($TARGET)) {INSERT($TARGET,\%Targets_U);}
		INSERT($LUN,\%LUNs_U);
		INSERT($VID,\%VIDs_U);
	} else {				# Something wrong with the format of the input line
		say "Wrong format in line $NrLines";
		$NrMalLines++;
	}
}
close $FILEHANDLE;

# Output
say "** Downstream *******************************************************";
OUTPUT("Client WWPNs",\%WWPN_D);
OUTPUT("Target WWPNs",\%Targets_D);
OUTPUT("VIDs",\%VIDs_D);
OUTPUT("LUNs",\%LUNs_D);
say "** Upstream *********************************************************";
OUTPUT("Client WWPNs",\%WWPN_U);
OUTPUT("Target WWPNs",\%Targets_U);
OUTPUT("VIDs",\%VIDs_U);
printf "%-24s %10d\n","Nummer of total lines:",$NrLines;
printf "%-26s %8d\n","Nummer of processed lines:",$NrOutlines;
printf "%-26s %6d\n","Nummer of malformated lines:",$NrMalLines;
printf "%-25s %8d\n","Number of upstream aborts:",$NrUp;
printf "%-26s %6d\n","Number of downstream aborts:",$NrDown;

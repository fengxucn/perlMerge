#!/usr/bin/perl -w
#find overlap
use warnings;
use strict;

my $usage =
"Usages:\nperl findOverlap.pl first_file_loction [key_index start_index end_index] second_file_loction [key_index start_index end_index] output_File_Name
the default values: key_index = 0, start_index = 1, end_index = 2, output_File_Name = first_file_loction.out
so the simple usage is:\nperl findOverlap.pl first_file_loction second_file_loction
for example: 
perl findOverlap.pl D:/A.txt D:/B.txt
or
perl findOverlap.pl D:/A.txt D:/B.txt output.txt
or
perl findOverlap.pl D:/A.txt 0 1 2 D:/B.txt 0 1 2 output.txt\n";

my $first_file  = "";
my $first_key   = 0;
my $first_start = 1;
my $first_end   = 2;

my $second_file  = "";
my $second_key   = 0;
my $second_start = 1;
my $second_end   = 2;

my $outputFile = $first_file . ".out";

if ( @ARGV < 2 ) {
	print $usage;
	exit;
}
elsif ( @ARGV == 2 ) {
	$first_file  = $ARGV[0];
	$second_file = $ARGV[1];
	$outputFile = $first_file . ".out";
}
elsif ( @ARGV == 3 ) {
	$first_file  = $ARGV[0];
	$second_file = $ARGV[1];
	$outputFile  = $ARGV[2];
}
elsif ( @ARGV == 9 ) {
	$first_file  = $ARGV[0];
	$first_key   = $ARGV[1];
	$first_start = $ARGV[2];
	$first_end   = $ARGV[3];

	$second_file  = $ARGV[4];
	$second_key   = $ARGV[5];
	$second_start = $ARGV[6];
	$second_end   = $ARGV[7];
	$outputFile   = $ARGV[8];
}
else {
	print $usage;
	exit;
}


open( FIRST_FILE, $first_file ) or die( "can not open " . $first_file . "\n" );

open( OUTPUT, ">" . $outputFile ) or die( "can not open " . $outputFile . "\n" );

my $head_1 = <FIRST_FILE>;    # read the table head
$head_1 =~ s/[\n\r]+/\t/g;

my $counter = 0;
my @table_content;
my %key_range_hash;           #HashTable storage the {key = [start, end], ...}

print "Build the Hash Index...\n";

while ( my $line = <FIRST_FILE> ) {
	my @datas = split( /\s+/, $line );

	my $key   = $datas[$first_key];
	my $start = $datas[$first_start];
	my $end   = $datas[$first_end];

	my $table_content_size = @table_content;
	my @range = ( $start, $end, $table_content_size );
	$line =~ s/[\n\r]+/\t/g;
	push( @table_content, $line );

	my @ranges = ();
	if ( exists $key_range_hash{$key} ) {
		@ranges = @{ $key_range_hash{$key} };
	}

	push( @ranges, @range );
	$key_range_hash{$key} = [@ranges];

	$counter++;
	if ( $counter % 10000 == 0 ) {
		print $counter. "...\n";
	}
}

print $counter. "...\n";
close(FIRST_FILE);

open( SECOND_FILE, $second_file ) or die( "can not open " . $second_file . "\n" );

$counter = 0;
my $head_2 = <SECOND_FILE>;    # read the table head
$head_2 =~ s/[\n\r]+/\t/g;
print OUTPUT ( $head_1, $head_2, "union_start\tunion_end\tintersection_start\tintersection_end", "\n" );
print "Read the second file...\n";
while ( my $line = <SECOND_FILE> ) {
	my @datas = split( /\s+/, $line );

	my $key   = $datas[$second_key];
	my $start = $datas[$second_start];
	my $end   = $datas[$second_end];

    if(!exists $key_range_hash{$key}){
    	next;
    }

	my @range = @{ $key_range_hash{$key} };

	$line =~ s/[\n\r]+/\t/g;

	my $index = 0;
	while ( $index < @range ) {

		my $flag = isOverlap( $range[$index], $range[ $index + 1 ], $start, $end );

		if ( $flag eq "true" ) {
			my @minmax = getMinMax( $range[$index], $range[ $index + 1 ], $start, $end );
			my @inter  = getIntersection( $range[$index], $range[ $index + 1 ], $start, $end );
			my $str_output = $table_content[ $range[ $index + 2 ] ] . "\t" . $line . "\t" . $minmax[0] . "\t" . $minmax[1] . "\t"  . $inter[0] . "\t" . $inter[1] . "\n";
			$str_output =~ s/\t\t/\t/g;
			print OUTPUT ($str_output);
		}

		$index = $index + 3;
	}

	$counter++;
	if ( $counter % 10000 == 0 ) {
		print $counter. "...\n";
	}
}
print $counter. "...\n";
close(SECOND_FILE);
close(OUTPUT);
print "Finish\n";

sub isOverlap {
	my ( $start_1, $end_1, $start_2, $end_2 ) = @_;
	if (   ( $start_1 <= $start_2 && $end_1 >= $start_2 )
		|| ( $start_1 <= $end_2   && $end_1 >= $end_2 )
		|| ( $start_2 <= $start_1 && $end_2 >= $end_1 ) )
	{
		"true";
	}
	else {
		"false";
	}
}

sub getMinMax {
	my (@list) = @_;
	my $min    = $list[0];
	my $max    = $list[0];

	my $index = 1;
	while ( $index < @list ) {
		if ( $min > $list[$index] ) {
			$min = $list[$index];
		}

		if ( $max < $list[$index] ) {
			$max = $list[$index];
		}

		$index++;
	}

	my @minmax = ( $min, $max );
}

sub getIntersection {
	my ( $start_1, $end_1, $start_2, $end_2 ) = @_;
	my $min    = $start_1;
	my $max    = $end_1;

    if($min < $start_2){
    	$min = $start_2;
    }
    
    if($max > $end_2){
    	$max = $end_2;
    }
	

	my @minmax = ( $min, $max );
}


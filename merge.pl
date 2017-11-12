#find NoOverlap
use warnings;
use strict;
use File::Basename;



my $usage =
"Info: TODO:
verion: 0.2.5
Usages:\nperl merge.pl -p [fdr or fc] -i inputFiles... -o outputfile(two output files: union, intersect)...
for example: 
perl merge.pl -p fdr -i D:/B.txt D:/C.txt -o D:/union.txt D:/inofc.txt\n";

#start process the input paremeters

my @inputFiles;

my $first_file  = "";
my $first_key   = 0;
my $first_start = 1;
my $first_end   = 2;

my @outputFile;
my $file_number = 0;
my $outFile_number = 0;
my $p;
#check the paremeter
if ( @ARGV < 3 ) {
	print $usage;
	exit;
}

for(my $i = 0; $i < @ARGV;){
	if ( $ARGV[$i] eq "-i" ) {
	    $i++;
	    while($ARGV[$i] ne "-o" && $i < @ARGV){
	    	    $inputFiles[$file_number++] = $ARGV[$i++];
	    }
    }elsif($ARGV[$i] eq "-o"){
	    $i++;
	    while($ARGV[$i] ne "-i" && $i < @ARGV){
	    	    $outputFile[$outFile_number++] = $ARGV[$i++];
	    }
    }elsif($ARGV[$i] eq "-p"){
	    $i++;
	    $p = $ARGV[$i++];
    }else{
	    print $usage;
	    exit;
    }
}

if ( $outFile_number != 2 ) {
	print $usage;
	exit;
}

#Finish


my %key_range_hash;           #HashTable storage the {key = [chr, start, end, FDR, 1, 1...], ...}
#read the files
for(my $i = 0; $i < $file_number; $i++){
	my $inputFile = $inputFiles[$i];
	print "read the file $inputFile\n";
	open( INPUT_FILE, $inputFile ) or die( "can not open " . $inputFile . "\n" );
    my $head_1 = <INPUT_FILE>;    # read the table head
    
    
	while ( my $line = <INPUT_FILE> ) {
	    my @datas = split( /\s+/, $line );
	    my $key = $datas[0];
	    my $start = $datas[1];
	    my $end = $datas[2];
	    my $f = $datas[4];  #FDR
	    my $fc = $datas[3];
	    
	    if($f eq "NA"){ # When FDR is NA, set FDR=0
	    	    $f = 0;
	    }
	    
	    if($fc eq "NA"){ # When FC is NA, set FC=0
	    	    $fc = 0;
	    }
	
	    my @ranges = ();
	    if ( exists $key_range_hash{$key} ) {
		     @ranges = @{ $key_range_hash{$key} };
	    }else{
	    	    for(my $k = 0; $k < $file_number; $k++){# fill the array with 1,0 or FDR and FC
	    	    	    my $l = 2*$k + 3;
        	    	 	if($l == 2*$i + 3){#the column of current file, for each file there has two columns so 2*$i
        	    	    		$datas[$l] = $f;
        	    	    		$datas[$l+1] = $fc;
        	    	    	}else{              #the column of other files
        	    	    		$datas[$l] = 1; # FDR=1
        	    	    		$datas[$l+1] = 0;# logFC=0
        	    	    	}
        	    	}
        	    	push( @ranges, \@datas );
        	    $key_range_hash{$key} = [@ranges];
        	    next;
	    }
	    
	    #sort by start
	    @ranges = sort { $a->[1] <=> $b->[1] }  @ranges;

        my $n = @ranges;
        my $needInsert = "true";
        for(my $j = 0; $j < $n; $j++){
        	    my @range = @{$ranges[$j]};
        	    my $hasOverlap = isOverlap( $range[$first_start], $range[ $first_end], $start, $end );
        	    
        	    if ( $hasOverlap eq "true" ) {
        	    	    $ranges[$j][2*$i + 3] = $f;
        	    	    $ranges[$j][2*$i + 4] = $fc;
        	    	    my @minMax = getMinMax($range[$first_start], $range[ $first_end], $start, $end);
        	    	    $ranges[$j][1] = $minMax[0];
        	    	    $ranges[$j][2] = $minMax[1];
        	    	    $needInsert = "false";
        	    	    last;
        	    }elsif($end < $range[$first_start]){
        	    	    	last;
        	    }
        }
        
        if($needInsert eq "true"){
        		for(my $k = 0; $k < $file_number; $k++){# fill the array with 1,0 or FDR and FC
	    	    	        my $l = 2*$k + 3;
        	    	 	    if($l == 2*$i + 3){#the column of current file, for each file there has two columns so 2*$i
        	    	    		    $datas[$l] = $f;
        	    	    	     	$datas[$l+1] = $fc;
        	    	     	}else{              #the column of other files
        	    	    		    $datas[$l] = 1; # FDR=1
        	    	    		    $datas[$l+1] = 0;# logFC=0
        	    	       	}
        	    	}
        	    	push( @ranges, \@datas );
        }
        
	    $key_range_hash{$key} = [@ranges];
    }
    
    close(INPUT_FILE);
    
}

#put out the result
print "Write the data to $outputFile[0]\n";
print "Write the data to $outputFile[1]\n";
open( OUTPUT, ">" . $outputFile[0] ) or die( "can not open " . $outputFile[0] . "\n" );
open( OUTPUT1, ">" . $outputFile[1]) or die( "can not open " . $outputFile[1]. "\n" );

#print header
print OUTPUT ( "chr\tstart\tend\t");
print OUTPUT1 ( "chr\tstart\tend\t");

for(my $i = 0; $i < $file_number; $i++){
	my $name = basename($inputFiles[$i]);
	$name =~ s{\.[^.]+$}{};
	print OUTPUT ( $name,"FDR\t");
	print OUTPUT1 ( $name,"FDR\t");
	
	print OUTPUT ( $name,"FC\t");
	print OUTPUT1 ( $name,"FC\t");
}

print OUTPUT ("sumFDR\tsumFC\n");
print OUTPUT1 ("sumFDR\tsumFC\n");

#sort by sum(FDR1, FDR2, FDR3,...)
my @outCome;
my $totalNumber = 0;
foreach my $key (keys %key_range_hash) { 
	my @ranges = @{ $key_range_hash{$key} }; 
	for(my $i = 0; $i < @ranges; $i++){
		my @range = @{ $ranges[$i] };
		$totalNumber = @range;
		my $fdrSum = 0;
		my $fcSum = 0;
		for(my $j = 3; $j < @range; $j=$j+2){
			$fdrSum = $fdrSum + $range[$j];
			$fcSum = $fcSum + abs($range[$j+1]);
		}
		$ranges[$i][$totalNumber++] = $fdrSum;
		$ranges[$i][$totalNumber++] = $fcSum;
	}
	
	push(@outCome, @ranges);
}

if($p eq "fdr"){
	@outCome = sort {$a->[$totalNumber -2] <=> $b->[$totalNumber -2]} @outCome;
}elsif($p eq "fc"){
	@outCome = sort {$b->[$totalNumber -1] <=> $a->[$totalNumber -1]} @outCome;
}

#print body 
	for(my $i = 0; $i < @outCome; $i++){
		my @range = @{ $outCome[$i] };
		my $allFDR = "true";
		my $allFC = "true";
		for(my $j = 3; $j < @range - 1; $j = $j+2){
			if($range[$j] == 1){
				$allFDR = "false";
				last;
			}
		}
		for(my $j = 3; $j < @range - 1; $j = $j+2){
			if($range[$j + 1] == 0){
				$allFC = "false";
				last;
			}
		}
		for(my $j = 0; $j < @range; $j++){
			print OUTPUT ( $range[$j],"\t");
			if($allFDR eq "true" && $p eq "fdr"){
				print OUTPUT1 ( $range[$j],"\t");
			}elsif($allFC eq "true" && $p eq "fc"){
				print OUTPUT1 ( $range[$j],"\t");
			}
		}
		print OUTPUT ("\n");
		if($allFDR  eq "true"){
		    print OUTPUT1 ("\n");
		}
	}


close(OUTPUT);
close(OUTPUT1);

print "Finish.\n";

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


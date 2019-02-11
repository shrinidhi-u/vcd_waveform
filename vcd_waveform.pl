#!/usr/bin/env perl

use Data::Dumper;
use feature 'say';
use warnings;
use strict;
use diagnostics;
use Verilog::VCD qw(parse_vcd);

my $file = shift;
my $vcd = parse_vcd($file);
#print "$vcd \n";
#say Dumper($vcd);

my $max_count=0;
my $max_time=0;
my %new_table={};

for my $code (keys %{$vcd }) {
  if ($vcd->{$code}->{tv} eq undef){
      next;
    }
 my @tmp_array=@{$vcd->{$code}->{tv}};
    if ( $tmp_array[$#tmp_array][0] > $max_count) {
    $max_count =$tmp_array[$#tmp_array][0] ; # Get the latest time point by checking if the latest timepoint in the current tv pair is later than the max_count
    }
}

for my $code (keys %{$vcd }) { # Loop 1 : For each key in the hash table generated for the vcd file
                               #          Each key value consists of two parts - 'tv' and 'nets'
                               #          'tv' holds the time value combinations. The values are vectors fundamentally and hence, need to be analyzed later in one of the loops.
                               #          'nets' contains the name and size information.
                               # At End of each loop : A bit level time-value combination for each timepoint from 0 to $max_count, for each bit of the vector represented by the key.
my @net = @{ $vcd->{$code}->{nets} };


  if ($vcd->{$code}->{tv} eq undef){    # Checking if the 'tv' value for the key is empty. This meanings no timing information provided for the net.
      next;
  }
my @tv_array= @{$vcd->{$code}->{tv}};
   # say Dumper(@tv_array);
	my $start_time= 0;
	my $end_time  = $max_count;

	#print "$start_time $end_time \n";
    for my $vector_index (1.. $net[0]->{size}){  # Loop 2 :  Iteration in each key based on the size of the value vector of 'tv'.
                                                 #           Each vector position is handled separately and later assigned to the corresponding index of the array signal.
                                                 # At End of each Loop : An array of values corresponding to one bit of a signal vector representing value assignment from 0 to the maximum time $max_count.
	my $prev_value=0;
	my $vector_in= $vector_index -1 ;
	my $next_change_time_index=0;
	for my $time ($start_time .. $end_time){          # Loop 3 : Iteration over time.
                                                   #          The time value combination is provided by the VCD file only if there is a change.
                                                   #           Hence, the timepoints where there is no change need to be filled with the last changed value.
                                                   # At End of Each loop: The time-value vector for each bit moves ahead 1 timepoint.



	  
	  if($net[0]->{size} == 1){           # Signals which are single bit wide are handled differently.

										if($tv_array[$next_change_time_index][0]==$time){                          # Check if we have iterated to the point of next change
														$new_table{"$net[0]->{hier}.$net[0]->{name}"}[$time]=$tv_array[$next_change_time_index][1];           # If yes, append the new value to our hash table "new_table" under the hash key of the name of the signal
														$prev_value=$tv_array[$next_change_time_index][1];                              # to the set of time ordered values. Update the prev_value variable and increment the next change index to point to the next element in the tv array.
														$next_change_time_index++;
										#   print "$net[0]->{hier}.$net[0]->{name}\n";
										}
										else{                                                                               # If not there yet, append last changed value.
														$new_table{"$net[0]->{hier}.$net[0]->{name}"}[$time]=$prev_value;
										}
				}
	   else{
								if($tv_array[$next_change_time_index][0]==$time){	                         # Similiar to previous if statement except that this is executed for vectors
								#print "vector_in $vector_in\n";
								#print "$tv_array[$next_change_time_index][1]\n";

										my $filter_bit= int ($tv_array[$next_change_time_index][1] / (10 ** $vector_in));      # We find the vector_in-th character in the tv value for vectors - a string.
										my $bit =0;                                                                            # The string character will be converted to integer.
										if(($filter_bit % 10)==1){
														$bit = 1;
												}                                                                                     
										# print "$bit \n";
												$new_table{"$net[0]->{hier}.$net[0]->{name}\(".$vector_in.')'}[$time]=$bit;   
												$prev_value=$bit;
												$next_change_time_index++;
										#  print "$net[0]->{hier}.$net[0]->{name}";		      
										#  print "\[$vector_in\]\n";
										}
								else{
												$new_table{"$net[0]->{hier}.$net[0]->{name}\(".$vector_in.')'}[$time]=$prev_value;
										}
	   }
	}
  }

}
my @key_s = sort { $a cmp $b } keys %new_table;
#print "Final table \n";
#say Dumper\@key_s;


foreach my $key (sort keys %new_table){
print "$key";
 foreach my $element ($new_table{$key}){
    my @tmp_element=$element;
    for my $ele_count (0..$max_count){
    print ",";
    print $tmp_element[0][$ele_count];
    
    }
  print "\n";
  }
}


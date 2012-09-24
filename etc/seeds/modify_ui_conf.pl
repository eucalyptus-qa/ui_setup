#!/usr/bin/perl
use strict;
use Cwd;

$ENV{'PWD'} = getcwd();

# does_It_Have( $arg1, $arg2 )
# does the string $arg1 have $arg2 in it ??
sub does_It_Have{
	my ($string, $target) = @_;
	if( $string =~ /$target/ ){
		return 1;
	};
	return 0;
};


print "\n";
print "#################### modify_ui_conf.pl ##########################\n";
print "\n";

print "#################### READ INPUT FILE ##########################\n";
print "\n";

my @ip_lst;
my @distro_lst;
my @version_lst;
my @arch_lst;
my @source_lst;
my @roll_lst;

my %cc_lst;
my %sc_lst;
my %nc_lst;

my $clc_index = -1;
my $cc_index = -1;
my $sc_index = -1;
my $ws_index = -1;

my $clc_ip = "";
my $cc_ip = "";
my $sc_ip = "";
my $ws_ip = "";

my $nc_ip = "";

my $max_cc_num = 0;

$ENV{'EUCALYPTUS'} = "/opt/eucalyptus";

#### read the input list

my $index = 0;

my $is_memo;
my $memo = "";

open( LIST, "./2b_tested.lst" ) or die "$!";
my $line;
while( $line = <LIST> ){
	chomp($line);

	if( $is_memo ){
		if( $line ne "END_MEMO" ){
			$memo .= $line . "\n";
		};
	};

	if( $line =~ /^([\d\.]+)\t(.+)\t(.+)\t(\d+)\t(.+)\t\[([\w\s\d]+)\]/ ){
		print "IP $1 with $2 distro was built from $5 as Eucalyptus-$6\n";

		if( !( $2 eq "VMWARE" || $2 eq "WINDOWS" ) ){

			push( @ip_lst, $1 );
			push( @distro_lst, $2 );
			push( @version_lst, $3 );
			push( @arch_lst, $4 );
			push( @source_lst, $5 );
			push( @roll_lst, $6 );

			my $this_roll = $6;

			if( does_It_Have($this_roll, "CLC") && $clc_ip eq "" ){
				$clc_index = $index;
				$clc_ip = $1;
			};

			if( does_It_Have($this_roll, "CC") ){
				$cc_index = $index;
				$cc_ip = $1;

				if( $this_roll =~ /CC(\d+)/ ){
					$cc_lst{"CC_$1"} = $cc_ip;
					if( $1 > $max_cc_num ){
						$max_cc_num = $1;
					};
				};			
			};

			if( does_It_Have($this_roll, "SC") ){
				$sc_index = $index;
				$sc_ip = $1;

				if( $this_roll =~ /SC(\d+)/ ){
	                                $sc_lst{"SC_$1"} = $sc_ip;
	                        };
			};

			if( does_It_Have($this_roll, "WS") ){
	                        $ws_index = $index;
	                        $ws_ip = $1;
	                };

			if( does_It_Have($this_roll, "NC") ){
	                        #$nc_ip = $nc_ip . " " . $1;
				$nc_ip = $1;
				if( $this_roll =~ /NC(\d+)/ ){
					if( $nc_lst{"NC_$1"} eq	 "" ){
	                                	$nc_lst{"NC_$1"} = $nc_ip;
					}else{
						$nc_lst{"NC_$1"} = $nc_lst{"NC_$1"} . " " . $nc_ip;
					};
	                        };
	                };

			$index++;

		};

	}elsif( $line =~ /^MEMO/ ){
		$is_memo = 1;
	}elsif( $line =~ /^END_MEMO/ ){
		$is_memo = 0;
	};

};

close( LIST );

$ENV{'QA_MEMO'} = $memo;

if( $clc_ip eq "" ){
	print "Could not find the IP of CLC\n";
};

if( $cc_ip eq "" ){
        print "Could not find the IP of CC\n";
};

if( $sc_ip eq "" ){
        print "Could not find the IP of SC\n";
};

if( $ws_ip eq "" ){
        print "Could not find the IP of WS\n";
};

if( $nc_ip eq "" ){
        print "Could not find the IP of NC\n";
};

chomp($nc_ip);


print "\n";
print "#################### KILL RUNNING UI ##########################\n";
print "\n";

print "Display Running UI\n";
my $cmd = "ps aux | grep euca-console-server ";
print "$cmd\n";
system($cmd);
print "\n";

print "Discover and Kill Running UI\n";
$cmd = "ps aux | grep euca-console-server | awk '{print \$2}'";
print "$cmd\n";

my $tempbuf = `$cmd`;
my @temparray = split("\n", $tempbuf);
foreach my $pid (@temparray){
	$cmd = "kill -9 $pid";
	print $cmd . "\n";
	system($cmd);
};
print "\n";

print "Verify Killed UI\n";
$cmd = "ps aux | grep euca-console-server ";
print "$cmd\n";
system($cmd);
print "\n";


print "\n";
print "#################### MODIFY UI CONFIG FILE ##########################\n";
print "\n";

my $ui_conf_file = "";

if( $source_lst[$clc_index] eq "BZR" || $source_lst[$clc_index] eq "SRC" ){
	$ui_conf_file = "/root/euca_builder/eee/eucalyptus-ui/server/console.ini";
}else{
	if( $distro_lst[$clc_index] eq "UBUNTU" ){
		$ui_conf_file = "/etc/eucalyptus-ui/console.ini";		### INCORRECT FOR NOW 092012
	}else{
		$ui_conf_file = "/etc/eucalyptus-ui/console.ini";
	};
};


print "=========== BEFORE MODIFICATION ==========\n";
print "\n";

print "Scan Existing UI Config File for \'clchost\'\n";
$cmd = "cat $ui_conf_file | grep clchost";
print "$cmd\n";
system($cmd);
print "\n";

print "Scan Existing UI Config File for \'usemock\'\n";
$cmd = "cat $ui_conf_file | grep usemock";
print "$cmd\n";
system($cmd);
print "\n";

my_sed("clchost: .*", "clchost: $clc_ip", $ui_conf_file);
my_sed("usemock: .*", "usemock: False", $ui_conf_file);

print "=========== AFTER MODIFICATION ==========\n";
print "\n";

print "Scan Existing UI Config File for \'clchost\'\n";
$cmd = "cat $ui_conf_file | grep clchost";
print "$cmd\n";
system($cmd);
print "\n";

print "Scan Existing UI Config File for \'usemock\'\n";
$cmd = "cat $ui_conf_file | grep usemock";
print "$cmd\n";
system($cmd);
print "\n";


print "\n";
print "#################### RESTART UI ##########################\n";
print "\n";

print "Restart UI\n";
if( $source_lst[$clc_index] eq "BZR" || $source_lst[$clc_index] eq "SRC" ){
	$cmd = "cd /root/euca_builder/eee/eucalyptus-ui; nohup ./launcher.sh > /dev/null 2> /dev/null \&";
}else{
	$cmd = "service eucalyptus-console restart";
};

print "$cmd\n";
system($cmd);
print "\n";

print "\n";
print "[TEST_REPORT]\tCOMPLETE MODIFY UI CONF\n";
print "\n";

exit(0);


1;


sub strip_num{
        my ($str) = @_;
        $str =~ s/\d//g;
        return $str;
};



# To make 'sed' command human-readable
# my_sed( target_text, new_text, filename);
#   --->
#        sed --in-place 's/ <target_text> / <new_text> /' <filename>
sub my_sed{

        my ($from, $to, $file) = @_;
                        
        $from =~ s/([\'\"\/])/\\$1/g;
        $to =~ s/([\'\"\/])/\\$1/g;

        my $cmd = "sed --in-place 's/" . $from . "/" . $to . "/' " . $file;

        system("$cmd");
                        
        return 0;
};

1;





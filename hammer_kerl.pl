#!/usr/bin/perl
#
# Copyright (c) 2024 Jesse Gumm
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

use File::Copy;

print "Hammer Kerl\n";

our $HAMMER_KERL_STRING = "#_ADDED_BY_HAMMER_KERL_";
our $default_config_file = "~/.hammer_kerl_version";

my $executable = $0;
my $args = join(' ', @ARGV);

my $full_command = "$executable $args";

# Run the 'kerl list installations' command and capture the output
my $command = "kerl list installations";
open(my $cmd_output, "-|", $command) or die "Failed to execute command: $!";

# Iterate over each line of the output

my @versions;
my @paths;

my $exec_after = in_list($executable, ("erl", "escript"));

while (my $line = <$cmd_output>) {
    chomp $line;  # Remove trailing newline character

    # Use a regular expression to capture the version and the path
    if ($line =~ /^(\S+)\s+(\/\S+)$/) {
        my $version = $1;
        my $path = $2;
		push(@versions, $version);
		push(@paths, $path);

        #print "Version: $version, Path: $path\n";
    }
}
close($cmd_output);

my $orig_vsn = "";

if (-e $default_config_file) {
	open(my $orig_fh, '<', $default_config_file);
	local $/;
	$orig_vsn = <$orig_fh>;
	chomp($orig_vsn);
}

my $num = -1;
my $run_vsn = "";
my $run_path = "";

my $orig_index = &index_of($orig_vsn, @versions);
if($orig_index == -1) {
	# no previous version

	print "These are the current installed versions...\n";
	for(my $i=0; $i<=$#versions; $i++) {
		my $ii = $i+1;
		print "$ii: $versions[$i]\n";
	}
	my $vsn_max = $#versions+1;
	$num = &get_until_valid_range("Activate which version? [1-$vsn_max]", 1, $vsn_max);
	$num--;
	$run_vsn = $versions[$num];
	$run_path = $paths[$num];

	my $act_cmd = ". $run_path/activate";
	&write_file($default_config_file, $run_vsn);
	&add_or_instruct($act_cmd);	
}else{
	
	$run_vsn = $versions[$num];
	$run_path = $paths[$num];

	my $act_cmd = ". $run_path/activate";
	&add_or_instruct($act_cmd);	

	#print "Activating $run_vsn...\n";
	#system(". $run_path/activate");
	#system($full_command) if($exec_after);
}

sub add_or_instruct {
	my ($act_cmd) = @_;
	if(&get_until_valid_default_lower("y", "Auto-add to shell startup?", ("y", "n")) eq "y") {
		&add_to_rc($act_cmd);
	}else{
		print "To Activate, run the following line:\n\n   $act_cmd\n\n";
	}
}

sub add_to_rc {
	my ($cmd) = @_;
	my $shells = "(b)ash, (z)sh, (t)sch, (f)ish, (k)sh, (c)sh";
	my @shellopts = ("b", "z", "t", "f", "k", "c");
	my @configs = ("/.bashrc","/.zshrc", "/.tcshrc", "/.config/fish/config.fish", "/.kshrc", "/.cshrc");
	my $chosen = &get_until_valid_default_lower("b", "Which shell configuration to add the auto-activate script?\n$shells", @shellopts);
	my $index = &index_of($chosen, @shellopts);
	my $config_path = $ENV{'HOME'}.$configs[$index];
	my $newline = "$cmd $HAMMER_KERL_STRING\n";
	&backup_rc($config_path);
	&replace_previous_config($config_path, $newline) or &append_config($config_path, $newline);
	print "Success!\n\nNext Step: Either launch a new shell, or run the following line in this shell:\n\n  $cmd\n\n";
}

sub append_config {
	my ($config_path, $newline) = @_;
	print "Attempting to add Hammer Kerl line to shell config.\n";
	open(my $fh, ">>", $config_path) or die("unable to open $config_path");
	print $fh "\n\n$newline";
	close $fh;
}

sub backup_rc {
	my ($file) = @_;
	my $old = "$file.old";
	print "Backing up $file to $old\n";
	copy($file, $old);
}	

sub replace_previous_config {
	my ($file, $newline) = @_;
	print "Attempting to update $file\n";
	my $cfg = "";
	my $open_failed = 0;
	my $replaced = 0;
	open($fh, "<", $file) or $open_failed=1;
	if(!$open_failed) {
		while(my $line = <$fh>) {
			if($line eq $newline) {
				$replaced = 1;
				print "No changes needed for this line: $newline\n";
				$cfg .= $newline;
			}elsif($line =~ /$HAMMER_KERL_STRING/) {
				if($replaced) {
					print "* Removing extraneous Hammer Kerl Line: $line";
				}else{
					$cfg .= $newline;
					$replaced = 1;
					print "* Replacing Line: $line* New Line: $newline\n";
				}
			}else{
				$cfg .= $line;
			}
		}
	}
	if($open_failed) {
		print "No $file found.\n";
	}elsif(!$replaced) {
		print "No Hammer Kerl line found to replace.\n";
	}else{
		open($fh, ">", $file) or die("Unable to write new $file to disk");
		print $fh $cfg;
		print "File Updated: $file\n";
	}
	return $replaced;
}
			
		
sub write_file {
	my ($file, $data) = @_;
	open(my $fh, '>', $file);
	print $fh $data;
	close($fh);
}

sub index_of {
	my ($needle, @haystack) = @_;
	for (my $i=0; $i<=$#haystack; $i++) { 
		return $i if $needle eq $haystack[$i];
	}
	return -1;
}

sub get_until_valid {
    my ($prompt, @list) = @_;
    my $val;
	my $options = join("/", @list);
    do {
        print "$prompt ($options): ";
        $val = <STDIN>;
        chomp($val);
    } while(not(in_list($val,@list)));
    return $val;
}

sub get_until_valid_default {
	my ($default, $prompt, @list) = @_;
	my $val;
	my $options = join("/", @list);
	do {
		print "$prompt ($options) [Default: $default]: ";
		$val = <STDIN>;
		chomp($val);
	} while(($val ne "") and not(in_list($val, @list)));
}

sub get_until_valid_default_lower {
	my ($default, $prompt, @list) = @_;
	my $val;
	my $options = join("/", @list);
	$options = lc($options);
	do {
		print "$prompt ($options) [Default: $default]: ";
		$val = <STDIN>;
		chomp($val);
	}while(($val ne "") and not(in_list_lc($val, @list)));

	return lc($val eq "" ? $default : $val);
}


sub in_list {
    my ($val, @list) = @_;
    for (@list) {
        return 1 if($val eq $_);
    }
    return 0;
}

sub in_list_lc {
	my ($val, @list) = @_;
	$val = lc($val);
	for(@list) {
		return 1 if($val eq lc($_));
	}
	return 0;
}


sub get_until_valid_range {
    my ($prompt, $min, $max) = @_;
    my $val;
    do {
        print "$prompt: ";
        $val = <STDIN>;
        chomp($val);
    }until($val eq "f" or $val eq "q" or (&is_integer($val) and $val>=$min and $val<=$max));
    return $val;
}

sub is_integer {
    my ($val) = @_;
    return (!ref($val) and $val == int($val)); ## tests whether is numerically equal to itself.
}



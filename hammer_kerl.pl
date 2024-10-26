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

our $VERSION = "0.2.0 (beta)";
print "🔨💪 Hammer Kerl 🔨💪 $VERSION\n";

our $HAMMER_KERL_STRING = "#_ADDED_BY_HAMMER_KERL_";
our $executable = $0;
our $args = join(' ', @ARGV);
our $full_command = "$executable $args";
our $is_erl_exec = in_list($executable, ("erl", "escript", "erlc"));

&main();

sub main {
	&check_kerl();
	&core();
}

## TODO: Update this to ask if we want to auto-install Kerl
## TODO: Also ask if we want to build erlang, including installing dependencies
sub check_kerl {
	my $has_kerl = system("kerl version > /dev/null")==0;
	if(!$has_kerl) {
		print("Kerl is not installed. Please download and install Kerl: http://github.com/kerl/kerl");
		print("Then, build and install at least one version of Erlang with Kerl");
		die("Kerl not installed");
	}
	#my $install_kerl = $get_until_valid_lower("Kerl is not installed. Would you like Kerl Hammer to download and install it?", ("y","n"));
}

sub get_installed_list {
	my $command = "kerl list installations";
	open(my $cmd_output, "-|", $command) or die "Failed to execute command: $!";

	my @erlangs;

	while (my $line = <$cmd_output>) {
		chomp $line;  # Remove trailing newline character

		# Use a regular expression to capture the version and the path
		if ($line =~ /^(\S+)\s+(\/\S+)$/) {
			my $version = $1;
			my $path = $2;
			my %erlang = (version => $version, path => $path);
			push(@erlangs, \%erlang);

			#print "Version: $version, Path: $path\n";
		}
	}
	close($cmd_output);
	return @erlangs;
}

sub is_installed {
	my($search_vsn) = @_;
	my @erlangs = &get_installed_list();
	for(my $i=0;$i<=$#erlangs;$i++) {
		if($erlangs[$i]->{version} eq $search_vsn) {
			return 1;
		}
	}
	return 0;
}

sub get_build_list {
	my $command = "kerl list builds";
	open(my $cmd_output, "-|", $command) or die "Failed to execute command: $!";

	my @erlangs;

	while (my $line = <$cmd_output>) {
		chomp $line;  # Remove trailing newline character
		
		# Use a regular expression to capture the version and the path
		if ($line =~ /^(\S+),(\S+)$/) {
			my $version = $1; ## This is actually the "named" version
			push(@erlangs, $version);
		}
	}
	close($cmd_output);
	return @erlangs;
}

sub is_built {
	my($search_vsn) = @_;
	my @builds = &get_build_list();
	for my $build (@builds) {
		if($build eq $search_vsn) {
			return 1;
		}
	}
	return 0;
}

sub get_installable_list {
	my ($all) = @_;
	my $suffix = $all ? "all" : "";
	my $command = "kerl list releases $suffix";
	`kerl update releases`;
	open(my $cmd_output, "-|", $command) or die "Failed to execute command: $!";

	my @releases;

	while (my $line = <$cmd_output>) {
		chomp $line;  # Remove trailing newline character

		# Use a regular expression to capture the version and the path
		if ($line =~ /^(\S+)(?:\s(\*))?$/) {
			my $version = $1;
			my $note = ($2 ? "currently supported by the Erlang Team" : "");
			my %release = (version => $version, note => $note);
			push(@releases, \%release);
		}
	}
	close($cmd_output);
	return @releases;
}

sub print_versions {
	my ($show_index, @erlangs) = @_;

	for(my $i=0; $i<=$#erlangs; $i++) {
		my $displaynum = $i+1;
		my ($vsn, $note);
		if(ref($erlangs[$i]) eq "HASH") {
			$vsn = $erlangs[$i]->{version};
			$note = $erlangs[$i]->{note};
		}else{
			$vsn = $erlangs[$i];
		}
		print("$displaynum: ") if($show_index);
		print "$vsn";
		print " ($note)" if($note);
		print "\n";
	}
	return @erlangs;
}

sub get_and_print_versions {
	my ($show_index) = @_;
	my @erlangs = &get_installed_list();
	&print_versions($show_index, @erlangs);
}

sub show_activate {
	print "\n\nVersions available to activate:\n";
	my @erlangs = &get_and_print_versions(1);
	my $vsn_max = $#erlangs+1;

	$num = &get_until_valid_range("Activate which version? [1-$vsn_max]", 1, $vsn_max);
	$num--;
	## $run_vsn = $erlangs[$num]->{version};
	$run_path = $erlangs[$num]->{path};

	my $act_cmd = ". $run_path/activate";
	&add_or_instruct($act_cmd);	
}

sub show_install {
	my ($all) = @_;
	my $prefix = $all ? "ALL " : "";
	print "\n\n${prefix}Versions available to install:\n";
	my @releases = &get_installable_list($all);
	my %more;
		
	if($all) {
		%more = (version => "Only Show Most Recent Versions");
	}else{
		%more = (version => "Show All Available Versions");
	}
	push(@releases, \%more);

	&print_versions(1, @releases);
	my $max = $#releases+1;

	my $action = &get_until_valid_range("Which Version to install? [1-$max]", 1, $max);


	if($action==$max) {
		## The last item ("show all or show most recent") was selected
		return &show_install(!$all);
	}

	$action--;
	
	my $install_vsn = $releases[$action]->{version};

	my $install_path = "$ENV{HOME}/kerl/$install_vsn";

	my $prompt = "Downloading, Building, and Installing Erlang Version $install_vsn into ~/kerl/$install_vsn. Proceed?";

	my $proceed = &get_until_valid_lower($prompt, ("y", "n"));
	if($proceed eq "n") {
		print "Aborting Installation.\n";
		return &show_install(0);
	}

	
	my $is_installed = &is_installed($install_vsn);
	if($is_installed) {
		print "Version $install_vsn already installed. Skipping completely.\n";
		return &show_install(0)
	}	


	my $is_built = &is_built($install_vsn);

	if($is_built) {
		print "Version $install_vsn already built. Jumping to Installation instead.\n";
	}else{
		print("Downloading and building $install_vsn");
		if(system("kerl build $install_vsn")!=0) {
			return;
		}
	}


	if(system("kerl install $install_vsn $install_path")==0) {
		my $actprompt = "Version $install_vsn installed.  Do you want to activate this newly installed version right away?";
		my $act = &get_until_valid_lower($actprompt, ("y", "n"));
		if($act eq "y") {
			my $act_cmd = ". $install_path/activate";
			&add_or_instruct($act_cmd);	
		}
	}
}


sub show_delete {
	my @installs = &get_installed_list();
	my @builds = &get_build_list();

	my @combined = @builds;
	for (my $i=0; $i<=$#installs; $i++) {
		## Get the version from the $installs hash reference
		my $vsn = $installs[$i]->{version};

		## Convert it to a basic string
		$installs[$i] = $vsn;

		## If the version has not already been built, then push it onto the list
		if(not(in_list($vsn, @builds))) {
			push(@combined, $vsn);
		}
	}

	@combined = &sort_semver(@combined);

	print "Available versions to delete:\n";
	&print_versions(1, @combined);
	my $max = $#combined+1;
	my $prompt = "Which version would you like to delete? (this will delete both builds and installations) [1-$max]: ";
	my $delnum = &get_until_valid_range($prompt, 1, $max);
	$delnum--;
	
	my $delvsn = $combined[$delnum];

	my $is_built = in_list($delvsn, @builds);

	my $is_installed = in_list($delvsn, @installs);

	$prompt = "Are you sure you want to delete Erlang $delvsn? If so, type '$delvsn' exactly (or type 'c' to cancel): ";

	if(&get_until_valid_lower($prompt, ($delvsn, "c")) eq "c") {
		print "Aborting Deletion\n";
		return &core();
	}

	if($is_installed) {
		if(system("kerl delete installation $delvsn")) {
			print "\nHammer Kerl encounted and error attempting to delete an installation.\nTry running this command to deactivate it, then re-run hammer_kerl:\n\n";
			print "    kerl_deactivate\n\n";

			return;
		}
	}

	if($is_built) {
		if(system("kerl delete build $delvsn")) {
			print "Hammer Kerl Crashed Deleting Build $delvsn\n";
			return;
		}
	}

	return &core();
}

sub core {
	my $orig_vsn = "";

	my $num = -1;
	my $run_vsn = "";
	my $run_path = "";

	print "Erlang versions installed:\n";
	my @erlangs = &get_and_print_versions(0);

	my $prompt = "\nAvailable actions:\nA: Activate a version of Erlang\nI: Install a new version of Erlang.\nD: Delete a build or installation.\nQ: Quit\nWhat would you like to do?";
	my $action = &get_until_valid_lower($prompt, ("A","I","D","Q"));

	if($action eq "a") {
		&show_activate();
	}elsif($action eq "i") {
		&show_install(0);
	}elsif($action eq "d") {
		&show_delete();
	}elsif($action eq "p") {
		&show_dependencies();
	}elsif($action eq "q") {
		return;
	}
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
	my $also_reset_vars = &get_until_valid_default_lower("n", "\nBy default, Kerl, overrides the REBAR_CACHE_DIR and REBAR_PLT_DIR variables.\nThis can sometimes lead to issues with some rebar3 projects. For reference, see\nthis Github issue: https://github.com/erlang/rebar3/issues/2762\n\nDo you want kerl_hammer to unset these variables in your shell config?", ("y","n"));
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

sub get_until_valid_lower {
	my ($prompt, @list) = @_;
	my $val;
	my $options = join("/", @list);
	$options = lc($options);
	do {
		print "$prompt ($options): ";
		$val = <STDIN>;
		chomp($val);
	}while(not(in_list_lc($val, @list)));
	return lc($val);
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

sub sort_semver {
	my @versions = @_;

	return sort {
		my ($a_major, $a_minor, $a_patch) = split(/\./, $a);
		my ($b_major, $b_minor, $b_patch) = split(/\./, $b);

		# Sort by major, then minor, then patch
		$a_major <=> $b_major ||
		$a_minor <=> $b_minor ||
		$a_patch <=> $b_patch;
	} @versions;
}

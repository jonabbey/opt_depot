
#
# Program to allow the installation and configuration of the
# opt_depot perl suite
#
#############################################################################

$version = "2.02";
$config = "opt.config"; # name of configuration file that will be produced

#########################################################################
#
#                                                              create_dir
# input: a pathname
#
# output: makes sure the specified directory exists. If it doesn't
#         then check_dirs makes it (along with any super-directories)
#
#
#########################################################################
sub create_dir{
  my ($file) = @_;
  my ($temp, @components);
  @components = split(/\//, $file);

  foreach $comp (@components) {
    $temp .= "$comp";

    if (! -d $temp && ($temp ne "")) {
      mkdir($temp, 0777) || print "Could not make dir $temp\n";
    }

    $temp .= "/";  # add trailing /
  }
}

#########################################################################
#
#                                                          check_response
#
# input: none
#
# this procedure prompts the user for whtether the responses entered were
# in fact correct
#
#########################################################################

sub check_response {
  print"\nYou have entered the following information\n";
  print"------------------------------------------\n";
  print"Primary directory: $dest\n";
  print"Depot directory: $depot\n";
  print"Log directory: $logdir\n\n";
  print"\nIs this information correct?(y/n)";
  $ans = <STDIN>;
  unless ($ans =~ /^y/i) {
    die "Installation process aborted\n";
  }
} # check_response

#########################################################################
#
#                                                         removelastslash
#
# input: a pathname to test
#
# this function will remove a trailing slash from the directory name
# input
#
#########################################################################
sub removelastslash {
  ($dir) = @_;

  if ($dir =~ /\/$/) {
    chop $dir;
  }
} # removelastslash

#########################################################################
#
#                                                           make_absolute
#
# input: a pathname
#
# output: if the pathname does not begin with a leading slash, then
#         the current working directory is pre-pended to the input dir
#
########################################################################
sub make_absolute {
  local($dir) = @_;
  my ($cwd);

  if ($dir !~ /^\s*\//) {
    $cwd = `pwd`;
    chop($cwd);
    $dir = "$cwd/$dir";
  }

  return $dir;
}

#########################################################################
#
#                                                                dircheck
#
# input: a pathname to test
#
# this function will trigger an exit if the parameter is not
# a directory.
#
#########################################################################
sub dircheck {
  local($dir)= @_;
  local($ans);

  if (!(-d $dir)) {
    print "$dir does not exist. Do you wish to create it? (y/n) ";
    $ans = <STDIN>;
    unless ($ans =~ /^y/i) {
      die "Installation process aborted\n";
    }
    &create_dir($dir);
  }
} # dircheck

#############################################################################
#
#
#                                   Main
#
#
#############################################################################

$where_perl_is = @ARGV[0];
print"\n## opt_install version: $version ##\n\n";

print"** Be sure to include all the necessary path information when choosing\n";
print"** the opt_depot program directories (leading slashes, relative paths, etc)\n\n";

#################### find dest ##################

print"Enter the Primary Directory [Default is: /opt ]\n";
print"** This is where the /bin/include/man/info/lib directories will reside\n";
print"---->  ";
$dest = <STDIN>;
chop $dest;

if ($dest eq "") {
  print"Default directory selected\n";
  $dest = "/opt";
}

&removelastslash($dest);
$dest = &make_absolute($dest);
&dircheck($dest);

################### find depot ##################

print"\nEnter the Depot directory [Default is $dest/depot ]\n";
print"---->  ";
$depot = <STDIN>;
chop $depot;

if ($depot eq "") {
  print"Default directory selected\n";
  $depot = "$dest/depot";
}

&removelastslash("$depot");
$depot = &make_absolute($depot);
&dircheck("$depot");

################# find logdir ##################

print"\nEnter the name of the log directory [Default is /logs/opt_depot ]\n";
print"---->  ";
$logdir = <STDIN>;
chop($logdir);

if ($logdir eq "") {
  print"Default log directory selected\n";
  $logdir = "/logs/opt_depot";
}

&dircheck($logdir);
&removelastslash($logdir);
$logdir = &make_absolute($logdir);

################## check response #################

&check_response;

################## create opt-config #########

open(OUT,">$config") || die "Could not create $config\n";
print"\n** Writing information to $config\n";

$SIG{'INT'} = 'IGNORE';  # Disables any signals which may result in
$SIG{'TERM'} = 'IGNORE'; # the early termination of printing to the
$SIG{'HUP'} = 'IGNORE';  # configuration file
print OUT "Base:$dest\n";
print OUT "Depot:$depot\n";
print OUT "Log:$logdir\n";
print OUT "Subdirs: bin,include,info,man,lib\n";
print OUT "Recurse: include/\n";

print"\nThe following subdirectories will be linked under $dest:\n";
print"\/bin /lib /include /man /info\n";
print"If you wish to add to this list,  please append the entry in the\n";
print"opt.config file located under the /etc directory of the opt_depot package\n\n";

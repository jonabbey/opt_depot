#
# Program to allow the installation and configuration of the
# opt_depot perl suite
#
#############################################################################

use FindBin qw($RealBin);

use lib "$RealBin/../modules";
use Opt_depot::Common;

$version = "3.0";
$config = "opt.config"; # name of configuration file that will be produced

#############################################################################
#
#
#                                   Main
#
#
#############################################################################

$where_perl_is = @ARGV[0];

print"\n## opt_install version: $version ##\n\n";

#################### find dest ##################

$dest = askstring("What directory is to contain the link target directories (bin, include, etc.)?",
		  "/opt");

removelastslash($dest);
$dest = make_absolute($dest);
testmakedir($dest);

################### find depot ##################

$depot = askstring("Where do you want the depot directory?",
		   "$dest/depot");

removelastslash($depot);
$depot = make_absolute($depot);
testmakedir($depot);

################# find logdir ##################

if (askyn("Do you want the opt_depot scripts to keep an activity log?")) {

  # use our old log file calculation algorithm, and let's see whether
  # there's an existing log file named according to our old standard

  if (-d "/logs") {
    $defaultlogdir = "/logs";	# an ARL thing
  } elsif (-d "/var/log") {
    $defaultlogdir = "/var/log";
  }

  @desttemp= split (/\//, $dest); # naming log file
  shift(@desttemp);		  # strip the leading /

  $defaultlog = "$defaultlogdir/opt_depot/" . join(':', @desttemp);

  if (!-e "$defaultlog") {
    $defaultlog = "$defaultlogdir/opt_depot.log";
  }

  $log = askstring("Where do you want the log file?", $defaultlog);

  removelastslash($log);
  $log = make_absolute($log);
} else {
  $log = undef;
}

################## final checkout #################

print"\nYou have entered the following information\n";
print"------------------------------------------\n";
print"Primary directory: $dest\n";
print"Depot directory: $depot\n";

if (defined $log) {
  if (-d $log) {
    print "Log directory: $log\n\n";
  } elsif (-e $log) {
    print "Log file: $log\n\n";
  }
} else {
  print "Logging: No logging\n\n";
}

unless (askyn("\nIs this information correct?(y/n)")) {
  die "Installation process aborted\n";
}

################## create opt-config #########

open(OUT,">$config") || die "Could not create $config\n";
print"\n** Writing information to $config\n";

$SIG{'INT'} = 'IGNORE';  # Disables any signals which may result in
$SIG{'TERM'} = 'IGNORE'; # the early termination of printing to the
$SIG{'HUP'} = 'IGNORE';  # configuration file
print OUT "Base:$dest\n";
print OUT "Depot:$depot\n";

if (defined $log) {
  print OUT "Log:$log\n";
} else {
  print OUT "Log:       # no logging\n";
}

print OUT "Subdirs: bin,include,info,man,lib\n";
print OUT "Recurse: include/\n";

close(OUT);

print "\n";

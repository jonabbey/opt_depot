#
# Opt_depot::Common.pm
#
# Perl module to provide common functionality used by the various
# opt_depot scripts, including link handling logic, directory filename
# operations, and configuration file parsing.
#
#************************************************************************
#
# Copyright (C) 2003  The University of Texas at Austin.
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation; either version 2 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program; if not, write to the Free Software
#    Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA
#    02111-1307, USA
#
#    Written by: Computer Science Division, Applied Research Laboratories,
#    University of Texas at Austin  opt-depot@arlut.utexas.edu
#
#***********************************************************************
# Written by Jonathan Abbey
# 23 July 2003
#
# Release: $Name:  $
# Version: $Revision: 1.2 $
# Last Mod Date: $Date: 2003/08/02 03:30:52 $
#
#####################################################################

package Opt_depot::Common;

use Text::ParseWords qw(quotewords);

use vars qw($VERSION @ISA @EXPORT $PERL_SINGLE_QUOTE);
$VERSION="3.0";

require 5.000;

use Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($dest $depot $logdir %switches @subdirs @unify_list
	     *LOG
	     parsequoted
	     init_log close_log logprint
	     check_lock clear_lock
	     dircheck extractdir killdir removelastslash resolve pathcheck
	     read_prefs
	    );
@EXPORT_OK = qw();

# declare our package globals that we're not exporting

our $usage_string;
#our CONFIG;
our $log_init;
#our LOG;
our $lockset = 0;


##########################################################################
#
#                                                              parsequoted
#
# input: $str, $remove_escapes
#
# This subroutine is designed to process a string that is surrounded by
# quotation marks, with proper escape handling.
#
# output: the quoted string, minus the surrounding quotes.  Any
# backslash (\) escapes are preserved in the returned string, for later
# processing.
#
##########################################################################
sub parsequoted {
  my ($str, $remove_escapes) = @_;

  my $quoted = "";
  my $strcopy = $str;

  $strcopy =~ s/^\s+//;		# trim leading whitespace

  if ($strcopy =~ m/^(["'])((?:\\.|(?!\1)[^\\])*)\1/) {
    $quoted = $2;

    if ($remove_escapes) {
      $quoted =~ s/\\(.)/$1/g;
    }
  }

  return $quoted;
}

#########################################################################
#
#                                                                init_log
#
# input: $appname
#
# uses: $logdir $dest %switches package globals
#
# This function handles initialization of the log file if the %switches
# hash doesn't contain q.
#
# Note that because this function depends on a bunch of package globals,
# it needs to be called after read_prefs().
#
#########################################################################
sub init_log {
  my ($appname) = @_;

  my ($buf, @dest, $log, $temphandle);

  # name log file, with colons separating the path of the log target

  @dest= split (/\//, $dest);
  shift(@dest);
  $log = "$logdir/" . join(':',@dest);

  # open log file and time stamp entry

  if (!$switches{'q'}) {
    open (LOG, ">> $log") || die "Could not open $log";

    # don't do command buffering on LOG

    $temphandle = select(LOG);
    $| = 1;
    select($temphandle);

    print (LOG "\n\n**$appname**  ");
    ($sec, $min, $hour, $mday, $mon, $year)= localtime(time);
    $mon=$mon + 1;
    print (LOG "$hour:$min:$sec  $mon\/$mday\/$year\n");
  }
}

#########################################################################
#
#                                                               close_log
#
#
# This function closes the log file if the %switches hash doesn't
# contain q.
#
#########################################################################
sub close_log {
  close (LOG) if (!($switches{'q'}));
}

##########################################################################
#
#                                                                 logprint
#
# input: $str - A string to print and/or log
#        $level - A numeric value.. if 0, print to stdout only on
#                 -v being set.  If not 0, print regardless of
#                 the presence or absence of -v
#
##########################################################################
sub logprint {
  my ($str,$level) = @_;

  if ($level || $switches{'v'}) {
    print $str;
  }

  if (!($switches{'q'})) {
    print LOG $str;
  }
}

#########################################################################
#
#                                                              check_lock
#
# input: $application, the name of the program being locked
#
# check_lock is a test-and-set routine for checking whether a lock can
# be established.  If a lock already exists and the user declines to
# break the lock, or if the user doesn't have permission to create a new
# lock file, check_lock will return 0.
#
# If the lock file can be created under $dest, check_lock returns 1.
#
# NOTE: check_lock consults the package global %switches hash to see
# if -s was specified on the command line.  If so, the lock will not be
# created or checked.  This is to allow opt_setup to set up an umbrella
# lock when running the other opt_depot scripts.
#
#########################################################################
sub check_lock {
  my ($application) = @_;

  my ($user, $software, $lock, $mins_ago, $cont);
  local *LOCK;

  if (exists $switches{'s'}) {
    return 1;
  }

  $lock = "$dest/lock.optdepot";

  # read lock and die if found

  if (open (LOCK, "<$lock")) {
    $user = <LOCK>;
    $software = <LOCK>;
    close(LOCK);

    chomp $user;
    chomp $software;

    print "\"$user\" may still be using $software.\n";
    $mins_ago= (-M $lock) * 24 * 60;
    printf ("The lock was created %3.1f minutes ago.\n", $mins_ago);
    print "Would you like to override?";
    $cont=getc;
    if (($cont ne "Y") && ($cont ne "y")) {
      $lockset = 0;
      return 0;
    } else {
      unlink($lock);
    }
  }

  # create a lock

  if (!open LOCK, ">$lock") {
    logprint("Could not create lockfile ($lock)", 1);
    $lockset = 0;
    return 0;
  } else {
    print LOCK "$ENV{'USER'}\n";
    print LOCK "$application\n";
    close (LOCK);
    $lockset = 1;
  }

  return 1;
}

#########################################################################
#
#                                                              clear_lock
#
# input: none
#
# uses: $log LOCK $dest %switches
#
# output: clears the lock file established by check_lock()
#
#########################################################################
sub clear_lock {
  if ($lockset) {
    unlink("$dest/lock.optdepot") || logprint("Could not remove lock!", 1);
  }
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
  my($dir) = @_;

  if (!(-d $dir)){		
    logprint("$dir is not a directory", 1);
    clear_lock();
    exit(0);
  }
}

#########################################################################
#
#                                                              extractdir
#
# input: $filepath, a string containing a fully qualified path, terminating
#        in a filename
#
# output: a string containing just the directory from $filepath
#
#########################################################################
sub extractdir {
  my ($filepath) = @_;

  my (@comps);

  @comps =split(/\//, $filepath);
  pop @comps;

  return join('/', @comps);
}

#########################################################################
#
#                                                                 killdir
#
# input: $filepath, a string containing a directory to be deleted
#
# returns 0 on failure, or a positive value on success
#
#########################################################################
sub killdir {
  my ($filepath) = @_;

  my $errcount = 0;

  local $SIG{__WARN__} = sub {$errcount++};	# have to use local for dynamic scope

  rmtree($filepath, 0, 0);

  if ($errcount > 0) {
    return 0;
  }

  return 1;
}

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
  if ($_[0] =~ /\/$/) {
    chop $_[0];
  }
}


#########################################################################
#
#                                                               pathcheck
#
# This function is used to determine if $file is contained under any
# directory listed in the keys of %assoc.  The keys of %assoc should
# map to integer values, in which the lowest positive number is taken
# to be the best priority, if we're dealing with a priority hash.  If
# we're dealing with an exclusion hash, then all values in the exclusion
# hash will be positive numbers, so if we find any of them we'll wind
# up returning a positive (true) integer value.
#
# In other words, when used on the global %priority hash, we'll return an
# integer that can be compared to determine relative priority.  When
# used on the global %exclude hash, we'll effectively return a boolean
# value.
#
# input: $file - a fully qualified filepath
#        *assoc - a name for an associative array (exclude or priority)
#
# output: as above.
#
#########################################################################
sub pathcheck {
  local ($file, *assoc) = @_;

  @components = split(/\//, $file);

  my ($t_pri, $temp, $low_pri);

  # we want to find the best (lowest numerical value) priority
  # that pertains to $file

  $low_pri = 9999;
  $temp = "";

  # now loop over the path, from top down.  Since we're splitting on
  # /, if $file began with a slash, our first component will be the
  # empty string, and we'll start adding non-empty strings after we've
  # appended the first slash in the second clause of the loop

  foreach $comp (@components) {
    $temp .= "$comp";

    if (exists $assoc{$temp}) {
      $t_pri = $assoc{$temp};

      if ($t_pri && $t_pri < $low_pri) {
	$low_pri = $t_pri;
      }
    }

    # add a trailing /, in case the trailing slash was present in the
    # hash, and check again.  Adding the trailing slash here will
    # also prep us to add the next component.

    $temp .= "/";

    if (exists $assoc{$temp}) {
      $t_pri = $assoc{$temp};

      if ($t_pri && $t_pri < $low_pri) {
	$low_pri = $t_pri;
      }
    }
  }

  if ($low_pri != 9999) {
    return $low_pri;
  }

  return 0;
}

#########################################################################
#
#                                                                 resolve
#
# input: $dir - absolute pathname of current directory
#        $link - string containing the readlink() results for a
#                symbolic link in $dir to be processed
#
# This function takes the current directory and the string
# obtained from a readlink() call and calculates and returns the
# absolute path to the target of the readlink, resolving any relative
# path elements along the way.
#
#########################################################################
sub resolve {
  my($dir, $link) = @_;

  my(@alinkp, $d, $alinkp);

  # make array representations of
  # the current directory and symbolic link

  # if we have a leading / in our $dir or $link,
  # we'll need to shift to get rid of the leading
  # empty array element

  @dirp=split(/\//, $dir);
  shift(@dirp) if (!($dirp[0]));

  @linkp=split(/\//, $link);
  shift(@linkp) if (!($linkp[0]));

  # @alinkp is an array that we will build to contain the absolute
  # link target pathname.  If the link does not begin with a /, it is
  # a relative link, and we need to place our current directory into
  # the @alinkp array.

  if ($link !~ /^\//) {
    @alinkp=@dirp;
  }

  # modify the @alinkp array according
  # to each path component of the @linkp array
  # (an array representation of the symbolic link
  # given to us), to arrive at the ultimate absolute
  # pathname of the symbolic link

  $d = shift(@linkp);

  while ($d) {
    if ($d eq "..") {
      pop(@alinkp);
    } elsif ($d ne ".") {
      push(@alinkp, $d);
    }

    $d=shift(@linkp);
  }

  $alinkp = "/".join('/',@alinkp);

  return $alinkp;
}

##########################################################################
#
#                                                               read_prefs
#
# The idea of read_prefs is to create a single function which can be called
# by the various opt scripts which would process command line arguments
# and the configure file.. ?
#
# input: $usage_str, $default_config_file, $switchlist, @ARGV
#
# $usage_str is a textual message describing the proper command line
# parameters we're expecting.  The $default_config_file should be the
# initial location to look in for the opt.config file.  The
# $switchlist string should be a concatenation of the permissible
# single-character command line flags.  %prefs should be a hash to
# load preference data into, and @ARGV should be the command line
# argument vector.
#
# output: the exported $dest, $depot, $logdir, %switches, @subdirs, and
# @unify_list variables are loaded from the given configuration file (or
# whatever configuration file is specified using the -f argument in @ARGV)
#
##########################################################################

sub read_prefs ($$$\@) {
  my ($usage_str, $default_config_file, $switchlist, $ARGV_ref) = @_;

  my ($cmd_config_file, $cmd_depot, $cmd_dest, $cmd_logdir);

  $usage_string = $usage_str;

  # first see if we have a config file override on the command line

  $cmd_config_file = find_arg('f', @$ARGV_ref);

  if ($cmd_config_file) {
    if (-r $cmd_config_file) {
      $config_file = $cmd_config_file;
    } else {
      die "Can't find/read $cmd_config_file";
    }
  } else {
    $config_file = $default_config_file;
  }

  # read the config file

  read_config($config_file);

  # if we didn't get an explicit -f config file specifier on the
  # command line, look to see if we have an auxiliary config file
  # located under $dest

  if (!$cmd_config_file && -e "$dest/opt.config") {
    read_config("$dest/opt.config");
  }

  # now for final after-the-fact command line overrides

  $cmd_depot = find_arg('d',@$ARGV_ref);

  if ($cmd_depot) {
    dircheck($cmd_depot);
    $depot = $cmd_depot;
  }

  $cmd_dest = find_arg('b', @$ARGV_ref);

  if ($cmd_dest) {
    dircheck($cmd_dest);
    $dest = $cmd_dest;
  }

  $cmd_logdir = find_arg('l', @$ARGV_ref);

  if ($cmd_logdir) {
    dircheck($cmd_logdir);
    $logdir = $cmd_logdir;
  }

  read_switches($switchlist, @$ARGV_ref);

  check_args($switchlist, @$ARGV_ref);

  removelastslash($depot);
  removelastslash($logdir);
  removelastslash($dest);
}

##########################################################################
#
#                                                              read_config
# input: $default_config_file, $switchlist
#
# output:
#
# This function reads the configuration file for the opt_depot scripts
# and sets global variables $dest, $depot, $logdir, @subdirs, @unify_list
# that are exported by this module.
#
##########################################################################
sub read_config {
  my ($file, $switchlist) = @_;

  open(CONFIG, "$config_file") || die "Could not open $config_file\n";

  while (<CONFIG>){
    if (/^Base:\s*(.*)/) {
      $dest = $1;

      if (($dest =~ /^\s*\"/) ||
	  ($dest =~ /^\s*\'/)) {
	$dest = parsequoted($dest, 1);
      }
    }

    if (/^Depot:\s*(.*)/) {
      $depot = $1;

      if (($depot =~ /^\s*\"/) ||
	  ($depot =~ /^\s*\'/)) {
	$depot = parsequoted($depot, 1);
      }
    }

    if (/^Log:\s*(.*)/) {
      $logdir = $1;

      if (($logdir =~ /^\s*\"/) ||
	  ($logdir =~ /^\s*\'/)) {
	$logdir = parsequoted($logdir, 1);
      }
    }

    if (/^Subdirs:\s*(.*)/) {
      $dirs = $1;
      $dirs =~ s/^\s+//;
      $dirs =~ s/\s+$//;
      @subdirs = quotewords('\s+|,',0,$dirs); # from Text::ParseWords
    }

    if (/^Recurse:\s*(.*)/) {
      $rdirs = $1;
      $rdirs =~ s/^\s+//;
      $rdirs =~ s/\s+$//;
      @unify_list = quotewords('\s+|,',0,$rdirs); # from Text::ParseWords
    }
  }

  close(CONFIG);
}

##########################################################################
#
#                                                                 find_arg
# input: $token, @args
#
# output: the string argument following the single character
# $token.. for instance, if $token is 'f', find_arg will return the
# string following -f in the @args list, if it can be found.
#
# if the token can't be found following a dash character, an empty string
# will be returned.
#
#
##########################################################################

sub find_arg {
  my ($token, @args) = @_;

  my ($i, $word, $localword);

  $i = 0;
  $localword = "";

  while ($args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i = $i + 1;

    if ($word =~ /^$token/) {
      # redefine config file location

      if (length($word)==1) {
	$localword = $args[$i];
      } else {
	$word =~ /^$token(.*)$/;
	$localword = $1;
      }

      last;
    }
  }

  return $localword;
}

##########################################################################
#
#                                                            read_switches
# input: $switchlist, @args
#
# The $switchlist string should be a concatenation of the
# permissible single-character command line flags.
#
# output: sets flags in the global %switches hash
#
##########################################################################

sub read_switches {
  my ($switchlist, @args) = @_;

  my ($i, $word, @switches);

  $i = 0;
  $localword = "";

  while ($args[$i] =~ /^-(.*)$/) {
    $word=$1;
    $i = $i + 1;

    if ($word =~ /(^[$switchlist]+)$/) {
      @switches= split (//, $1);
      for $switch (@switches) {
	$switches{$switch}="-$switch";
      }	
    } else {
      print "\"$word\" is an invalid command entry!\n\n";
      print $usage_string;
      exit 0;
    }
  }
}

##########################################################################
#
#                                                               check_args
# input: $switchlist, @args
#
# check_args runs through the argument array and makes sure that no
# parameters were given which shouldn't be there
#
##########################################################################

sub check_args {
  my ($switchlist, @args) = @_;

  my ($i, $word);

  $i = 0;

  while ($i <= $#args) {
    if ($args[$i] =~ /^-(.*)$/) {
      $word=$1;
      $i++;

      if ($word =~ /^[fdbl]/) {
	# we've got one of the standard tokens which may permissibly
	# be followed by an argument string
	
	if (length($word)==1) {
	  # single char flag.. skip the next param, which is the
	  # argument for the flag
	  $i++;
	}
      } elsif ($word =~ /^[$switchlist]+$/) {
	# just a set of switch flags, no big deal either
      } else {
	print "\"$word\" is an unrecognized command line flag!\n\n";
	print $usage_string;
	exit 0;
      }
    } else {
      print "\"$word\" is an unrecognized command line flag!\n\n";
      print $usage_string;
      exit 0;
    }
  }
}

1;

#!/bin/sh
#
# This is the bootstrapping configuration script for opt_depot. The
# only thing we count on to run this script is that /bin/sh works.
#
# Get enough information from the user to be able to find Perl 5
#
# Release: $Name:  $
# Version: $Revision: 1.7 $
# Last Mod Date: $Date: 2003/07/09 02:21:44 $
#
###############################################################################

depot_version="2.02"

# 
# Figure out how to do an echo without trailing newline
#

prompt ()
{
  if [ `echo "Z\c"` = "Z" ] > /dev/null 2>&1; then
    # System V style echo
    echo "$@\c"
  else
    # BSD style echo
    echo -e -n "$@"
  fi
}

verify_perl ()
{
  _perl_loc=$1

  $_perl_loc > /dev/null 2>&1 <<EOF
# this Perl script is used to validate that we have a new enough version of perl
die if $] < 5.000;
exit 0;
EOF

  if [ $? = 0 ]; then
    echo "Perl has been located as $_perl_loc"
    echo
    echo "###########################################################"
    $_perl_loc -v   # this call to perl prints out the version info needed
    echo "###########################################################"
    echo
    echo
    echo "Do you wish to use $_perl_loc? [Y/N]"
    prompt "----> "
    read _answer
    echo

    case $_answer in
      y|Y|yes|Yes) perlok="y"
        ;;
      *) perlok="n"
         perl_loc=""
        ;;
    esac
  else
    echo "$_perl_loc is too old, we require Perl 5.0"
    echo "or later for opt_depot"
    echo
    perlok="n"
    perl_loc=""
  fi

  return 0
}

#
# Let the games begin
#

echo
echo "## opt_depot setup version $depot_version ##"
echo
echo "Searching for 'perl'..."
echo

# Find perl (GPERL)

perl_loc=`which perl5 2> /dev/null`

if [ ! -r "$perl_loc" ]; then
  perl_loc=`which perl 2> /dev/null`
fi

if [ ! -r "$perl_loc" ]; then
  perl_loc=""
fi

perlok="n"

while [ "$perlok" = "n" ]; do
  if [ "$perl_loc" = "" ]; then
    echo "Please enter the name of the Perl 5 version you want to use"
    echo "and its location" 
    prompt "----> "
    read perl_loc
    echo

    if [ ! -r "$perl_loc" ]; then
      if [ "$perl_loc" != "" ]; then
        echo "Could not find $perl_loc"
	echo
      fi
      perl_loc=""
      continue
    fi
  fi

  verify_perl $perl_loc
done

echo
echo "The following line will be added to the opt_depot scripts:"
echo "#!$perl_loc"

$perl_loc scripts/install.pl  -IGetopt $perl_loc
if [ -f "opt.config" ]; then  
  $perl_loc scripts/modify_archives 
else
  exit
fi

echo " "
$perl_loc scripts/opt_copy $perl_loc

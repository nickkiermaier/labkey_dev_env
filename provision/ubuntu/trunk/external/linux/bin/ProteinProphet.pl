#!/usr/bin/perl
#############################################################################
# Program       : ProteinProphet.pl                                         #
# Author        : Andrew Keller <akeller@systemsbiology.org>                #
# Date          : 3.28.03                                                   #
#                                    xxx                                    #
# ProteinProphet                                                            #
#                                                                           #
# Program       : ProteinProphet T.M.                                       #   
# Author        : Andrew Keller <akeller@systemsbiology.org>                #
# Date          : 11.27.02                                                  #
#                                                                           #
#                                                                           #
# Copyright (C) 2003 Andrew Keller                                          #
#                                                                           #
# This library is free software; you can redistribute it and/or             #
# modify it under the terms of the GNU Lesser General Public                #
# License as published by the Free Software Foundation; either              #
# version 2.1 of the License, or (at your option) any later version.        #
#                                                                           #
# This library is distributed in the hope that it will be useful,           #
# but WITHOUT ANY WARRANTY; without even the implied warranty of            #
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU         #
# General Public License for more details.                                  #
#                                                                           #
# You should have received a copy of the GNU Lesser General Public          #
# License along with this library; if not, write to the Free Software       #
# Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA #
#                                                                           #
# Andrew Keller                                                             #
# Insitute for Systems Biology                                              #
# 1441 North 34th St.                                                       #
# Seattle, WA  98103  USA                                                   #
# akeller@systemsbiology.org                                                #
#                                                                           #
#############################################################################
use strict;
use File::Basename;
use Cwd;

use lib Cwd::abs_path(dirname($0));

use IO::Handle;
use POSIX;

use Time::Local;
use Time::localtime qw(localtime);
############################################################################
#     C  O  N  F  I  G  U  R  A  T  I  O  N     A  R  E  A
#
#
# ISB-CYGWIN Release
#   This is a kludge to hardcode isb-cygwin specific
#   defaults for the parameters in this section. 
#   In the future these options should be automatically
#   filled in by a true build system. See the code which 
#   immediately follows this section for the isb-cygwin defaults.
#
my $PROGRAM_VERSION = '4.0';

#
#  PRINT_HTML
#     Set to 1 if you don't have working web server or xsltproc
#     program (or equivalent).
#
my $PRINT_HTML = 0; 

########################################
# ALL NON-ISB USERS: SET THIS VALUE TO 0
my $ISB_VERSION = 0;
########################################

my $WINDOWS_CYGWIN = -f '/bin/cygpath';

# forward declarations (for scoping reasons they are declared here)
my $LD_LIBRARY_PATH;
my $DTD_FILE;
my $XSL_MAKER;
my $CGI_HOME;
my $TOP_PATH;
my $PROTXML_SCHEMA;
my $BINARY_DIRECTORY;
my $SCHEMA_DIRECTORY;
my $SERVER_ROOT;

$BINARY_DIRECTORY = dirname($0) . '/';
$TOP_PATH = $BINARY_DIRECTORY . '../';
$SCHEMA_DIRECTORY = $TOP_PATH . 'schema/';
#$DTD_FILE = $SCHEMA_DIRECTORY . 'ProteinProphet_v1.9.dtd';
$PROTXML_SCHEMA = $SCHEMA_DIRECTORY . 'protXML_v4.xsd';
$SERVER_ROOT = '';

if (-f $BINARY_DIRECTORY . 'protxml2html.pl')
{
    $XSL_MAKER = $BINARY_DIRECTORY . 'protxml2html.pl';
}

#
# Linux architecture installation
#
if ( $^O eq 'linux' ) {
    #
    # LD_LIBRARY_PATH - May only be required for XALAN
    #
    $LD_LIBRARY_PATH = '';
    $CGI_HOME = '/tpp/cgi-bin/';

#
# Cygwin Release
#
} elsif( $^O eq 'cygwin') {

    $CGI_HOME = '/tpp-bin/';
    if ($ENV{'WEBSERVER_ROOT'} ne "") {
	print "WEBSERVER_ROOT=" . $ENV{'WEBSERVER_ROOT'} . "\n";
        my ($serverRoot) = ($ENV{'WEBSERVER_ROOT'} =~ /(\S+)/);
        if ( $WINDOWS_CYGWIN && $serverRoot =~ /\:/ ) {
            $serverRoot = `cygpath '$serverRoot'`;
            ($serverRoot) = ($serverRoot =~ /(\S+)/);
        }
        # make sure ends with '/'
        $serverRoot .= '/' if($serverRoot !~ /\/$/);
        $SERVER_ROOT = $serverRoot;
        if ($SERVER_ROOT eq '') {
            die "cannot find WEBSERVER_ROOT environment variable\n";
        }
        $XSL_MAKER = $SERVER_ROOT . '../tpp-bin/'  . 'protxml2html.pl';
        #$DTD_FILE = $SERVER_ROOT . 'ProteinProphet_v1.9.dtd';
        $PROTXML_SCHEMA = $SERVER_ROOT . 'protXML_v4.xsd';
    }
}

###########################
# version                 #
###########################
require 'TPPVersionInfo.pl';  # declare $TPPVersionInfo
my $TPPVersionInfo = getTPPVersionInfo();
my $VERSION = 'ProteinProphet.pl v2.0 (' . $TPPVersionInfo . ') AKeller August 15, 2003'; 

if(@ARGV < 2) {
    print STDERR $VERSION . "\n\n";
    print STDERR "usage:\tProteinProphet.pl '<interact pep prob html file1><interact pep prob html file2>....' <outfile> (ICAT) (GLYC) (XPRESS) (ASAP_PROPHET) (ACCURACY) (ASAP) (REFRESH) (DELUDE) (NOOCCAM) (NOPLOT) \n";
    print STDERR "\t\tNOPLOT: do not generate plot png file\n";
    print STDERR "\t\tNOOCCAM: non-conservative maximum protein list\n";
    print STDERR "\t\tICAT: highlight peptide cysteines\n";
    print STDERR "\t\tGLYC: highlight peptide N-glycosylation motif\n";
    print STDERR "\t\tACCURACY: min pep prob 0\n";
    print STDERR "\t\tASAP: compute ASAP ratios for protein entries\n\t\t\t(ASAP must have been run previously on interact dataset)\n";
    print STDERR "\t\tREFRESH: import manual changes to ASAP ratios\n\t\t\t(after initially using ASAP option)\n";
    print STDERR "\t\tASAP_PROPHET: *New and Improved* compute ASAP ratios for protein entries\n\t\t\t(ASAP must have been run previously on all input interact datasets with mz/XML raw data format)\n";    
    print STDERR "\t\tDELUDE: do NOT use peptide degeneracy information when assessing proteins\n";
    print STDERR "\t\tHTML: write output to static html page (rather than dynamic shtml)\n";
    print STDERR "\t\tOther options in conjunction with HTML:\n";
    print STDERR "\t\t\tEXCELPEPS: write output tab delim xls file including all peptides\n";
    print STDERR "\t\t\tEXCELxx: write output tab delim xls file including all protein (group)s \n\t\t\t\twith minimum probability xx, where xx is a number between 0 and 1\n";
    print STDERR "\n";
    exit(1);
}

my $XML_INPUT = 1;
my $RUN_INDEX = 0;
$CGI_HOME .= '/' if($CGI_HOME !~ /\/$/);

my $IPI_DATABASE = 0;
my $DROSOPHILA_DATABASE = 0;
my $IPI_EXPLORER_PRE = 'http://srs.ebi.ac.uk/srs7bin/cgi-bin/wgetz?-id+m_RJ1KrMXG+-e+[IPI:' . "'"; #'IPI00011028']
my $IPI_EXPLORER_SUF = "'" . ']';

my $E_EXPLORE = 1;
my $E_EXPLORER_PRE = 'http://www.ensembl.org/';
my $E_EXPLORER_MID = 'Homo_sapiens';
my $E_EXPLORER_MID_MOUSE = 'Mus_musculus';
my $E_EXPLORER_SUF = '/protview?peptide=';

my $ACCURACY_MODE = 0; # for paper figures

# for teaching purposes...colors correct prot's red
my $COLOR_CORRECTS = 0;
my @db_prots = (); # stores all entries in database

my $EXCEL_PEPTIDES = 0; # unless specified
my $EXCEL_MINPROB = 0.2; # group prob unless specified

my $PRINT_PROT_COVERAGE = 5; # whether or not to print out (average) coverage for each entry, 
# and if so, max number of degenerate protein members to use as the average for degenerage groups

my $USE_ALT_DEGEN_ENC = 1; # read degen from file (use with $USE_ALT_DEGEN_ENC in mixture_aft.pl)
my $USE_ALT_DEGEN_SUF = '.dgn'; # degen file suffix

my $MALDI = 0; #@ARGV > 1 && $ARGV[1] eq 'MALDI';  # interprets spectrum names differently, all 1+ charge
my $MALDI_TAG = "<!-- MALDI -->";
my $SILENT = 1; # default

my $MERGE_SUBSETS = 1; # whether to have subsets be subsumed by supersets (those prots including all prots and more)

my $DEBUG = 0;
my $STD = 'nothingevertomatch'; #'KTGQAPGFSYTDANK';

my $WT_POWER = 1;
my $UNIQUE_2_3 = 1; # whether or not to count 2+ and 3+ spectra assigned to same peptide as distinct
my $USE_NSP = 1; #1; # whether to learn NSP distributions and use to compute peptide probs
my $NSP_PSEUDOS = 0.005; # use for nsp distributions in each bin

my $DEGEN3_MINWT = 0.2; #0.5;
my $DEGEN3_MINPROB = 0.2; #0.5;
my $PROB_ADJUSTMENT = 0.999; #0.99; #adjustment to prob (use 1.0 for no adjustment)

my $SMOOTH = 0.25; #0.5;  #whether or not to smooth nsp distributions, how much to weight neighbors
my $OCCAM = 1; #1; #1; # whether or not to allocate edge wts according to protein probabilities (for fewest total
               # number of proteins that explain observed data (set to 0 for maximum prot list)

my $PLOT_PNG = 1; # whether or not to run gnuplot to create a png file
my $ANNOTATION = 1; # whether to write protein annotation info below

my $USE_WT_PRIORS = 0; # whether or not to have minimum wt to each protein

my %ENZYMES = (); # collect for all data files
my $ENZYME_TAG = 'ENZYME=';

my $START = 0;
my $MIN_DATA_PROB = 0.05;  # below this prob, data is excluded from analysis

my %subsumed = ();


my $COMPUTE_TOTAL_SPECTRUM_COUNTS = 1; # whether or not to keep track of the percent of total spectra (est correct) that
                                       # correspond to each protein
my %spectrum_counts = ();
my $total_spectrum_counts = 0.0;


my @FILES = glob($ARGV[0]);

# make full path
for(my $f = 0; $f < @FILES; $f++) {
    if($FILES[$f] !~ /^\//) {
	$FILES[$f] = getcwd() . '/' . $FILES[$f];
    }
}


my $ASAP_MIN_WT = 0.5; # peps must be above
my $ASAP_MIN_PEP_PROB = 0.5; # peps must be >=

my $source_files = join(' ', @FILES);


my $source_files_alt = join('+', @FILES);
my $MULTI_FILES = @FILES > 1;
my @probs;
my @triplets;
my $peptide;
my $spectrum;
my $charge;
my $PROCESS_TAG = '<!-- MODEL ANALYSIS -->';  # labels first line in output to indicate prior analysis


my $BATCH_ANNOTATION = 1; # whether or not to store all annotation for database in memory
my @spectra = ();
my @singly_spectra = ();
my %specprobs = ();
my %singly_specprobs = ();
my %specpeps = ();
my %singly_specpeps = ();
my %pep_max_probs;
my %orig_pep_max_probs;
my %pep_prob_ind = (); 
my %prot_peps = ();
my %pep_wts = ();
my %orig_pep_wts = ();

my %pep_nsp = ();

my %group_members = (); # whether or not a protein entry is a member of group
my @groups = (); # ptrs to arrays of each group's members
my $group_index;
my %group_probs = ();
my %group_names = ();
my @grp_indeces;

my %unique = (); # whether or not pep is unique (corresponds to a single protein in dataset)

my @cgifiles = ();
foreach(@FILES) {
    if(/^\//) {
	push(@cgifiles, $_);
    }
    else {
	push(@cgifiles, getcwd() . '/' . $_);
    }
}

my %annotation = ();
my %equivalent_peps = (); # store all actual pep seq's corresponding to hashed equivalent pep

# can get smarter than this for xml format
my %substitution_aas = ('I' => 'L', '#' => '*', '@' => '*'); # which aa's are equivalent, and hence should be converted

# these 2 deprecated
my %MODIFICATIONS_REF = (); # hash by aminoacid/symbol for both static and optional mods
my %mod_index;

my $USE_STD_MOD_NAMES = 1;
my %MODIFICATION_MASSES = (); # hash by aminoacid/symbol for both static and optional mods
my %peptide_masses = ();
my $OMIT_CONST_STATICS = 1;
my %constant_static_mods = ();
my $constant_static_tots = 0;
my $MODIFICATION_ERROR = 0.5;

# example: $MODIFICATIONS_REF{'C'} = \(225.323, 250.78); 
# $MODIFICATIONS_REF{'n'} = \(24.25) for n terminal
#
#


my @pos_shared_prot_distrs = (); 
my @neg_shared_prot_distrs = (); 
my @shared_prot_prob_threshes = (0.1, 0.25, 0.5, 1, 2, 5, 15); #0);
for(my $k = 0; $k <= @shared_prot_prob_threshes; $k++) {
    $pos_shared_prot_distrs[$k] = 1 / (@shared_prot_prob_threshes + 1);
    $neg_shared_prot_distrs[$k] = 1 / (@shared_prot_prob_threshes + 1);
}

my @NSP_BIN_EQUIVS; # enforce monotonic ratio of pos NSP to neg NSP in successive bins...

my $DEGEN_USE_NTT = 1; # for degen groups

my $MIN_WT = 0;
my $MIN_PROB = 0.1;

my $FIN_MIN_PROT_PROB = 0;
my $FIN_MIN_PEP_PROB = 0;

my $NODATA = '-1';
my @datanum = (0,0);
my $singly_datanum = 0;

my %protein_probs = ();

my %final_prot_probs;
my %degen;
my %member;
my %degen_info;

my %sens;
my %err;

my %coverage = (); # protein coverage

my $database = '';
my $HTML_HEADER = '<HTML><BODY BGCOLOR="#FFFFFF" TARGET="Win0" BODY BGCOLOR="#FFFFFF" OnLoad="self.focus();"><PRE><HEAD><TITLE>ProteinProphet (' . $TPPVersionInfo . ')</TITLE></HEAD>';
my $OUTFILE = '';
$OUTFILE = $ARGV[1];
$OUTFILE = getcwd() . '/' . $OUTFILE if($OUTFILE !~ /^\//);

setWritePermissions($OUTFILE);

my $excelfile = 'ProteinProphet.xls';
my $XMLFILE = 'ProteinProphet.xml';

if($OUTFILE =~ /^(\S+\.)htm$/) {
    $XMLFILE = $1 . 'xml';
    $excelfile = $1 . 'xls';
}
elsif($OUTFILE =~ /^(\S+\.)xml$/) {
    $XMLFILE = $1 . 'xml';
    $excelfile = $1 . 'xls';
}
elsif($OUTFILE =~ /^(\S+\.)shtml$/) {
    $XMLFILE = $1 . 'xml';
    $excelfile = $1 . 'xls';
}
else {
    $OUTFILE .= '.htm';
    $XMLFILE = $OUTFILE . 'xml';
    $excelfile = $OUTFILE . 'xls';
}
my $ICAT = 0;
my $GLYC = 0;
my $ASAP = 0;
my $ASAP_PROPHET = 0; # new and improved
my $XPRESS = 0;
my $ASAP_IND = 0;
my $LAST_ASAP_IND = 0;
my $ASAP_INIT = 1;
my $ASAP_REFRESH = 0;
my %ASAP = ();
my $ASAP_FILE = $FILES[0];
if($ASAP_FILE !~ /^\//) {
    $ASAP_FILE = getcwd() . '/' . $ASAP_FILE;
}
my $XML = 1;
my $DEGEN = 1; # unless proven otherwise
my $WINDOWS = 0; # unless proven otherwise
my $USE_GROUPS = 1; 
my $ASAP_EXTRACT = 0;
my %EXTRACTED_INDS = ();
my $STY_MOD = 0;
my $USE_INTERACT = 0;
my $ACCEPT_ALL = 0;
my $EXCLUDE_ZEROS = 0; 
my $XPRESS_ALL = 0;

my $LIBRA = 0;
my $LIBRA_CHANNEL = 0;

my $DB_REFRESH = 0; # database refresh for xml input
# OPTIONS HERE
my $options = join(' ', @ARGV[2 .. $#ARGV]);
for(my $k = 2; $k < @ARGV; $k++) {
    $SILENT = 0 if($ARGV[$k] eq '-verbose');
    $OCCAM = 0 if($ARGV[$k] eq 'NOOCCAM');
    $PLOT_PNG = 0 if($ARGV[$k] eq 'NOPLOT');
    $ICAT = 1 if($ARGV[$k] eq 'ICAT');
    $ACCURACY_MODE = 1 if($ARGV[$k] eq 'ACCURACY');
    $GLYC = 1 if($ARGV[$k] eq 'GLYC');
    $ASAP = 1 if($ARGV[$k] eq 'ASAP');
    $ASAP_REFRESH = 1 if($ARGV[$k] eq 'REFRESH');
    $XML = 1 if($ARGV[$k] eq 'XML');
    $USE_NSP = 0 if($ARGV[$k] eq 'NONSP');
    $DEGEN = 0 if($ARGV[$k] eq 'DELUDE');
    $WINDOWS = 1 if($ARGV[$k] eq 'WINDOWS');
    $USE_GROUPS = 0 if($ARGV[$k] eq 'NOGROUPS');
    $PRINT_HTML = 1 if($ARGV[$k] eq 'HTML');
    $PRINT_PROT_COVERAGE = 0 if($ARGV[$k] eq 'NOCOVERAGE');
    $ASAP_EXTRACT = 1 if($ARGV[$k] eq 'EXTRACT');
    $XPRESS = 1 if($ARGV[$k] eq 'XPRESS');
    $ASAP_PROPHET = 1 if($ARGV[$k] eq 'ASAP_PROPHET');
    $ACCEPT_ALL = 1 if($ARGV[$k] eq 'ACCEPT_ALL');
    $DB_REFRESH = 1 if($ARGV[$k] eq 'DB_REFRESH');
    $EXCLUDE_ZEROS = 1 if($ARGV[$k] eq 'EXCLUDE_ZEROS');
    $XPRESS_ALL = 1 if($ARGV[$k] eq 'XPRESS_ALL');

    if($ARGV[$k] =~ /^LIBRA(\d+)$/) {
	$LIBRA = 1;
	$LIBRA_CHANNEL = $1;
    }

    if($ARGV[$k] =~ /^MINPROB(\S+)$/) {
	$MIN_DATA_PROB = $1;
    }
    $STY_MOD = 1 if($ARGV[$k] eq 'STY');
    $EXCEL_PEPTIDES = 1 if($ARGV[$k] eq 'EXCELPEPS');

    $XML_INPUT = 1 if($ARGV[$k] eq 'XML_INPUT');
    if($ARGV[$k] eq 'EXCELPEPS') {
	$EXCEL_PEPTIDES = 1;
    }
    elsif($ARGV[$k] =~ /^EXCEL(\S+)$/) {
	$EXCEL_MINPROB = $1; 
	$FIN_MIN_PROT_PROB = $EXCEL_MINPROB; 
    }
    $USE_INTERACT = 1 if($ARGV[$k] eq 'INTERACT');
}

$MIN_DATA_PROB = 0 if($ACCURACY_MODE);
$ASAP = 1 if($ASAP_REFRESH); # cannot have refresh without ASAP
$XML = 0 if($PRINT_HTML);
# this one deprecates old ASAP options
if($ASAP_PROPHET) {
    $ASAP = 0;
    $ASAP_REFRESH = 0;
}

$USE_STD_MOD_NAMES = 0 if(! $XML_INPUT);

# here set environment variable so that Xalan works ok in final system call to protxml2html.pl
if(! ($LD_LIBRARY_PATH eq '')) {
    my $preset = 1;
    if(exists $ENV{'LD_LIBRARY_PATH'}) {
	my $match_ind = index($ENV{'LD_LIBRARY_PATH'}, $LD_LIBRARY_PATH);
	if($match_ind < 0) {
	    $preset = 0;
	}
	else {
	    # must make sure both ends are ok
	    if($match_ind > 0) {
		my $next = substr($ENV{'LD_LIBRARY_PATH'}, $match_ind, 1);
		$preset = 0 if(! ($next eq ':'));
	    }
	    if(length($ENV{'LD_LIBRARY_PATH'}) > $match_ind + length($LD_LIBRARY_PATH)) {
		my $next = substr($ENV{'LD_LIBRARY_PATH'}, $match_ind + length($LD_LIBRARY_PATH), 1);
		$preset = 0 if(! ($next eq ':'));
	    }
	}
	if(! $preset) {
	    if($ENV{'LD_LIBRARY_PATH'} eq '') {
		$ENV{'LD_LIBRARY_PATH'} = $LD_LIBRARY_PATH;
	    }
	    else {
		$ENV{'LD_LIBRARY_PATH'} .= ':' . $LD_LIBRARY_PATH;
	    }
	}
    }
    else {
	$ENV{'LD_LIBRARY_PATH'} = $LD_LIBRARY_PATH;
    }
} # if not null LD_LIB_PATH

# greeting
print STDERR "\n $VERSION";
print STDERR " --- maldi mode ---" if($MALDI);
print STDERR " (xml input)" if($XML_INPUT);
print STDERR " (without OCCAM's 'min prot list' razor)" if(! $OCCAM);
print STDERR " (accuracy mode)" if($ACCURACY_MODE);
print STDERR " (no nsp)" if(! $USE_NSP);
print STDERR " (icat mode)" if($ICAT);
print STDERR " (glyc mode)" if($GLYC);
print STDERR " (no groups)" if(! $USE_GROUPS);
print STDERR " (XPRESS)" if($XPRESS);
print STDERR " (XPRESS ALL)" if($XPRESS_ALL);
print STDERR " (ASAPRatio)" if($ASAP_PROPHET);
print STDERR " (LIBRA norm channel: $LIBRA_CHANNEL)" if($LIBRA);
if($ASAP_REFRESH) {
    print STDERR " (ASAP refresh";
    print STDERR "/extract" if($ASAP_EXTRACT);
    print STDERR ")";
}
elsif($ASAP) {
    print STDERR " (ASAP)";
}
if($DEGEN) {
    print STDERR " (using degen pep info)";
}
else {
    print STDERR " (w/o degen pep info)";
}
print STDERR " (no coverage)" if(! $PRINT_PROT_COVERAGE);
print STDERR " (excluding STY mods)" if($STY_MOD);
print STDERR " (using Interact files)" if($USE_INTERACT);
print STDERR " (HTML output)" if($PRINT_HTML);
print STDERR " (accept all peps)" if($ACCEPT_ALL);
print STDERR " (database refresh)" if($DB_REFRESH);
print STDERR " (exclude zero prob entries)" if($EXCLUDE_ZEROS);
print STDERR "\n";

validateSubstitutionAAs(\%substitution_aas);

my %ASAP_INDS = ();

my $index = 1;

my %estNSP = ();


%substitution_aas = ('I' => 'L') if($XML_INPUT && $USE_STD_MOD_NAMES);

foreach(@FILES) {
    if($XML_INPUT) {
	readDataFromXML($_);
    }
    elsif(! readData($_, $index++)) {
	$index--;
	readDataFromInteractFile($_, $index++);
    }
}

#getBatchAnnotation($database) if(! $XML_INPUT && $BATCH_ANNOTATION && $ANNOTATION);
getBatchAnnotation($database) if($BATCH_ANNOTATION && $ANNOTATION);

setPepMaxProbs(0,0,0);

setInitialWts();

setExpectedNumSiblingPeps();
print STDERR " finished setting NSP values!\n" if($DEBUG);

my $first_iters = iterate1(50);

($MIN_WT, $MIN_PROB) = ($DEGEN3_MINWT, $DEGEN3_MINPROB);

(my $third_iters, my $fourth_iters) = multiiterate(100);

setPepMaxProbs(1, ! $ACCEPT_ALL, $COMPUTE_TOTAL_SPECTRUM_COUNTS);

findDegenGroups3(0, 0.5, $DEGEN_USE_NTT);

computeDegenWts();

($MIN_WT, $MIN_PROB) = (0, 0.2);

($MIN_WT, $MIN_PROB) = (0.5, 0.2);
my $final_iters = final_iterate(50);


($MIN_WT, $MIN_PROB) = (0.5, 0.2);

$MIN_WT = 0.05 if(! $OCCAM);  # if not adjust weights, include virtually everything

my $FINAL_PROB_MIN_WT = $MIN_WT;
my $FINAL_PROB_MIN_PROB = $MIN_PROB;

computeFinalProbs();

findGroups() if($USE_GROUPS);

my $INCLUDE_GROUPS = 1;

my $min_prot_prob = 0;
(my $num_prots1, my $num_prots) = numProteins($min_prot_prob, 1);

my $SENSERR = 1;
my @threshes = (0, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 0.96, 0.97, 0.98, 0.99, 1);
$OUTFILE = getcwd() . '/data' if($OUTFILE eq '');
my $datafile = $OUTFILE . '_' . 'senserr.txt';
my $imagefile = $OUTFILE . '_' . 'senserr.png';
my $scriptfile = $OUTFILE . '_' . 'senserr.tmp';
if($OUTFILE =~ /^(\S+\.)html?$/) {
    $datafile = $1 . 'senserr.txt';
    $imagefile = $1 . 'png';
    $scriptfile = $1 . 'senserr.tmp';
}
if($XMLFILE =~ /^(\S+\.)xml$/) {
    $imagefile = $1 . 'png';
}
writeErrorAndSens($datafile, \@threshes, $INCLUDE_GROUPS);
writeScript($datafile, $scriptfile, $imagefile, $num_prots) if ($PLOT_PNG);

if($PRINT_HTML) {
    open(OUTFILE, ">$OUTFILE") or die "cannot open OUT $OUTFILE $!\n";
    print OUTFILE "$HTML_HEADER\n";
    print OUTFILE "-------------------------------------------------------------------------------\n";
    print OUTFILE " $VERSION\n";
    print OUTFILE "-------------------------------------------------------------------------------\n";
    print OUTFILE "ProteinProphet.pl ", join(' ', @ARGV), "\n";
    printf OUTFILE "read in %d 1+, %d 2+, and %d 3+ spectra (tot %d) with min prob $MIN_DATA_PROB\n\n", $singly_datanum, $datanum[0], $datanum[1], $singly_datanum + $datanum[0] + $datanum[1];
    print OUTFILE "iteration 1: $first_iters\n";
    print OUTFILE "multiiterate: wts: $third_iters, NSP: $fourth_iters\n";
    printNSPDistrs();
    print OUTFILE "final iters: $final_iters\n";

} # if print html
my $INIT_MIN_DATA_PROB = $MIN_DATA_PROB;

$MIN_WT = 0;


computeCoverage(0.1, $PRINT_PROT_COVERAGE) if($PRINT_PROT_COVERAGE);

if($PRINT_HTML) {

   printProteinProbs($FIN_MIN_PROT_PROB, $FIN_MIN_PEP_PROB); 

   close(OUTFILE);
   writeExcelOutput($FIN_MIN_PROT_PROB, $FIN_MIN_PEP_PROB, $excelfile);

   # get local file names if windows/cygwin....
   my $local_htmlfile = $OUTFILE;
   my $local_excelfile = $excelfile;
   if($WINDOWS_CYGWIN) {
       if((length $SERVER_ROOT) <= (length $local_htmlfile) && 
	  index((lc $local_htmlfile), (lc $SERVER_ROOT)) == 0) {
	   $local_htmlfile = '/' . substr($local_htmlfile, (length $SERVER_ROOT));
       }
       else {
	   die "problem: $local_htmlfile is not mounted under webserver root: $SERVER_ROOT\n";
       }
       if((length $SERVER_ROOT) <= (length $local_excelfile) && 
	  index((lc $local_excelfile), (lc $SERVER_ROOT)) == 0) {
	   $local_excelfile = '/' . substr($local_excelfile, (length $SERVER_ROOT));
       }
       else {
	   die "problem: $local_excelfile is not mounted under webserver root: $SERVER_ROOT\n";
       }
   } # if iis & cygwin


   print STDERR "\n protein probabilities written to file $local_htmlfile\n";
   print STDERR "\n tab delimited results with min prob $EXCEL_MINPROB ";
   print STDERR "(including peptides) " if($EXCEL_PEPTIDES);
   print STDERR "written to $local_excelfile\n";
   print STDERR "\n";
}

$FIN_MIN_PROT_PROB = 0.2 if($EXCLUDE_ZEROS);

if($XML) {

    my $num_final_prots = scalar keys %final_prot_probs;
    open(XML, ">$XMLFILE");
    writeXMLOutput($FIN_MIN_PROT_PROB, $FIN_MIN_PEP_PROB, $XMLFILE);
    close(XML);

    my @xsl_results = ();
    if (defined($XSL_MAKER)) {
        my $command = "$XSL_MAKER -file $XMLFILE $num_final_prots";
        $command .= " ICAT" if($ICAT);
        $command .= " GLYC" if($GLYC);
        if(-e $XSL_MAKER) {
            open XSL, "$command |";
            @xsl_results = <XSL>;
            close(XSL);
            #system($command);
        }
        else {
            die "cannot find $XSL_MAKER\n";
        }
    }
    my $parser = 'parser';
    my $xpressparser = 'XPressProteinRatioParser';
    my $asapparser = 'ASAPRatioProteinRatioParser';
    my $asappvalueparser = 'ASAPRatioPvalueParser';
    my $libraparser = 'LibraProteinRatioParser';

   if($LIBRA && $XML_INPUT) {
       my $fullpath = validateExecutableFile($libraparser);

       if(! $fullpath) {
	   print STDERR "$libraparser not available for importing LIBRA ratios\n";
       }
       else {
	   print " importing LIBRA (norm channel: $LIBRA_CHANNEL) protein ratios...."; 
	   system("$fullpath $XMLFILE $LIBRA_CHANNEL");
	   print "\n";
       }

   } # libra
    if($XPRESS || $XPRESS_ALL) {
	if($XML_INPUT) {
	    my $fullpath = validateExecutableFile($xpressparser);

	    if(! $fullpath) {
		print STDERR "$xpressparser not available for importing XPRESS ratios\n";
	    }
	    else {
		print " importing XPRESS protein ratios...."; 
		system("$fullpath $XMLFILE");
		print "\n";
	    }

	} # xml input
	else {
	    my $fullpath = validateExecutableFile($parser);
	    if(! $fullpath) {
		print STDERR "$parser not available for importing XPRESS ratios\n";
	    }
	    else {
		print " importing XPRESS protein ratios...."; 
		if($XPRESS_ALL) {
		    #print "$fullpath $XMLFILE xpress 0\n";
		    system("$fullpath $XMLFILE xpress 0");
		}
		else {
		    #print "$fullpath $XMLFILE xpress\n";
		    system("$fullpath $XMLFILE xpress");
		}
		print "\n";
	    }

	} # not xml (old version)
    } # XPRESS
    if($ASAP_PROPHET) {
	if($XML_INPUT) {
	    my $fullpath = validateExecutableFile($asapparser);
	    if(! $fullpath) {
		print "$asapparser not available for importing ASAPRatio ratios\n";
	    }
	    else {
		print " importing ASAPRatio protein ratios...."; 
		system("$fullpath $XMLFILE");
	    }

	    $fullpath = validateExecutableFile($asappvalueparser);
	    if(! $fullpath) {
		print "\n$asappvalueparser not available for computing ASAPRatio pvalues\n";
	    }
	    else {

# 		if($WINDOWS_CYGWIN) {
# 		    # compute the webserver relative png file ahead of time
# 		    if($XMLFILE =~ /^(\S+)\.xml/) {
# 			my $local_png = $1 . '-pval.png';
# 			if((length $SERVER_ROOT) <= (length $local_png) && 
# 			   index((lc $local_png), (lc $SERVER_ROOT)) == 0) {
# 			    $local_png = '/' . substr($local_png, (length $SERVER_ROOT));
# 			}
# 			else {
# 			    die "problem: $local_png is not mounted under webserver root: $SERVER_ROOT\n";
# 			}
# 			print "and pvalues...."; 
# 			system("$fullpath $XMLFILE $local_png");
# 		    }
# 		}
# 		else {
		    print "and pvalues...."; 
		    system("$fullpath $XMLFILE");
#		}
		print "\n";
	    }

	} # xml input
	else {
	    my $fullpath = validateExecutableFile($parser);
	    if(! $fullpath) {
		print "$parser not available for importing ASAP ratios\n";
	    }
	    else {
		print " importing ASAP protein ratios...."; 
		system("$fullpath $XMLFILE asap");

		if($WINDOWS_CYGWIN) {
		    # compute the webserver relative png file ahead of time
		    if($XMLFILE =~ /^(\S+)\.xml/) {
			my $local_png = $1 . '-pval.png';
			if((length $SERVER_ROOT) <= (length $local_png) && 
			   index((lc $local_png), (lc $SERVER_ROOT)) == 0) {
			    $local_png = '/' . substr($local_png, (length $SERVER_ROOT));
			}
			else {
			    die "problem: $local_png is not mounted under webserver root: $SERVER_ROOT\n";
				}
			print "and pvalues...."; 
			system("$fullpath $XMLFILE pvalue $local_png");
			print "\n";
		    }
		}
		else {
		    print "and pvalues...."; 
		    system("$fullpath $XMLFILE pvalue");
		    print "\n";
		}
	    }

	}

    } # asap

    print "", join('', @xsl_results);

} # if xml


if(0 && $COMPUTE_TOTAL_SPECTRUM_COUNTS) {
    print "Total: $total_spectrum_counts\n";
    foreach(keys %spectrum_counts) {
	print "$_: $spectrum_counts{$_}\n";
    }
}




########################################################################################################
#                                                                                                      #
#                                             SUBROUTINES                                              #
#                                                                                                      #
########################################################################################################

sub validateExecutableFile {
(my $file) = @_;
open(WHICH, "which $file |");
my $found = 0;
my @results = <WHICH>;
close(WHICH);
if(@results > 0) {
    chomp $results[0];
    $found = 1 if($results[0] =~ /^\//);
}
return $results[0] if($found);
return '';
}

sub validateSubstitutionAAs {
(my $ptr) = @_;
my @formers = keys %{$ptr};
for(my $f = 0; $f < @formers; $f++) {
    for(my $g = 0; $g < @formers; $g++) {
	if($f != $g && $formers[$f] eq ${$ptr}{$formers[$g]}) {
	    die " problem with substitution aa's, whereby $formers[$g] -> ${$ptr}{$formers[$g]} -> ${$ptr}{$formers[$f]}\n";
	}
    }
}
}


sub multiiterate {
(my $max_num_iters) = @_;
my $counter = 0;
while($counter < $max_num_iters && multiupdate()) {
    $counter++;
}
my $counter2 = 0;

# now adjust the nsp distributions
while($counter2 < $max_num_iters && $USE_NSP && updateNSPDistributions()) {
    $counter2++;
    print STDERR " updating nsp distributions.....\n" if(! $SILENT);
}

return ($counter, $counter2);
}



sub multiupdate {
my $output = 0;
if(updateProteinProbs()) {
    print STDERR " updating protein probs.....\n" if(! $SILENT);
    $output = 1;
}
$output &&= updateProteinWeights(0) if($OCCAM);

print STDERR "------------------\n" if(! $SILENT);

return $output;
}

sub printNSPDistrs {
    print OUTFILE "\nNSP distributions";
    print OUTFILE " (with neighboring bin smoothing wt $SMOOTH)" if($SMOOTH);
    print OUTFILE "\nindex\t\t\tpos\tneg\tratio\n";
    my $start;
for(my $k = 0; $k < @pos_shared_prot_distrs; $k++) {
    if($k == 0) {
	$start = 0;
    }
    else {
	$start = $shared_prot_prob_threshes[$k-1];
    }
    if($k < @pos_shared_prot_distrs - 1) {
	printf OUTFILE "$k (%0.2f<=nsp<%0.2f): \t%0.3f\t%0.3f\t%0.3f", $start, $shared_prot_prob_threshes[$k], $pos_shared_prot_distrs[$k], $neg_shared_prot_distrs[$k], $pos_shared_prot_distrs[$k]/$neg_shared_prot_distrs[$k];
    }
    else {
	printf OUTFILE "$k (%0.2f<=nsp     ): \t%0.3f\t%0.3f\t%0.3f", $start, $pos_shared_prot_distrs[$k], $neg_shared_prot_distrs[$k], $pos_shared_prot_distrs[$k]/$neg_shared_prot_distrs[$k];
    }
    if($NSP_BIN_EQUIVS[$k] != $k) {
	printf OUTFILE " (%0.3f)", $pos_shared_prot_distrs[$NSP_BIN_EQUIVS[$k]]/$neg_shared_prot_distrs[$NSP_BIN_EQUIVS[$k]];
    }
    print OUTFILE "\n";
}
    print OUTFILE "\n";
}

sub getFirstLine {
(my $file) = @_;
die "cannot find $file\n" if(! -e $file);
open(FILE, $file);
while(<FILE>) {
    my $output = $_;
    close(FILE);
    return $output;
}
close(FILE);
die "could not find first line for $file\n";
}

sub readDegens {
(my $degenfile) = @_;
die "cannot find $degenfile\n" if(! -e $degenfile);
%degen_info = (); # hashed by spectrum


open(DEGEN_INFO, $degenfile);
while(<DEGEN_INFO>) {
    if(/^\.\/(\S+)\s+(\S+.*)$/) {
	$degen_info{$1} = $2;
    }

    elsif(/^(\S+)\s+(\S+.*)$/) {
	$degen_info{$1} = $2;
    }
    else {
	print STDERR "cannot parse $_\n";
    }

}
close(DEGEN_INFO);
}


sub getDateTime {
    my $timestamp = time;
    my $td = localtime($timestamp);

    my $time = sprintf("%04d-%02d-%02dT%02d:%02d:%02d", $td->year + 1900, $td->mon+1, $td->mday, $td->hour, $td->min, $td->sec);
    return $time;

}

sub readDataFromXML {
(my $xmlfile) = @_;
# first get database
my $database_parser;
my $refresh_parser;
if($WINDOWS_CYGWIN) {
   $database_parser = '/usr/bin/DatabaseParser.exe';
   $refresh_parser = '/usr/bin/RefreshParser.exe';
}
else {
    $database_parser = $BINARY_DIRECTORY . 'DatabaseParser';
    $refresh_parser = $BINARY_DIRECTORY . 'RefreshParser';
}

die "cannot find $database_parser\n" if(! -e $database_parser && ! -e $database_parser . ".exe");
die "cannot find $refresh_parser\n" if($DB_REFRESH && ! -e $refresh_parser && ! -e $refresh_parser . ".exe");

print "Calling $database_parser $xmlfile\n"; #bxm

open DB, "$database_parser $xmlfile |";
my @results = <DB>;
if(@results > 0) {
    chomp $results[0];
    if(! ($database eq '') && ! ($database eq $results[0])) {
	print "Error: input files reference different databases: $database and $results[0]\n";
	print "Use RefreshParser to update all input files to common database\n";
	exit(1);
    }
    elsif($database eq '') {
	$database = $results[0];
	if($database =~ /\,/) {
	    print "Error: multiple databases ($database) referenced by $xmlfile\n";
	    print "Use RefreshParser to update all entries to common database\n";
	    exit(1);
	}
    } # if no prev database
}
else {
    print "Error: No database referenced by $xmlfile\n";
    exit(1);
}
close(DB);

print STDERR " processing $xmlfile ... ";

if($DB_REFRESH) {
    print "Calling $refresh_parser $xmlfile '$database'\n"; #bxm
    print STDERR "\n";
    system("$refresh_parser $xmlfile '$database'");
}

$IPI_DATABASE = 1 if($database =~ /IPI/ || $database =~ /ipi/);
$DROSOPHILA_DATABASE = 1 if($database =~ /rosophila/);
# now ready to read results from xmlfile
my @parsed_probs = (-1.0, -1.0, -1.0);
my $prob = -1.0;
my $protein = '';
my $peptide = '';
my $ntt = -1;
my @alt_prots = ();
my @alt_ntts = ();
my @alt_annots = ();
my $output = 0;
my $annot = '';
my $VERBOSE = 0;
my $NONEXISTANT = 'NON_EXISTENT';
my $analyze = 0;
my $next_protein;

my @tots = (0, 0, 0);
my $error = 0.25; # modified aa's within this error of one another's masses are considered the same

my $nterm;
my $cterm;
my %mods;
my $pepmass;

print "Reading results.\n";	#bxm

open(XML, $xmlfile) or die "cannot open XML $xmlfile $!\n";
while(<XML>) {
    if(/\<sample\_enzyme\s+name\=\"(\S+)\"/) {
	$ENZYMES{$1}++;
    }
    if(/\<msms\_run\_summary\s+/) {
	$RUN_INDEX++;
    }
    if($OMIT_CONST_STATICS && /\<search\_summary/) {
	$constant_static_tots++ if($OMIT_CONST_STATICS); #%mod_index = (); # reset
    }
    elsif($OMIT_CONST_STATICS && /\<aminoacid\_modification\s+aminoacid\=\"(\S)\".*mass\=\"(\S+)\".*variable\=\"N\"/) {
	my $mass = sprintf("%0.0f", $2);
	if($constant_static_tots == 1) {
	    my %next = ($mass => 1);
	    $constant_static_mods{$1} = \%next;
	    foreach(keys %constant_static_mods) { 
               #print "const static for aa: $_: \n"; 
	    }
	}
	else {
	    ${$constant_static_mods{$1}}{$mass}++ if(exists $constant_static_mods{$1} && exists ${$constant_static_mods{$1}}{$mass});
	}
    }
    elsif($OMIT_CONST_STATICS && /\<terminal\_modification\s+terminus\=\"(\S)\".*mass\=\"(\S+)\".*variable\=\"N\"/) {
	my $mass = sprintf("%0.0f", $2);
	if($constant_static_tots == 1) {
	    my %next = ($mass => 1);

	$constant_static_mods{$1} = \%next;
	}
	else {
	    ${$constant_static_mods{$1}}{$mass}++ if(exists $constant_static_mods{$1} && exists ${$constant_static_mods{$1}}{$mass});
	}
    }
# ADD THE RUN BASENAME HERE.......
    elsif(/\<spectrum\_query/) {
	$analyze = 1;
	if(/\s+spectrum\=\"(\S+)\"/) {
	    $spectrum = $RUN_INDEX . '_' . $1;
	    if($spectrum =~ /^(\S+)\.\d$/) {
		$spectrum = $1;
	    }
	}
	if(/\s+assumed\_charge\=\"(\S+)\"/) {
	    $charge = $1 - 2;
	}
    }
    elsif($analyze) {


	if(/\<search\_hit.*hit\_rank=\"1\"/) {

	    if(/\s+peptide\=\"(\S+)\"/) {
		$peptide = $1;
	    }
	    if(/\s+protein\=\"(\S+)\"/) {
		$protein = $1;
	    }
	    if(/\s+protein\_descr\=\"(\S.*?\S)\s*\"/) {
		$annot = $1;
	    }
	    if(/\s+num\_tol\_term\=\"(\S+)\"/) {
		$ntt = $1;
	    }
	    if($USE_STD_MOD_NAMES && /\s+calc\_neutral\_pep\_mass\=\"(\S+)\"/) {
		$pepmass = $1;
	    }

	    # reset
	    $nterm = 0;
	    $cterm = 0;
	    %mods = ();
	}
	elsif(/\<peptideprophet\_result/) {
	    if(/\s+probability\=\"(\S+)\"/) {
		$prob = $1;
	    }
	    if(/\s+all\_ntt\_prob\=\"\((\S+)\)\"/) {
		my $next_probs = $1;
		if($next_probs =~ /(\S+)\,(\S+)\,(\S+)/) {
		    $parsed_probs[0] = $PROB_ADJUSTMENT * $1;
		    $parsed_probs[1] = $PROB_ADJUSTMENT * $2;
		    $parsed_probs[2] = $PROB_ADJUSTMENT * $3;
		}
	    }
	}
	elsif(/\<alternative\_protein/) {
	    if(/\s+protein\=\"(\S+)\"/) {
		push(@alt_prots, $1);
	    }
	    if(/\s+num_tol_term\=\"(\S+)\"/) {
		push(@alt_ntts, $1);
	    }
	    if(/\s+protein\_descr\=\"(.*?)\"/) {
		push(@alt_annots, $1);
	    }
	}
	elsif($USE_STD_MOD_NAMES && /\<modification\_info/) {
	    if(/\s+mod\_nterm\_mass\=\"(\S+)\"/) {
		$nterm = $1;
	    }
	    if(/\s+mod\_cterm\_mass\=\"(\S+)\"/) {
		$cterm = $1;
	    }
	}
	elsif($USE_STD_MOD_NAMES && /\<mod\_aminoacid\_mass/) {
	    if(/\s+position\=\"(\S+)\".*\s+mass\=\"(\S+)\"/) {
		$mods{$1} = $2;
	    }
	}

	# can add quantitation info here....


	elsif(/\<\/spectrum\_query/) {

	    # process and reset
	    $analyze = 0;
	    if(! ($protein eq $NONEXISTANT) && $prob > $MIN_DATA_PROB) {


		$tots[$charge+1]++;
	    my @probs = ();
	    foreach(@parsed_probs) {
		push(@probs, $_);
	    }

	    if($VERBOSE) {
		printf("%s %d %d %s %0.2f %0.2f %0.2f %s %s\n", $spectrum, $charge, $ntt, $peptide, $probs[0]/$PROB_ADJUSTMENT, $probs[1]/$PROB_ADJUSTMENT, $probs[2]/$PROB_ADJUSTMENT, $protein, $annot);
		for(my $k = 0; $k < @alt_prots; $k++) {
		    printf("\talt: %s %d %s\n", $alt_prots[$k], $alt_ntts[$k], $alt_annots[$k]);
		}
	    } # if verbose

	    if($charge == -1) {
		$singly_datanum++;
	    }
	    else {
		$datanum[$charge]++;
	    }
	    my $output;
	    if (length($annot) > 0) {
		$annotation{$protein} = $annot;
	    }
            # get the standard name
	    $peptide = getStdModifiedPeptide($peptide, $nterm, $cterm, \%mods, $error) if($USE_STD_MOD_NAMES);

	    # add on preceding
	    $peptide = ($charge+2) . '_' . $peptide if($UNIQUE_2_3);

	    # subst equivalent aa's	
	    $peptide = equivalentPeptide(\%substitution_aas, \%equivalent_peps, $peptide);

            # record mass here
	    $peptide_masses{$peptide} = $pepmass if($USE_STD_MOD_NAMES);

	    $unique{$peptide} = 1 if(! exists $unique{$peptide}); # it is unique
	    if(exists $pep_prob_ind{$peptide}) {
		${$pep_prob_ind{$peptide}}{$protein} = 0;
		${$pep_wts{$peptide}}{$protein} = 1.0 / (@alt_prots + 1); # ADK;
		${$pep_prob_ind{$peptide}}{$protein} = $ntt;
	    }
	    else {
		my %next3 = ($protein => 0);
		$pep_prob_ind{$peptide} = \%next3;
		my %next4 = ($protein => 1.0 / (@alt_prots + 1)); # ADK
		$pep_wts{$peptide} = \%next4;
		my %next5 = ($protein => $ntt);
		$pep_prob_ind{$peptide} = \%next5;
	    }
	    if(exists $prot_peps{$protein}) {
		${$prot_peps{$protein}}{$peptide}++;
	    }
	    else {
		my %next = ($peptide => 1);
		$prot_peps{$protein} = \%next;
	    }

	    # take care of degenerate cases
	    if(@alt_prots > 0) {
		$unique{$peptide} = 0;


		my @degentries = split(' ', $5);
		die "problem with $_\n" if(@degentries%2 != 0);
		for(my $k = 0; $k < @alt_prots; $k ++) {
		    $next_protein = $alt_prots[$k];
		    if (length($alt_annots[$k]) > 0) {
			$annotation{$next_protein} = $alt_annots[$k];
		    }
		    if(exists $pep_prob_ind{$peptide}) {
			${$pep_prob_ind{$peptide}}{$next_protein} = $alt_ntts[$k]; 
			${$pep_wts{$peptide}}{$next_protein} = 1 / (@alt_prots+1); # ADK
			${$pep_wts{$peptide}}{$next_protein} = ${$pep_wts{$peptide}}{$next_protein}**$WT_POWER; # BSP: this was "${$pep_wts{$peptide}}{$protein}"
		    }
		    else {
			my %next3 = ($next_protein => $alt_ntts[$k]); 
			$pep_prob_ind{$peptide} = \%next3;
			my %next4 = ($next_protein => (1 / (@alt_prots+1))**$WT_POWER); # ADK
			$pep_wts{$peptide} = \%next4;
		    }
		    if(exists $prot_peps{$next_protein}) {
			${$prot_peps{$next_protein}}{$peptide}++;
		    }
		    else {
			my %next = ($peptide => 1);
			$prot_peps{$next_protein} = \%next;
		    }
		} # next deg entry
	    } # if degen


	    if($VERBOSE) {
		print "protein: $protein $spectrum\n";
		if(exists $prot_peps{$protein}) {
		    foreach(keys %{$prot_peps{$protein}}) {
			print "$protein: $_\n";
		    }
		}
	    }


	    if($peptide eq $STD) {
		my @peps2 = sort keys %{$prot_peps{$protein}};
		for(my $z = 0; $z < @peps2; $z++) { print STDERR "$peps2[$z] "; } print STDERR "\n";
	    }

	    if($charge >= 0) {
		if(exists $specpeps{$spectrum}) {
		    $output = 1;
		    ${$specpeps{$spectrum}}[$charge] = $peptide;
		    ${$specprobs{$spectrum}}[$charge] = \@probs;
		}
		else { # make new entry for spectrum
		    $output = 0;
		    my @next1 = ($NODATA, $NODATA);
		    my @next2 = ($NODATA, $NODATA);

		    $specpeps{$spectrum} = \@next1;
		    ${$specpeps{$spectrum}}[$charge] = $peptide;

		    $specprobs{$spectrum} = \@next2;
		    ${$specprobs{$spectrum}}[$charge] = \@probs;
		}
	    }
	    else { # singlys

		if($charge == -1) {
		    if(exists $singly_specpeps{$spectrum}) {
			die "already seen $spectrum with charge ", $charge+2, "\n";
		    }
		    $output = 0;
		    $singly_specpeps{$spectrum} = $peptide;
		    $singly_specprobs{$spectrum} = \@probs;
		}
	    } # singlys

	    if(! $output) {
		push(@spectra, $spectrum) if($charge >= 0);
		push(@singly_spectra, $spectrum) if($charge == -1);
	    }
	} # if valid protein

	    # reset
	    $spectrum = '';
	    @alt_prots = ();
	    @alt_ntts = ();
	    @alt_annots = ();
	    @parsed_probs = (-1.0, -1.0, -1.0);
	    $peptide = '';
	    $protein = '';
	    $ntt = -1;
	    $annot = '';
	    $prob = -1.0;
	} # if analyze
    }

} # next line of xml
close(XML);
print STDERR " read in $tots[0] 1+, $tots[1] 2+, and $tots[2] 3+ spectra with min prob $MIN_DATA_PROB\n"; 

if(0 && $OMIT_CONST_STATICS) {
    print "Total number of runs: $constant_static_tots\n";
    foreach(sort keys %constant_static_mods) {
	my @masses = sort keys %{$constant_static_mods{$_}};
	for(my $k = 0; $k < @masses; $k++) {
	    print "$_ $masses[$k]: ${$constant_static_mods{$_}}{$masses[$k]}\n";
	}
    }
}
}


# this one uses .esi and .prob files to gather all information (interact-independent)
sub readData {
(my $datafile_input, my $index) = @_;
return 0 if($USE_INTERACT); # force
my $datafile = $datafile_input;
if($datafile =~ /^(\S+)\.orig$/) {
    $datafile = $1;
}

my $esifile = $datafile . '.esi';
my $probfile = $datafile . '.prob';


if(! -e $esifile) {
    print STDERR " without $esifile\n";
}
if(! -e $probfile) {
    print STDERR " without $probfile\n";
}
return 0 if(! -e $esifile);
return 0 if(! -e $probfile);

my $PREFIX = $index . '_';
print STDERR " reading $datafile ... ";
print OUTFILE "$datafile: ";
STDOUT->autoflush(1);
my @previous = ($datanum[0], $datanum[1]);
my $singly_previous = $singly_datanum;
my $degenfile = 'PeptideProphet' . $USE_ALT_DEGEN_SUF;
my $maldi_set = 0;

# attend to degeneracies
if($DEGEN && $USE_ALT_DEGEN_ENC) {
    if($datafile =~ /\S/) {
	$degenfile = $datafile . $USE_ALT_DEGEN_SUF; 
    }



    getDegeneracies($datafile) if(! -e $degenfile);
    readDegens($degenfile) if(-e $degenfile);

}


# first read and store all probs from .prob file
my %spectrum_probs = ();
open(PROB, $probfile);
while(<PROB>) {
    my @parsed = split(' ');
    if($ACCEPT_ALL) {
	$spectrum_probs{$parsed[0]} = 1.0;
    }
    else {
	$spectrum_probs{$parsed[0]} = $parsed[1];
    }
}
close(PROB);


my $first = 1;
my $degen;
open(ESI, $esifile);
my $next_enz = 'tryptic';
my $pep_ind = -1;
my $prot_ind = -1;
my $charge_ind = -1;
my $spec_ind = -1;
my $ntt_ind = -1;
my $ESI_MALDI_TAG = "MALDI=";
while(<ESI>) {
    if($first && /DATABASE\=(\S+)\s?/) {
	chomp();
	$database = $1 if($database eq '');
	# convert windows to unix
	if(! ($database eq '') && -f '/bin/cygpath' ) {

	    if ($database =~ /\:/ ) {
		$database = `cygpath '$database'`;
		($database) = ($database =~ /(\S+)/);
	    }

	}

	$IPI_DATABASE = 1 if($database =~ /IPI/ || $database =~ /ipi/);
	$DROSOPHILA_DATABASE = 1 if($database =~ /rosophila/);

	$E_EXPLORER_MID = $E_EXPLORER_MID_MOUSE if($IPI_DATABASE && ($database =~ /MOUSE/ || $database =~ /mouse/));

	$first = 0;
	if(index($_, $ENZYME_TAG) >= 0) {
	    $next_enz = substr($_, index($_, $ENZYME_TAG) + length($ENZYME_TAG));
	    if($next_enz =~ /^(\S+)\s+/) { # strip off what follows
		$next_enz = $1;
	    }
	}
	my $maldi_index = index($_, $ESI_MALDI_TAG);
	if($maldi_index >= 0) {
	    $MALDI = substr($_, $maldi_index + (length $ESI_MALDI_TAG), 1);
	    $maldi_set = 1;
	}
    }
    else {

	my $verbose = 0; #/NSSM\*DLHLQQW/;


	my @parsed = split(' ');
	$degen = 0;
	
	if($pep_ind == -1) {
	    for(my $k = 0; $k < @parsed - 1; $k++) {
		if($parsed[$k] eq 'spec') {
		    $spec_ind = $k+1;
		}
		elsif($parsed[$k] eq 'charge') {
		    $charge_ind = $k+1;
		}
		elsif($parsed[$k] eq 'ntt') {
		    $ntt_ind = $k+1;
		}
		elsif($parsed[$k] eq 'prot') {
		    $prot_ind = $k+1;
		}
		elsif($parsed[$k] eq 'pep') {
		    $pep_ind = $k+1;
		}
	    }
	    if($pep_ind == -1) {
		print STDERR "cannot find peptide index in $esifile\n";
		exit(1);
	    }
	} # if not yet determined

	if(exists $degen_info{$parsed[$spec_ind] . '.' . $parsed[$charge_ind]}) {
	    $degen = $degen_info{$parsed[$spec_ind] . '.' . $parsed[$charge_ind]};
	}

	if($verbose) {

	    print "$parsed[$spec_ind], -1, $spectrum_probs{$parsed[$spec_ind]}, $parsed[$pep_ind], $parsed[$prot_ind], $degen, $parsed[$ntt_ind]\n";
	}
	
	enter($PREFIX . $parsed[$spec_ind], -1, $spectrum_probs{$parsed[$spec_ind]}, $parsed[$pep_ind], $parsed[$prot_ind], $degen, $parsed[$ntt_ind]) if($MALDI);
	enter($PREFIX . $parsed[$spec_ind], $parsed[$charge_ind]-2, $spectrum_probs{$parsed[$spec_ind] . '.' . $parsed[$charge_ind]}, $parsed[$pep_ind], $parsed[$prot_ind], $degen, $parsed[$ntt_ind]) if(! $MALDI);
    }
   
}
close(ESI);

$ENZYMES{$next_enz}++; # add the enzyme for this file to the list

die "could not find database\n" if($database eq '');
$ANNOTATION = 0 if($database eq '' || ! -e $database);

print STDERR " read in ", $singly_datanum-$singly_previous, " 1+, ", $datanum[0]-$previous[0], " 2+, and ", $datanum[1]-$previous[1], " 3+ spectra with min prob $MIN_DATA_PROB"; 
print STDERR " (maldi mode)" if($MALDI);
print STDERR "\n";
STDOUT->autoflush(1);

print OUTFILE "read in ", $singly_datanum-$singly_previous, " 1+, ", $datanum[0]-$previous[0], " 2+, and ", $datanum[1]-$previous[1], " 3+ spectra with min prob $MIN_DATA_PROB\n"; 
if($singly_datanum - $singly_previous + $datanum[0] - $previous[0] + $datanum[1] - $previous[1] == 0) {
    print STDERR " no analysis possible for $datafile, aborting analysis\n";
    exit(1);
}
return 1;
}


sub readDataFromInteractFile {

(my $datafile, my $index) = @_;
die "cannot find $datafile\n" if(! -e $datafile);
my $PREFIX = $index . '_';
print STDERR " reading $datafile ... ";
print OUTFILE "$datafile: ";
STDOUT->autoflush(1);
my @previous = ($datanum[0], $datanum[1]);
my $singly_previous = $singly_datanum;

my @dat = ();
my $tot = 0.0;

my $firstline = getFirstLine($datafile);
die "$datafile not analyzed with interactp, aborting...\n" if(index($firstline, $PROCESS_TAG) < 0);
$MALDI = index($firstline, $MALDI_TAG) >= 0;

if($database eq '' && $firstline =~ /\<\!\-\- DB\=(\S+)\s+/) {
    $database = $1;
    $IPI_DATABASE = 1 if($database =~ /IPI/);
    $DROSOPHILA_DATABASE = 1 if($database =~ /rosophila/);
}
if(! ($database eq '') && -f '/bin/cygpath' ) {

    if ($database =~ /\:/ ) {
	$database = `cygpath '$database'`;
	($database) = ($database =~ /(\S+)/);
    }

}


die "could not find database\n" if($database eq '');
$ANNOTATION = 0 if(! -e $database);

my @parsed;

my $count = 0;
my $MAX = 500;

my $degenfile = 'PeptideProphet' . $USE_ALT_DEGEN_SUF;
my $default_enz = 'tryptic';

if($DEGEN && $USE_ALT_DEGEN_ENC) {
    if($datafile =~ /\S/) {
	$degenfile = $datafile . $USE_ALT_DEGEN_SUF; 
    }

    getDegeneracies($datafile) if(! -e $degenfile);
    readDegens($degenfile) if(-e $degenfile);
}

open(DATA, $datafile);
$ENZYMES{$default_enz}++;

while(<DATA>) {
    chomp();

    my $line = $_;
    while($line =~ /(.*)\<.*?\>(.*)/) {
	$line = $1 . $2;
    }
    my $degen = ! $USE_ALT_DEGEN_ENC && /DEGEN\_PROT\_INFO/;

    if($line =~ /^(\S+)\s+.*?\s+(\S+)\.(\d)\s+\S+\s+\((\S+)\)\s+(\S+)\s+(\S+)\s+\S+\s+(\d+)\s+.*\s+(\S+)\s+\+\d+\s+([A-Z,\#,\-,\@,\*]\.[A-Z,\#,\@,\*,\-,\+]+\.[A-Z,\#,\-,\@,\*])\s?/) {  # degen case

	if($USE_ALT_DEGEN_ENC && exists $degen_info{$2 . '.' . $3}) {
	    $degen = $degen_info{$2 . '.' . $3};
	}
	enter($PREFIX . $2 . '.' . $3, -1, $1, $9, $8, $degen, -1) if($MALDI);
	enter($PREFIX . $2, $3-2, $1, $9, $8, $degen, -1) if(! $MALDI);
    }
    elsif($line =~ /^(\S+)\s+.*?\s+(\S+)\.(\d)\s+\S+\s+\((\S+)\)\s+(\S+)\s+(\S+)\s+\S+\s+(\d+)\s+.*\s+(\S+)\s+([A-Z,\#,\-,\@,\*]\.[A-Z,\#,\@,\*,\-,\+]+\.[A-Z,\#,\-,\@,\*])\s?/) {
	if($USE_ALT_DEGEN_ENC && exists $degen_info{$2 . '.' . $3}) {
	    $degen = $degen_info{$2 . '.' . $3};
	}
	enter($PREFIX . $2 . '.' . $3, -1, $1, $9, $8, $degen, -1) if($MALDI);
	enter($PREFIX . $2, $3-2, $1, $9, $8, $degen, -1) if(! $MALDI);
    }

}
close(DATA);

print STDERR " read in ", $singly_datanum-$singly_previous, " 1+, ", $datanum[0]-$previous[0], " 2+, and ", $datanum[1]-$previous[1], " 3+ spectra with min prob $MIN_DATA_PROB"; 
print STDERR " (maldi mode)" if($MALDI);
print STDERR "\n";
STDOUT->autoflush(1);

print OUTFILE "read in ", $singly_datanum-$singly_previous, " 1+, ", $datanum[0]-$previous[0], " 2+, and ", $datanum[1]-$previous[1], " 3+ spectra with min prob $MIN_DATA_PROB\n"; 
if($singly_datanum - $singly_previous + $datanum[0] - $previous[0] + $datanum[1] - $previous[1] == 0) {
    print STDERR " no analysis possible for $datafile, aborting analysis\n";
    exit(1);
}

}


sub enter {
(my $spectrum, my $charge,  my $prob, my $pep, my $prot, my $degen, my $ntt) = @_;
#return if(! $ACCEPT_ALL && $charge < -1 || $charge > 1 || ($prob < $MIN_DATA_PROB && length(strip($pep)) > 7)); # bernd special
return if(! $ACCEPT_ALL && $charge < -1 || $charge > 1 || $prob < $MIN_DATA_PROB);
$prob *= $PROB_ADJUSTMENT;
# strip off charge
push(@spectra, $spectrum) if($charge >= 0 && ! enterData($spectrum, $charge, $prob, $pep, $prot, $degen, $ntt));
push(@singly_spectra, $spectrum) if($charge == -1 && ! enterData($spectrum, $charge, $prob, $pep, $prot, $degen, $ntt));

}

# returns whether already seen
sub enterData {
(my $spectrum, my $charge, my $prob,  my $pep, my $prot, my $degen, my $ntterm) = @_;

$prob = 1.0 if($ACCEPT_ALL); # want to use equally all input peptides, regardless of prob

my $unique = ! $degen;

# chop off first './' of spectrum, if exists
if($spectrum =~ /^\.\/(\S+)/) {
    $spectrum = $1;
}

my $VERBOSE = 0; #$pep =~ /NSSM\*DLHLQQW/; #0; #$spectrum =~ /test4\.1639\.1639/;

my $DEG_XTN = '_DEGEN*';
if($charge == -1) {
    $singly_datanum++;
}
else {
    $datanum[$charge]++;
}
my $output;

my $peptide = $pep;

my $ntt = $ntterm >= 0 ? $ntterm : numTrypticEnds($peptide);

my $prev;
my $next;
my @probs;

if($peptide =~ /(\S)\.(\S+)\.(\S)/) {
    $prev = $1;
    $peptide = $2;
    $peptide = ($charge+2) . '_' . $peptide if($UNIQUE_2_3);


    $next = $3;
}
else {
    $peptide = ($charge+2) . '_' . $peptide if($UNIQUE_2_3);
}

$peptide = equivalentPeptide(\%substitution_aas, \%equivalent_peps, $peptide);
if($VERBOSE) { # && $peptide eq '2_NSSM*DLHLQQW') {
    print STDERR "$spectrum $charge $prob $pep $prot\n";
}

print STDERR "$spectrum $charge $prob $pep $prot $unique\n" if($VERBOSE || $peptide eq $STD);

if($unique) {
    $unique{$peptide} = 1 if(! exists $unique{$peptide}); # it is unique

    if(exists $pep_prob_ind{$peptide}) {
	    ${$pep_prob_ind{$peptide}}{$prot} = 0;
            ${$pep_wts{$peptide}}{$prot} = 1;
	    ${$pep_prob_ind{$peptide}}{$prot} = $ntt;
     }
     else {
	      my %next3 = ($prot => 0);
	      $pep_prob_ind{$peptide} = \%next3;
              my %next4 = ($prot => 1);
              $pep_wts{$peptide} = \%next4;
	      my %next5 = ($prot => $ntt);
	      $pep_prob_ind{$peptide} = \%next5;
     }
    if(exists $prot_peps{$prot}) {
             ${$prot_peps{$prot}}{$peptide}++;
     }
    else {
             my %next = ($peptide => 1);
             $prot_peps{$prot} = \%next;
    }
    # make only as long as nec
    @probs = ();
    for(my $k = 0; $k < $ntt; $k++) {
	$probs[$k] = $NODATA;
    }
    $probs[$ntt] = $prob;

    print STDERR "ntt $ntt, reported probs: ", join(' ', @probs), "\n" if($VERBOSE);

} # if peptide has flanking aa info
else { # degen case
    $unique{$peptide} = 0;

    my $degen_info = $_;
    $degen_info = $degen if($USE_ALT_DEGEN_ENC);

    if($degen_info =~ /DEGEN\_PROT\_INFO\:\s+(\S+)\s(\S+)\s(\S+)\s(\S+)\s+(\S+.*?\S)\s+\-\-\>/) {

	my $protein;
	$peptide = $1;
	$peptide = ($charge+2) . '_' . $peptide if($UNIQUE_2_3);
        $peptide = equivalentPeptide(\%substitution_aas, \%equivalent_peps, $peptide);
	print "addding $peptide to protein $prot\n" if($VERBOSE);
  
        @probs = ($2*$PROB_ADJUSTMENT,$3*$PROB_ADJUSTMENT, $4*$PROB_ADJUSTMENT);
        my @degentries = split(' ', $5);
        die "problem with $_\n" if(@degentries%2 != 0);
        for(my $k = 0; $k < @degentries; $k += 2) {
	    my $VERBOSE = 0; #$degentries[$k] eq 'Chr_ORF0931'; #GP:AK022634_1'; #Chr_ORF1435'; #Q0050'; #'SW:ANX2_HUMAN'; #SWN:TBBQ_HUMAN';
	    $protein = $degentries[$k];

	    if(exists $pep_prob_ind{$peptide}) {
	         ${$pep_prob_ind{$peptide}}{$protein} = $degentries[$k+1]; 
                 ${$pep_wts{$peptide}}{$protein} = 2 / scalar @degentries;
                 ${$pep_wts{$peptide}}{$protein} = ${$pep_wts{$peptide}}{$protein}**$WT_POWER;
             }
             else {
	         my %next3 = ($protein => $degentries[$k+1]); 
	         $pep_prob_ind{$peptide} = \%next3;
		 my %next4 = ($protein => (2 / scalar @degentries)**$WT_POWER);
                 $pep_wts{$peptide} = \%next4;
	    }
            if(exists $prot_peps{$protein}) {
		${$prot_peps{$protein}}{$peptide}++;
            }
            else {
                my %next = ($peptide => 1);
                $prot_peps{$protein} = \%next;
	    }
	    if($VERBOSE) {
		print "here in degen group with protein $degentries[$k].and peptide $peptide..\n";
		foreach(sort keys %{$prot_peps{$protein}}) { print "$_ "; }
		print "\n";
	    }

	    if($VERBOSE && $degentries[$k+1] eq 'SWN:TBBQ_HUMAN') {
		print STDERR "$spectrum $charge $prob $pep $prot $unique\n";
		print "added to protpeps for $degentries[$k+1]: ";
		foreach(sort keys %{$prot_peps{$protein}}) { print "$_ "; } 
		print "\n";
	    }

	} # next deg entry
    } # if read deg info
    else { die "could not find DEGEN_PROT_INFO in $_\n"; }

} # degen case

if($peptide eq $STD) {
    my @peps2 = sort keys %{$prot_peps{$prot}};
    for(my $z = 0; $z < @peps2; $z++) { print STDERR "$peps2[$z] "; } print STDERR "\n";
}

if($charge >= 0) {
    if(exists $specpeps{$spectrum}) {
	$output = 1;
	${$specpeps{$spectrum}}[$charge] = $peptide;
	${$specprobs{$spectrum}}[$charge] = \@probs;
    }
    else { # make new entry for spectrum
	$output = 0;
	my @next1 = ($NODATA, $NODATA);
	my @next2 = ($NODATA, $NODATA);

	$specpeps{$spectrum} = \@next1;
	${$specpeps{$spectrum}}[$charge] = $peptide;

        $specprobs{$spectrum} = \@next2;
        ${$specprobs{$spectrum}}[$charge] = \@probs;
    }
}
else { # singlys

    if($charge == -1) {
	if(exists $singly_specpeps{$spectrum}) {
	    #die "already seen $spectrum with $charge ", $charge+2, "\n";
	}
	$output = 0;
	$singly_specpeps{$spectrum} = $peptide;
	$singly_specprobs{$spectrum} = \@probs;
    }
}





if($VERBOSE) {
    print STDERR "FINAL: $spectrum: ($charge) ", join(' ', ${${$specprobs{$spectrum}}[$charge]}[1]), "\n";
}
return $output;
}


sub setInitialWts {
# in proportion to total numbers of peptides corresponding to each of its corresponding proteins

    my $alt = 1; # do it by probability instead of cardinality
    my $UNIQUE_FACTOR = 5; # how many time more to weight unique peptides

    foreach(sort keys %pep_wts) {
	my $tot_peps = 0;
	my $verbose = 0;
        print STDERR "$_ " if($verbose);
	my @prots = sort keys %{$pep_wts{$_}};
        my @uniques = ();
	for(my $p = 0; $p < @prots; $p++) {
            $uniques[$p] = numUniquePeps($prots[$p]);
	    $tot_peps += weightedPeptideProbs($prots[$p], $UNIQUE_FACTOR) if($UNIQUE_FACTOR);
	    printf STDERR "adding %d for $prots[$p]...\n",  scalar keys %{$prot_peps{$prots[$p]}} if($verbose);
	}
	if($tot_peps > 0) {
	    for(my $p = 0; $p < @prots; $p++) {
		if($OCCAM) {
		    ${$pep_wts{$_}}{$prots[$p]} = weightedPeptideProbs($prots[$p], $UNIQUE_FACTOR) / $tot_peps if($UNIQUE_FACTOR);
                }
                else {
		    ${$pep_wts{$_}}{$prots[$p]} =  1;
                }
	        if(exists $orig_pep_wts{$_}) {
		    ${$orig_pep_wts{$_}}{$prots[$p]} = ${$pep_wts{$_}}{$prots[$p]};
                }
                else {
	            my %next = ($prots[$p] => ${$pep_wts{$_}}{$prots[$p]});
                    $orig_pep_wts{$_} = \%next;
                }
	        printf STDERR "pep wt for $_ -> $prots[$p]: %0.2f\n", ${$pep_wts{$_}}{$prots[$p]} if($verbose);
	    }
        }

    } # next peptide

}

sub computeProteinProb {
(my $prot) = @_;
my @peps = sort keys %{$prot_peps{$prot}};

my $VERBOSE2 = 0;
my $VERBOSE = 0;
my $prob = 1;
for(my $k = 0; $k < @peps; $k++) {

    $VERBOSE = $VERBOSE2; # && $peps[$k] eq '2_K.NLVSMLTYTYDPVEK.Q');
    # can go through all other prots that this pep corresponds to, and multiply weight by (1-w') for each
    my $factor = 1;

    if($VERBOSE) {
	print STDERR "min wt: $MIN_WT, min prob: $MIN_PROB\n";
    }
    if(! $STY_MOD || ! isSTYMod($peps[$k])) {

	$prob *= (1 - ${$pep_max_probs{$peps[$k]}}{$prot} * ${$pep_wts{$peps[$k]}}{$prot} * $factor) if
                                (${$pep_wts{$peps[$k]}}{$prot} >= $MIN_WT && 
                                 ${$pep_max_probs{$peps[$k]}}{$prot} >= $MIN_PROB);
    }

print STDERR "prob: $prob\n" if($VERBOSE);

} # next pep
printf STDERR "returning %0.3f for $prot\n", 1-$prob if($VERBOSE); 
return (1-$prob);
}

sub updateProteinProbs {
    print STDERR " updateProteinProbs....\n" if($DEBUG);
    my $changed = 0;
    my $nextprob;
    my $MAX_DIFF = 0.05;
    my $verbose = 0;
    foreach(sort keys %prot_peps) {
	$nextprob = computeProteinProb($_);
	if (! exists $protein_probs{$_} || abs($nextprob - $protein_probs{$_}) > $MAX_DIFF) {
		if($verbose) {
	    printf "updating prot probs for $_: from %0.2f to %0.2f\n", $protein_probs{$_}, $nextprob;
	}
		$protein_probs{$_} = $nextprob; # BSP: formerly once one got changed, they all got changed whether they thresholded or not
		$changed = 1;
	}
    }
    print "-------------------------------------------------\n\n" if($verbose);
    return $changed;
}

sub numProteins {
(my $min_prot_prob, my $include_groups) = @_;
    my $tot = 0;
    my $group_tot = 0;
    foreach(sort keys %protein_probs) {
	$tot += $protein_probs{$_} if((! $include_groups || ! exists $group_members{$_}) &&
				      $protein_probs{$_} >= $min_prot_prob);
    }
    if($include_groups) {
        foreach(@grp_indeces) {
	    $group_tot += $group_probs{$_} if($group_probs{$_} >= $min_prot_prob);
	}
    }
    return ($tot, $tot + $group_tot);
}

sub sens_err {
(my $min_prot_prob, my $include_groups) = @_;
my $tot_correct = 0;
my $tot_incorr = 0;
foreach(sort keys %protein_probs) {
    $tot_correct += $protein_probs{$_} if((! $include_groups || ! exists $group_members{$_}) &&
					  $protein_probs{$_} >= $min_prot_prob);
    $tot_incorr += 1 - $protein_probs{$_} if((! $include_groups || ! exists $group_members{$_}) &&
                                             $protein_probs{$_} >= $min_prot_prob);
}
if($include_groups) {
    for(my $k = 0; $k < @grp_indeces; $k++) {
	if($group_probs{$grp_indeces[$k]} >= $min_prot_prob) {
	    $tot_correct += $group_probs{$grp_indeces[$k]};
	    $tot_incorr += 1 - $group_probs{$grp_indeces[$k]};
	}
	else {
	    $k = @grp_indeces;
	}
    }
}

return ($tot_correct, $tot_incorr);
}

sub rank_protein_probs { # a helper for sorting at output resolution
    (my $number) = @_;
	my $fmt = sprintf("%0.2f",$number);
    return $fmt;
}

sub writeErrorAndSens {
(my $outfile, my $min_probptr, my $include_groups) = @_;

if ($PLOT_PNG) {
	unlink($outfile) if(-e $outfile);
	open(OUT, ">$outfile");
}

my @next = sens_err(0, $include_groups);
my $tot;
my $total = $next[0];
print OUT "#thresh\tcorr\tincorr\tsens\terr\n" if $PLOT_PNG;
%sens = ();
%err = ();
foreach(@{$min_probptr}) {
    @next = sens_err($_, $include_groups);
    $tot = $next[0] + $next[1];
    $sens{$_} = $total > 0 ? $next[0]/$total : 1;
    $err{$_} = $tot > 0 ? $next[1]/$tot : 0;
    if ($PLOT_PNG) {
		printf OUT "%0.3f\t%0.1f\t%0.1f\t%0.3f\t%0.3f\n", $_, $next[0], $next[1], $next[0]/$total, $next[1]/$tot if($tot > 0 && $total > 0);
		printf OUT "%0.3f\t%0.1f\t%0.1f\t%0.3f\t%0.3f\n", $_, 0, 0, 0 if($tot == 0 || $total == 0);
	}
}
close(OUT) if $PLOT_PNG;
}

sub writeScript {
(my $datafile, my $scriptfile, my $outfile, my $num) = @_;
unlink($scriptfile) if(-e $scriptfile);
open(OUT, ">$scriptfile");
print OUT "set terminal png;\n";
print OUT "set output \"$outfile\";\n";
print OUT "set border;\n";
printf OUT "set title \"Estimated Sensitivity (fraction of %0.1f total) and Error Rates\";\n", $num;
print OUT "set xlabel \"Min Protein Prob\";\n";
print OUT "set ylabel \"Sensitivity or Error\";\n";
print OUT "set xtics (\"0\" 0, \"0.2\" 0.2, \"0.4\" 0.4, \"0.6\" 0.6, \"0.8\" 0.8, \"1\" 1.0);\n";
print OUT "set grid;\n";
print OUT "set size 0.75,0.8;\n";
print OUT "plot \"$datafile\" using 1:4 title 'sensitivity' with lines, \\\n";
print OUT " \"$datafile\" using 1:5 title 'error' with lines\n";
close(OUT);
unlink($outfile) if(-e $outfile);
my $resul = system("gnuplot $scriptfile");  # make outfile...
unlink($scriptfile) if(-e $scriptfile);
unlink($datafile) if(-e $datafile && ! $ACCURACY_MODE);
print STDERR "png file $imagefile not written...\n" if(! -e $imagefile );
}

sub printProteinProbs {
(my $min_prot_prob, my $min_pep_prob) = @_;
my $index = 1;
my @peps;
my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2


print OUTFILE "\nusing ";
print OUTFILE "OCCAM edge wts and " if($OCCAM);
print OUTFILE "no OCCAM's 'min prot list' razor and " if(! $OCCAM);
print OUTFILE "degen groups protocol \#3 with minwt $DEGEN3_MINWT and minprob $DEGEN3_MINPROB\n";
print OUTFILE "equivalent aa's: ";
my @formers = sort keys %substitution_aas;
for(my $k = 0; $k < @formers; $k++) {
    print OUTFILE "$formers[$k] -> $substitution_aas{$formers[$k]}";
    print OUTFILE ", " if($k < @formers - 1);
}
print OUTFILE "\n";
print OUTFILE "enzyme: ", join(',', sort keys %ENZYMES); #$ENZYME";
print OUTFILE "\n\n";

# HTML font colors
my $prot_prob_color = 'FF0000'; # red
my $asterisk_color = '990000'; # brown 
my $pep_prob_color = 'FF7400"'; #
my $annot_color = '007800'; # green
my $match_color = 'DD00DD'; # pink
print OUTFILE "<TABLE><TR><TD>";
my $local_imagefile = $imagefile;

if($WINDOWS_CYGWIN) {
    if((length $SERVER_ROOT) <= (length $local_imagefile) && 
       index((lc $local_imagefile), (lc $SERVER_ROOT)) == 0) {
	$local_imagefile = '/' . substr($local_imagefile, (length $SERVER_ROOT));
    }
    else {
	die "problem: $local_imagefile is not mounted under webserver root: $SERVER_ROOT\n";
    }
}


print OUTFILE "<IMG SRC=\"$local_imagefile\">";
print OUTFILE "</TD><TD><PRE>";

print OUTFILE "<font color=\"red\">sensitivity</font>\tfraction of all correct proteins\n\t\twith probs &gt;= min_prob\n\n";
print OUTFILE "<font color=\"green\">error</font>\t\tfraction of all proteins with\n\t\tprobs &gt;= min_prob that are incorrect\n";
print OUTFILE "\n\n";
print OUTFILE "    min_prob <font color=\"red\">sens     </font><font color=\"green\">err      </font>\t<font color=\"red\"># corr</font>\t<font color =\"green\"># incorr</font>\n\n";
foreach(reverse sort keys %sens) {
    printf OUTFILE "    %0.2f     <font color=\"red\">%0.3f    </font><font color=\"green\">%0.3f\t</font><font color=\"red\">%0.0f</font>\t<font color=\"green\">%0.0f</font><br>", $_, $sens{$_}, $err{$_}, $sens{$_} * $num_prots, $sens{$_} * $num_prots * $err{$_} / (1.0 - $err{$_}) if($err{$_} < 1.0);
}
print OUTFILE "</TD></TR></TABLE>";
print OUTFILE "\n\n";


my @num_prots = numProteins($min_prot_prob, 0);
my @num_prots_grp = numProteins($min_prot_prob, 1);

printf OUTFILE "Total Number of Proteins Identified (with prob at least $min_prot_prob): %0.1f (%0.1f w/o groups)\n\n", $num_prots_grp[1], $num_prots[1];
print OUTFILE "\n";
my $TAB_DELIM_OUTPUT = 1; # form to write output to tab delimited format

if($TAB_DELIM_OUTPUT) {

    print OUTFILE "<font color=\"green\"><b>  NOW YOU CAN REVISE THIS HTML, EXCLUDING ENTRIES BY INDEX NUMBER OR PROBABILITY.</b></font>\n";
    print OUTFILE "<table><tr><td>\n";
    print OUTFILE "</td><td>";
    print OUTFILE "<table border=3><tr><td>\n";
    print OUTFILE "<form method=\"GET\" target=\"Win1\" action=\"" . $CGI_HOME . "reviseHTML.pl\">\n";
    print OUTFILE "<pre>    <font color=\"blue\">           <input type=\"submit\", value=\"revise html\"></font>";
    print OUTFILE "\n\n exclude entries (example: 5,10-12): <INPUT TYPE=\"text\" NAME=\"excludes\" VALUE=\"\" SIZE=\"10\" MAXLENGTH=\"200\">   ";
    print OUTFILE "\n\n minimum protein prob: <INPUT TYPE=\"text\" NAME=\"min_prob\" VALUE=\"0.0\" SIZE=\"4\" MAXLENGTH=\"15\">";
    print OUTFILE "<input type=\"hidden\", name=\"html_file\", value=\"$OUTFILE\">\n";
    print OUTFILE "</pre></form>\n";
    print OUTFILE "</td></tr></table>\n";

    print OUTFILE "</td><td>";
    print OUTFILE "<table border=3><tr><td>\n";
    print OUTFILE "<form method=\"GET\" target=\"Win1\" action=\"" . $CGI_HOME . "restoreOriginalHTML.pl\">\n";
    print OUTFILE "<pre>    <font color=\"blue\"><input type=\"submit\", value=\"restore original html\">    </font>";
    print OUTFILE "<input type=\"hidden\", name=\"html_file\", value=\"$OUTFILE\">\n";
    print OUTFILE "</pre></form>\n";
    print OUTFILE "</td></tr></table>\n";

    print OUTFILE "</td></tr></table>\n";
} # if
print OUTFILE "\n";
print OUTFILE "<FONT COLOR=\"$asterisk_color\">";
print OUTFILE "* indicates peptide corresponding to unique protein entry\n\n";
print OUTFILE "</FONT>";
my $MAX_PEPLENGTH = 45;
my $max_peplength = maxPeptideLength();
$max_peplength = $MAX_PEPLENGTH if($max_peplength > $MAX_PEPLENGTH);
my $init = 1;
my $grp_counter = 0;
foreach(reverse sort { $protein_probs{$a} <=> $protein_probs{$b} } keys %protein_probs) {

    while($grp_counter < @grp_indeces && $group_probs{$grp_indeces[$grp_counter]} > $protein_probs{$_}) {
	printGroup($grp_indeces[$grp_counter],$max_peplength, $min_pep_prob, $index, $prot_prob_color); 
	$grp_counter++;
	$index++;
    }

    printProteinInfo($_, $index++, $max_peplength, $min_pep_prob, 0, 0, 0) 
	if($protein_probs{$_} >= $min_prot_prob && ! exists $group_members{$_});

} # next prot entry
# any stragglers????
while($grp_counter < @grp_indeces) {
    printGroup($grp_indeces[$grp_counter],$max_peplength, $min_pep_prob, $index, $prot_prob_color); 
    $grp_counter++;
    $index++;
}

}

sub setWritePermissions {
(my $file) = @_;
return; 
my $directory = './'; # default
if($file =~ /^(\S*\/)\S+$/) {
    $directory = $1;
}
system("chmod ug+w $directory");
}

sub getBofFile {
(my $xmlfile) = @_;
if($xmlfile =~ /^(\S+)interact\-(\S+)\-prot\.xml$/) {
    return $1 . 'ASAPRatio_' . $2 . '_peptide.bof';
}
elsif($xmlfile =~ /^(\S+)interact\-prot\.xml$/) {
    return $1 . 'ASAPRatio_peptide.bof';
}

return 'ASAPRatio_peptide.bof';
}

sub writeXMLOutput {
(my $min_prot_prob, my $min_pep_prob, my $xmlfile) = @_;
print XML '<?xml version="1.0" encoding="UTF-8"?>', "\n";

if($xmlfile =~ /^(\S+\.x)ml$/) {
     my $local_xslfile = $1 . 'sl';
     if( $WINDOWS_CYGWIN) {
	 if((length $SERVER_ROOT) <= (length $local_xslfile) && 
	    index((lc $local_xslfile), (lc $SERVER_ROOT)) == 0) {
	     $local_xslfile = substr($local_xslfile, (length $SERVER_ROOT));
	     
	     if (exists($ENV{'WEBSERVER_URL'})) {
		my $url = $ENV{'WEBSERVER_URL'};
		$url .= '/' if($url !~ /\/$/);
		$local_xslfile = $url . $local_xslfile ;
	    }
	    else {
		$local_xslfile = "http://localhost/" . $local_xslfile ;
	    }
	     
	 }
	 else {
	     die "problem: $local_xslfile is not mounted under webserver root: $SERVER_ROOT\n";
	 }
     } # if iis & cygwin



     print XML '<?xml-stylesheet type="text/xsl" href="' . $local_xslfile . '"?>', "\n";
 }

#my $localtime = localtime;

print XML '<protein_summary xmlns="http://regis-web.systemsbiology.net/protXML" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://regis-web.systemsbiology.net/protXML ' . $PROTXML_SCHEMA . '" summary_xml="' . $XMLFILE . '">', "\n";

my $index = 1;
my @peps;
my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2


print XML '<protein_summary_header reference_database="';
if($WINDOWS_CYGWIN) {
    # here use convential windows name of database
    my $local_database = `cygpath -u '$database'`;
    chomp($local_database);
    print XML $local_database;
    $local_database = `cygpath -w '$database'`;
    if($local_database =~ /^(\S+)\s?/) {
	$local_database = $1;
    }

    # check for error

     print XML '" win-cyg_reference_database="', $local_database if(! ($local_database eq '') && $local_database =~ /^\S\:/); 
} # if iis & cygwin
else {
    print XML $database;
}
print XML '" residue_substitution_list="';
my @formers = sort keys %substitution_aas;
for(my $k = 0; $k < @formers; $k++) {
    print XML "$formers[$k] -> $substitution_aas{$formers[$k]}";
    print XML ", " if($k < @formers - 1);
}
if($IPI_DATABASE) {
    if($database =~ /ipi\.HUMAN\..*\.fasta/) {
	print XML '" organism="Homo_sapiens';
    }
    elsif($database =~ /ipi\.MOUSE\..*\.fasta/) {
	print XML '" organism="Mus_musculus';
    }
    elsif($database =~ /ipi\.RAT\..*\.fasta/) {
	print XML '" organism="Rattus_norvegicus';
    }
    elsif($database =~ /hiv\_hcv/) {
	print XML '" organism="Homo_sapiens';
    }
}
elsif($DROSOPHILA_DATABASE) {
    print XML '" organism="Drosophila';
}

print XML '" source_files="', $source_files; 
print XML '" source_files_alt="', $source_files_alt; 

if($WINDOWS_CYGWIN) {

    my @windows_files = split(' ', $source_files);
    for(my $k = 0; $k < @windows_files; $k++) {
	$windows_files[$k] = `cygpath -w '$windows_files[$k]'`;
	if($windows_files[$k] =~ /^(\S+)\s?/) {
	    $windows_files[$k] = $1;
	}
    } # next input file
    print XML '" win-cyg_source_files="', join(' ', @windows_files); 
} # if iis & cygwin


if($ASAP_FILE =~ /interact\-(\S+)\-data\.htm$/) {
    print XML '" source_file_xtn="', $1; 
}

print XML '" min_peptide_probability="';
printf XML "%0.2f", $FINAL_PROB_MIN_PROB;
print XML '" min_peptide_weight="';
printf XML "%0.2f\"", $FINAL_PROB_MIN_WT;
printf XML " num_predicted_correct_prots=\"%0.1f\"", $num_prots;
printf XML " num_input_1_spectra=\"%d\"", $singly_datanum;
printf XML " num_input_2_spectra=\"%d\"", $datanum[0];
printf XML " num_input_3_spectra=\"%d\"", $datanum[1];
printf XML " initial_min_peptide_prob=\"%0.2f\"", $INIT_MIN_DATA_PROB; 
printf XML " total_no_spectrum_ids=\"%0.1f", $total_spectrum_counts if($COMPUTE_TOTAL_SPECTRUM_COUNTS);
print XML '" sample_enzyme="', join(',', sort keys %ENZYMES);
print XML '">', "\n";


print XML '<program_details analysis="proteinprophet" time="' . getDateTime() . '" version="' . $PROGRAM_VERSION . '(' . $TPPVersionInfo .')">', "\n";;
print XML '<proteinprophet_details ';
print XML ' occam_flag="', Bool2Alpha($OCCAM);
print XML '" groups_flag="', Bool2Alpha($USE_GROUPS);
print XML '" degen_flag="', Bool2Alpha($DEGEN);
print XML '" nsp_flag="', Bool2Alpha($USE_NSP);
printf XML "\" initial_peptide_wt_iters=\"%d\"", $first_iters;
printf XML " nsp_distribution_iters=\"%d\"", $fourth_iters;
printf XML " final_peptide_wt_iters=\"%d\"", $final_iters;
printf XML " run_options=\"%s\"", $options if(! ($options eq ''));
print XML '>', "\n";


# nsp information
spaceXML(2);
print XML '<nsp_information neighboring_bin_smoothing="', Bool2Alpha($SMOOTH), '">', "\n";
my $start;
for(my $k = 0; $k < @pos_shared_prot_distrs; $k++) {
    if($k == 0) {
	$start = 0;
    }
    else {
	$start = $shared_prot_prob_threshes[$k-1];
    }
    spaceXML(3);
    print XML '<nsp_distribution bin_no="', $k, '" nsp_lower_bound_incl="';
    printf XML "%0.2f", $start;
    print XML '" nsp_upper_bound_excl="';
    if($k < @pos_shared_prot_distrs - 1) {
	printf XML "%0.2f", $shared_prot_prob_threshes[$k];
    }
    else {
	printf XML "inf";
    }
    print XML '" pos_freq="';
    printf XML "%0.3f", $pos_shared_prot_distrs[$k];
    print XML '" neg_freq="';
    printf XML "%0.3f", $neg_shared_prot_distrs[$k];
    print XML '" pos_to_neg_ratio="';
    if($neg_shared_prot_distrs[$k] >0.0) {
	printf XML "%0.2f", $pos_shared_prot_distrs[$k]/$neg_shared_prot_distrs[$k];
    }
    else {
	printf XML "%0.2f", 9999;
    }
    if($NSP_BIN_EQUIVS[$k] != $k) {
	print XML '" alt_pos_to_neg_ratio="';
	printf XML "%0.2f", $pos_shared_prot_distrs[$NSP_BIN_EQUIVS[$k]]/$neg_shared_prot_distrs[$NSP_BIN_EQUIVS[$k]];
	
    }
    print XML '"/>', "\n";
} # next nsp bin

spaceXML(2);
print XML '</nsp_information>';


# sens and error info
foreach(sort keys %sens) {
    spaceXML(2);
    printf XML "<protein_summary_data_filter min_probability=\"%0.2f\" sensitivity=\"%0.3f\" false_positive_error_rate=\"%0.3f\" predicted_num_correct=\"%0.0f\" predicted_num_incorrect=\"%0.0f\" />\n", $_, $sens{$_}, $err{$_}, $sens{$_} * $num_prots, $err{$_} < 1.0 ? $sens{$_} * $num_prots * $err{$_} / (1.0 - $err{$_}) : $num_prots;
}

print XML '</proteinprophet_details>', "\n", '</program_details>', "\n";

print XML '</protein_summary_header>', "\n";

print XML '<dataset_derivation generation_no="0">', "\n", '</dataset_derivation>', "\n";

my $MAX_PEPLENGTH = 45;
my $max_peplength = maxPeptideLength();
$max_peplength = $MAX_PEPLENGTH if($max_peplength > $MAX_PEPLENGTH);
my $init = 1;
my $grp_counter = 0;

foreach(reverse sort { rank_protein_probs($protein_probs{$a}) <=> rank_protein_probs($protein_probs{$b}) || $b cmp $a } keys %protein_probs) { # sort at output accuracy
    while($grp_counter < @grp_indeces && $group_probs{$grp_indeces[$grp_counter]} > $protein_probs{$_} && $group_probs{$grp_indeces[$grp_counter]} >= $min_prot_prob) {
	writeGroupXML($grp_indeces[$grp_counter], $min_pep_prob, $index); 
	$grp_counter++;
	$index++;
    }

    if($protein_probs{$_} >= $min_prot_prob && ! exists $group_members{$_}) {
	
	print XML '<protein_group group_number="', $index;
	print XML '" probability="', $protein_probs{$_}, '">', "\n";
	writeProteinXML($_, $index++, $min_pep_prob, 'a');
	print XML '</protein_group>', "\n";
    }

} # next prot entry
# any stragglers????
while($grp_counter < @grp_indeces) {
    writeGroupXML($grp_indeces[$grp_counter],$min_pep_prob, $index); 
    $grp_counter++;
    $index++;
}

print XML '</protein_summary>', "\n";

}

sub writeExcelOutput {
(my $min_prot_prob, my $min_pep_prob, my $excelfile) = @_;
   open(EXCEL, ">$excelfile") or die "cannot open EXCEL $excelfile $!\n";
   # write header info
   print EXCEL "entry no.\tgroup probability\tprotein\tprotein probability\tpercent coverage\t";
   if($ASAP) {
       print EXCEL "ratio mean\tratio stdev\tratio num peptides\t";
   }
   print EXCEL "num unique peps\ttot num peps\t";
   print EXCEL "ipi\t" if($IPI_DATABASE);
   print EXCEL "description\t";
   print EXCEL "ensembl\ttrembl\tswissprot\trefseq\t"   if($IPI_DATABASE);
   print EXCEL "weight\tprecursor ion charge\tpeptide sequence\tnsp adjusted probability\tinitial probability\tnumber tolerable termini\testimated num sibling peptides\tnum instances\tpeptide group designator\tunique\tis contributing evidence" if($EXCEL_PEPTIDES);
   print EXCEL "\n";


my $index = 1;
my @peps;
my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2

if($ASAP) {
    $ASAP_IND = 0; # reset counter
    if($PRINT_HTML) {
	$ASAP_REFRESH = 1; # no need to compute from scratch when writing the XML
    }
}

my $MAX_PEPLENGTH = 45;
my $max_peplength = maxPeptideLength();
$max_peplength = $MAX_PEPLENGTH if($max_peplength > $MAX_PEPLENGTH);
my $init = 1;
my $grp_counter = 0;
foreach(reverse sort { $protein_probs{$a} <=> $protein_probs{$b} } keys %protein_probs) {

    while($grp_counter < @grp_indeces && $group_probs{$grp_indeces[$grp_counter]} > $protein_probs{$_} && $group_probs{$grp_indeces[$grp_counter]} >= $min_prot_prob) {
	writeGroupExcel($grp_indeces[$grp_counter], $min_pep_prob, $index); 
	$grp_counter++;
	$index++;
    }

    if($protein_probs{$_} >= $min_prot_prob && ! exists $group_members{$_}) {
	writeProteinExcel($protein_probs{$_}, $_, $index++, $min_pep_prob, 'a');
    }

} # next prot entry
# any stragglers????
while($grp_counter < @grp_indeces) {
    writeGroupExcel($grp_indeces[$grp_counter],$min_pep_prob, $index); 
    $grp_counter++;
    $index++;
}

}


sub spaceXML {
(my $num) = @_;
my $mult = 3;
for(my $k = 0; $k < $num * $mult; $k++) {
    print XML ' ';
}
}

sub writeGroupXML {
(my $group_ind, my $min_pep_prob, my $index) = @_;
print XML '<protein_group group_number="', $index, '" pseudo_name="', $group_names{$group_ind}, '" probability="';
printf XML "%0.2f", $group_probs{$group_ind};
print XML '">', "\n";


my $id = 'a';
for(my $g = 0; $g < @{$groups[$group_ind]}; $g++) {
    writeProteinXML(${$groups[$group_ind]}[$g], $index . '-' . ($g+1), $min_pep_prob, $id++);
}
print XML '</protein_group>', "\n";
}

sub writeGroupExcel {
(my $group_ind, my $min_pep_prob, my $index) = @_;
return if($group_probs{$group_ind} < $EXCEL_MINPROB);

my $id = 'a';
for(my $g = 0; $g < @{$groups[$group_ind]}; $g++) {
    writeProteinExcel($group_probs{$group_ind}, ${$groups[$group_ind]}[$g], $index . '-' . ($g+1), $min_pep_prob, $id++);
}
}

sub getUniqueStrippedPeps {
(my $pepptr) = @_;
my %uniques = ();
foreach(@{$pepptr}) {
    if(exists $equivalent_peps{$_}) {
	my @actualpeps = sort keys %{$equivalent_peps{$_}};
	for(my $k = 0; $k < @actualpeps; $k++) {

	    $uniques{strip($actualpeps[$k])}++;
	}
    }
    else {
	$uniques{strip($_)}++;
    }
}
my @uniques = sort { $a cmp $b } keys %uniques;
my $output = '';
for(my $k = 0; $k < @uniques; $k++) {
    $output .= $uniques[$k];
    $output .= '+' if($k < @uniques - 1);
}
return $output;
}

sub getTotalNumPeps {
(my $entry, my $pepptr) = @_;
my $tot = 0;
foreach(@{$pepptr}) {
    $tot += numInstancesPeptide($_, $entry, 0, 0) if(${$pep_max_probs{$_}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$_}}{$entry} >= $FINAL_PROB_MIN_WT);
}
return $tot;
}

sub writeProteinXML {
(my $entry, my $index, my $min_pep_prob, my $prot_id) = @_;


my $PRINT_COVERAGE = 0;

my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2

my $grp_index = '';
my $verbose = $entry =~ /133916/;

if($index =~ /^(\d+)(\-\d+)$/) {
    $grp_index = $1;
    $index = $2;
}
else {
    $grp_index = 0 - $index if($index < 0);
    $index = '' if($index < 0);
}

my @peps = reverse sort { rank_protein_probs(${$pep_max_probs{$a}}{$entry}) <=> rank_protein_probs(${$pep_max_probs{$b}}{$entry}) || $b cmp $a} keys %{$prot_peps{$entry}}; # sort at output precision

return if(@peps == 0);

my $verbose = 0; #$entry =~ /YOR1\_YEAST/;

print STDERR "Num peps: ", scalar @peps, "\n" if($verbose);

spaceXML(2);	
print XML '<protein ';

my @entries = split(' ', $entry);
print XML 'protein_name="', $entries[0], '" n_indistinguishable_proteins="', scalar @entries, '" probability="';
printf XML "%0.2f", $protein_probs{$entry};
print XML '"';
if($PRINT_PROT_COVERAGE) {
   $coverage{$entry} = getCoverageForEntry($entry, $PRINT_PROT_COVERAGE); 
   if($coverage{$entry} != -1) {
       printf XML " percent_coverage=\"%0.1f\"", getCoverageForEntry($entry, $PRINT_PROT_COVERAGE);
   }
}
print XML ' unique_stripped_peptides="' . getUniqueStrippedPeps(\@peps) . '"'; 
print XML ' group_sibling_id="' . $prot_id . '"';
print XML ' total_number_peptides="', getTotalNumPeps($entry, \@peps), '"';
print XML ' subsuming_protein_entry="' . $subsumed{$entry} . '"' if(exists $subsumed{$entry});
if($COMPUTE_TOTAL_SPECTRUM_COUNTS && $total_spectrum_counts > 0 && $protein_probs{$entry} > 0.0) {
    my $tot_cnts = 0.0;
    for(my $pep = 0; $pep < @peps; $pep++) {
	$tot_cnts += $spectrum_counts{$peps[$pep]} * ${$pep_wts{$peps[$pep]}}{$entry} if(exists $spectrum_counts{$peps[$pep]});
    }
    if($total_spectrum_counts > 10000.0) { # add extra decimal place
	printf XML " pct_spectrum_ids=\"%0.3f\"", $tot_cnts * 100 / $total_spectrum_counts;
    }
    else {
	printf XML " pct_spectrum_ids=\"%0.2f\"", $tot_cnts * 100 / $total_spectrum_counts;
    }
}

my $NEW_ASAP = 1; # object for ASAP data
if($NEW_ASAP) {
    print XML ">\n";
}

if($ASAP) {
    my $result = getASAPRatio($ASAP_IND, $entry, \@peps);
    my $pro_index = '';
    if($result =~ /proIndx\=(\d+)/) {
	$pro_index = $1;
    }

    # now strip off html tags
    while($result =~ /(.*)\<.*?\>(.*)/) {
	$result = $1 . $2;
    }
    if($NEW_ASAP && $result =~ /ASAP\:\s+(\S+)\s+\+\-\s+(\S+)\s+\(\S+\)\s+(\d+)\s?$/) {
	spaceXML(3);	
	printf XML " <ASAPRatio ratio_mean=\"%0.2f\" ratio_standard_dev=\"%0.2f\" ratio_number_peptides=\"%d\"", $1, $2, $3;
	print XML ' index="' . $pro_index . '"';
	print XML '/>';
	spaceXML(3);	
    }
    elsif(! $NEW_ASAP) {
	print XML ' quantitation_ratio="', $result, '"';
    }
}
if(! $NEW_ASAP) {
    print XML '>';
}

my $VERBOSE = 0; #$entry =~ /AB028127/;

# annotation
if($ANNOTATION) { # && exists $annotation{$entries[0]}) {

    getAnnotation($entry, $database, -1);
    if($IPI_DATABASE) {
	spaceXML(3);
	my $next_annot = exists $annotation{$entries[0]}  
	                 && (length $annotation{$entries[0]}) > 0 ? $annotation{$entries[0]} : $entries[0];
	(my $prot_descr, my $ipi, my $refseq, my $swissprot, my $ensembl, my $trembl) = parseIPI($next_annot);
	print XML '<annotation protein_description="' . $prot_descr . '"';
	print XML ' ipi_name="' . $ipi . '"' if(! ($ipi eq ''));
	print XML ' refseq_name="' . $refseq . '"' if(! ($refseq eq ''));
	print XML ' swissprot_name="' . $swissprot . '"' if(! ($swissprot eq ''));
	print XML ' ensembl_name="' . $ensembl . '"' if(! ($ensembl eq ''));
	print XML ' trembl_name="' . $trembl . '"' if(! ($trembl eq ''));
	print XML '/>';
    }
    elsif($DROSOPHILA_DATABASE) {
	spaceXML(3);
	my $next_annot = exists $annotation{$entries[0]}  
	                 && (length $annotation{$entries[0]}) > 0 ? $annotation{$entries[0]} : $entries[0];
	my $flybase = getFlybaseInfo($next_annot);
	print XML '<annotation protein_description="' . $next_annot . '"';
	print XML ' flybase="' . $flybase . '"' if(! ($flybase eq ''));
	print XML '/>';
    }
    elsif(exists $annotation{$entries[0]} && (length $annotation{$entries[0]}) > 0) {
	spaceXML(3);
	my @description = split('\n', $annotation{$entries[0]});
	my $next_descr = join(' ', @description);
	# strip off first '>'
	if($next_descr =~ /^\&gt\;(.*)$/) {
	    $next_descr = $1;
	}
	print XML '<annotation protein_description="', $next_descr, '"/>';
    }
}
print XML "\n";

# indistinguishables
for(my $k = 1; $k < @entries; $k++) {
    spaceXML(3);
    print XML '<indistinguishable_protein protein_name="', $entries[$k], '">';
    if($ANNOTATION) { # && exists $annotation{$entries[$k]}) {
	if($IPI_DATABASE) {
	    print XML "\n";
	    spaceXML(4);
	    my $next_annot = exists $annotation{$entries[$k]} && 
		             (length $annotation{$entries[0]}) > 0 ? $annotation{$entries[$k]} : $entries[$k];
	    (my $prot_descr, my $ipi, my $refseq, my $swissprot, my $ensembl, my $trembl) = parseIPI($next_annot);
	    print XML '<annotation protein_description="' . $prot_descr . '"';
	    print XML ' ipi_name="' . $ipi . '"' if(! ($ipi eq ''));
	    print XML ' refseq_name="' . $refseq . '"' if(! ($refseq eq ''));
	    print XML ' swissprot_name="' . $swissprot . '"' if(! ($swissprot eq ''));
	    print XML ' ensembl_name="' . $ensembl . '"' if(! ($ensembl eq ''));
	    print XML ' trembl_name="' . $trembl . '"' if(! ($trembl eq ''));
	    print XML '/>';
	}
	elsif(exists $annotation{$entries[$k]} && (length $annotation{$entries[0]}) > 0) {
	    print XML "\n";
	    spaceXML(4);
	    my @description = split('\n', $annotation{$entries[$k]});
	    print XML "<annotation protein_description=\"", join(' ', @description), "\"/>";
	}
	spaceXML(3);
    }
    print XML "\n</indistinguishable_protein>\n";
}
my $indsptr = findCommonPeps(\@peps);


print "num peps: ", scalar @peps, " => ", join(',', @peps), "\n" if($VERBOSE);

for(my $pep = 0; $pep < @peps; $pep++) {
print STDERR "1. $peps[$pep] ${$pep_max_probs{$peps[$pep]}}{$entry} vs $min_pep_prob\n" if($verbose || $VERBOSE); 
if($verbose && ! exists ${$pep_max_probs{$peps[$pep]}}{$entry}) {
    print STDERR "no pep max probs\n";
}
elsif($verbose) {
    print STDERR "pepmaxprobs: ${$pep_max_probs{$peps[$pep]}}{$entry}\n";
}
next if(! exists ${$pep_max_probs{$peps[$pep]}}{$entry} || 
	    ${$pep_max_probs{$peps[$pep]}}{$entry} < $min_pep_prob);  # skip if not high enough prob
    
print STDERR "2. $peps[$pep]\n" if($verbose || $VERBOSE);    
    spaceXML(3);
    print XML '<peptide ';


    my $color =  ${$pep_max_probs{$peps[$pep]}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$peps[$pep]}}{$entry} >= $FINAL_PROB_MIN_WT ? 'Y' : 'N';

    my $std_pep;
    my $nterm;
    my $cterm;
    my $modptr;
    my $pepmass;
    # must deal with the equivalent peptide names....
    my $pep_seq;
    if(exists $equivalent_peps{$peps[$pep]}) {
	my @actualpeps = sort keys %{$equivalent_peps{$peps[$pep]}};
	$pep_seq = substr($actualpeps[0], 2);
    }
    else {
	$pep_seq = substr($peps[$pep], 2); #substr($actualpeps[0], 2);
    }


    if($XML_INPUT && $USE_STD_MOD_NAMES) {
	$std_pep = $pep_seq;
	# must recreate original stripped peptide from std peptide name, also get back modification info
	($pep_seq, $nterm, $cterm, $modptr) = interpretStdModifiedPeptide($std_pep);
	$pepmass = exists $peptide_masses{$peps[$pep]} ? $peptide_masses{$peps[$pep]} : 0.0;

	# write out modification below
    }

    print XML 'peptide_sequence="' . $pep_seq . '" ';

    if(! $USE_STD_MOD_NAMES && $pep_seq =~ /\#/) {
	$pep_seq =~ s/\#/\~/g;
	print XML 'pound_subst_peptide_sequence="' . $pep_seq . '" ';
    }

    print XML 'charge="', substr($peps[$pep], 0, 1), '" ';
    print XML 'initial_probability="';
    printf XML "%0.2f", ${$orig_pep_max_probs{$peps[$pep]}}{$entry};
    print XML '" ';
    print XML 'nsp_adjusted_probability="';
    printf XML "%0.2f", ${$pep_max_probs{$peps[$pep]}}{$entry};
    print XML '" ';
    print XML 'peptide_group_designator="', ${$indsptr}{$peps[$pep]}, '" ' if(exists ${$indsptr}{$peps[$pep]});
    print XML 'weight="';
    printf XML "%0.2f", ${$pep_wts{$peps[$pep]}}{$entry};
    print XML '" ';
    print XML 'is_nondegenerate_evidence="', Bool2Alpha(getNumberDegenProteins($peps[$pep]) == 1), '" ';
    print XML 'n_enzymatic_termini="', maxNTT($entry, $peps[$pep]), '" ';
    printf XML "n_sibling_peptides=\"%0.2f\" ", ${$estNSP{$peps[$pep]}}{$entry};
    printf XML "n_sibling_peptides_bin=\"%d\" ", ${$pep_nsp{$peps[$pep]}}{$entry};
    print XML 'n_instances="', numInstancesPeptide($peps[$pep], $entry, 0, 0), '"';
    print XML ' is_contributing_evidence="' . $color . '"'; #>', "\n";
    if($XML_INPUT && $USE_STD_MOD_NAMES) {
	if(exists $peptide_masses{$peps[$pep]}) {
	    print XML ' calc_neutral_pep_mass="' . $peptide_masses{$peps[$pep]} . '"';
	}
	else {
	    print XML ' calc_neutral_pep_mass="0"';
	    print "error: no peptide mass available for $peps[$pep]\n";
	}
    }	    
    print XML '>', "\n";
    # mod info
    my $modified = $nterm > 0.0 || $cterm > 0.0 || scalar keys %{$modptr} > 0;
    if($XML_INPUT && $USE_STD_MOD_NAMES && $modified) {
	print XML '<modification_info';
	print XML ' mod_nterm_mass="', $nterm, '"' if($nterm > 0.0);
	print XML ' mod_cterm_mass="', $cterm, '"' if($cterm > 0.0);
	print XML ' modified_peptide="', streamlineStdModifiedPeptide($std_pep), '"';
	print XML '>', "\n";
	foreach(sort {$a <=> $b} keys %{$modptr}) {
	    printf XML "<mod_aminoacid_mass position=\"%d\" mass=\"%f\"/>\n", $_, ${$modptr}{$_};
	}
	print XML '</modification_info>', "\n";
    }

    # parent protein info....
    foreach(sort keys %{$pep_max_probs{$peps[$pep]}}) {
	# only record additional prot's (not also in an indist group
	if(! ($_ eq $entry) && ! exists $degen{$entry}) {
	    spaceXML(4);
	    print XML '<peptide_parent_protein ';
	    my @firstname = split(' ');
	    print XML 'protein_name="', $firstname[0], '"/>', "\n";
	}
    }
    # must deal with the equivalent peptide names....
    if(exists $equivalent_peps{$peps[$pep]}) {
	my @actualpeps = sort keys %{$equivalent_peps{$peps[$pep]}};
	for(my $k = 1; $k < @actualpeps; $k++) {

	    if($XML_INPUT && $USE_STD_MOD_NAMES) {
		my $stripped_alt = strip($actualpeps[$k]);
		# write out modification below
		spaceXML(4);
		print XML '<indistinguishable_peptide peptide_sequence="', $stripped_alt, '">', "\n";
		print XML '<modification_info modified_peptide="', substr($actualpeps[$k], 2), '"/>', "\n" if($modified);
		print XML '</indistinguishable_peptide>', "\n";
	    }
	    else {
		spaceXML(4);
		print XML '<indistinguishable_peptide peptide_sequence="', substr($actualpeps[$k], 2), '"/>', "\n";
	    }
	}
    }
    spaceXML(3);
    print XML '</peptide>', "\n";
} # next pep
spaceXML(2);
print XML '</protein>', "\n";
}
 
sub writeProteinExcel {
(my $group_prob, my $entry, my $index, my $min_pep_prob, my $prot_id) = @_;

my $PRINT_COVERAGE = 0;

my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2

my $grp_index = '';
my $verbose = $entry =~ /133916/;
return if($protein_probs{$entry} < $EXCEL_MINPROB);

if($index =~ /^(\d+)(\-\d+)$/) {
    $grp_index = $1;
    $index = $2;
}
else {
    $grp_index = 0 - $index if($index < 0);
    $index = '' if($index < 0);
}

my $HEADER = '';
my @peps = reverse sort { ${$pep_max_probs{$a}}{$entry} <=> ${$pep_max_probs{$b}}{$entry} } keys %{$prot_peps{$entry}};

my $totuniquepeps = 0;
foreach(@peps) {
    $totuniquepeps++ if(${$pep_max_probs{$_}}{$entry} >= $min_pep_prob);
}

my @entries = split(' ', $entry);

$HEADER .= "$index\t$group_prob\t" . join(',', @entries) . "\t";

$HEADER .= sprintf("%0.2f\t", $protein_probs{$entry});
my $cov = getCoverageForEntry($entry, $PRINT_PROT_COVERAGE); 
print STDERR "coverage for $entry: $cov\n" if($verbose);
if($cov > -1) {
    $HEADER .= sprintf("%0.1f\t", $cov);
}
else {
    $HEADER .= "\t";
}

if($ASAP) {
    my $result = getASAPRatio($ASAP_IND, $entry, \@peps);
    print STDERR "result for $entry: $result\n" if($verbose);

    my $pro_index = '';
    if($result =~ /proIndx\=(\d+)/) {
	$pro_index = $1;
    }

    # now strip off html tags
    while($result =~ /(.*)\<.*?\>(.*)/) {
	$result = $1 . $2;
    }
    if($result =~ /ASAP\:\s+(\S+)\s+\+\-\s+(\S+)\s+\(\S+\)\s+(\d+)\s?$/) {
	$HEADER .= sprintf("%0.2f\t%0.2f\t%d\t", $1, $2, $3);
    }
    else {
	$HEADER .= "\t\t\t"; # no info
    }
}

$HEADER .= "$totuniquepeps\t" . getTotalNumPeps($entry, \@peps) . "\t";

# annotation
my @prot_descr = ();
my @ipi = ();
my @refseq = ();
my @swissprot = ();
my @ensembl = ();
my @trembl = ();
if($ANNOTATION) { # && exists $annotation{$entries[0]}) {

    getAnnotation($entry, $database, -1);
    for(my $k = 0; $k < @entries; $k++) {

	if($IPI_DATABASE) {
	    my $next_annot = exists $annotation{$entries[$k]} ? $annotation{$entries[$k]} : $entries[$k];
	    (my $prot_descr, my $ipi, my $refseq, my $swissprot, my $ensembl, my $trembl) = parseIPI($next_annot);
	    push(@prot_descr, $prot_descr);
	    push(@ipi, $ipi);
	    push(@refseq, $refseq);
	    push(@swissprot, $swissprot);
	    push(@ensembl, $ensembl);
	    push(@trembl, $trembl);
	}
	elsif(exists $annotation{$entries[$k]}) {
	    my @description = split('\n', $annotation{$entries[$k]});
	    push(@prot_descr, join(' ', @description));
	    # clean up
	    if($prot_descr[$#prot_descr] =~ /^\&gt\;$entries[$k]\s+(\S+.*)$/) {
		$prot_descr[$#prot_descr] = $1;
	    }
	}
    } # next indisting
}

# now write them
$HEADER .= join(',', @ipi) . "\t" if($IPI_DATABASE);
$HEADER .= join(',', @prot_descr) . "\t"; 
$HEADER .= join(',', @ensembl) . "\t" . join(',', @trembl) . "\t" . join(',', @swissprot) . "\t" . join(',', @refseq) . "\t" if($IPI_DATABASE);


my $indsptr = findCommonPeps(\@peps);

for(my $pep = 0; $pep < @peps; $pep++) {
    print EXCEL $HEADER;
    $pep = scalar @peps if(! $EXCEL_PEPTIDES && $pep == 0); # done
    if($EXCEL_PEPTIDES) {
	next if(${$pep_max_probs{$peps[$pep]}}{$entry} < $min_pep_prob);  # skip if not high enough prob
    
	my $color =  ${$pep_max_probs{$peps[$pep]}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$peps[$pep]}}{$entry} >= $FINAL_PROB_MIN_WT ? 'Y' : 'N';
	# charge
	printf EXCEL "%0.2f\t", ${$pep_wts{$peps[$pep]}}{$entry}; # wt
	print EXCEL "", substr($peps[$pep], 0, 1), "\t";
	# must deal with the equivalent peptide names....
	if(exists $equivalent_peps{$peps[$pep]}) {
	    my @actualpeps = sort keys %{$equivalent_peps{$peps[$pep]}};

	    print EXCEL "", substr($actualpeps[0], 2), "\t";
	}
	else {
	    print EXCEL "",  substr($peps[$pep], 2), "\t";
	}
	print EXCEL "", sprintf("%0.2f\t", ${$pep_max_probs{$peps[$pep]}}{$entry}); #nsp adj
	print EXCEL "", sprintf("%0.2f\t", ${$orig_pep_max_probs{$peps[$pep]}}{$entry});
	print EXCEL "", maxNTT($entry, $peps[$pep]), "\t";
	print EXCEL "", ${$pep_nsp{$peps[$pep]}}{$entry}, "\t";
	print EXCEL "", numInstancesPeptide($peps[$pep], $entry, 0, 0), "\t";
	print EXCEL "", ${$indsptr}{$peps[$pep]} if(exists ${$indsptr}{$peps[$pep]}); # pep group desig
	print EXCEL "\t";
	print EXCEL "", Bool2Alpha(getNumberDegenProteins($peps[$pep]) == 1), "\t";
	print EXCEL "", Bool2Alpha($color);
	print EXCEL "\n";
    } # next pep
} # if peps
if(! $EXCEL_PEPTIDES) {
    print EXCEL "\n";
}
}
 

sub parseIPI {
(my $annot) = @_;
my $ipi = '';
my $refseq = '';
my $swissprot = '';
my $protein_description = '';
my $ensembl = '';
my $trembl = '';
if($annot =~ /Ensembl\_locations\S+\s+(\S.*\S)/) { # mouse IPI
    $protein_description = $1;
}
elsif($annot =~ /IPI.*?Tax\_Id\=\d\d*\s+(\S.*\S)\s?\s?\,?\s?\s?\s?\|/) { 
    $protein_description = $1;
}
elsif($annot =~ /IPI.*?Tax\_Id\=\d\d*\s+(\S.*\S)/) {
    $protein_description = $1;
}
elsif($annot =~ /(\S+)/) {
    $protein_description = ''; #$1; # not really IPI
}

if($annot =~ /REFSEQ\_?[A-Z]?[A-Z]?\:(\S+?)[\|,\s,\;]/) {
    $refseq = $1;
}
if($annot =~ /SWISS\-PROT\:(\S+?)[\|,\s,\;]/) {
    $swissprot = $1;
}
if($annot =~ /TREMBL\:(\S+?)[\|,\s,\;]/) {
    $trembl = $1;
}
if($annot =~ /ENSEMBL\:(\S+?)[\|,\s,\;]/) {
    $ensembl = $1;
}
return ($protein_description, $ipi, $refseq, $swissprot, $ensembl, $trembl);
}


sub getFlybaseInfo {
(my $annot) = @_;
if($annot =~ /(FBgn\S+)\]/) {
    return $1;
}
return '';
}


sub writeCoverageInfo {
(my $outfile, my $min_prot_prob, my $max_num_prots) = @_;

# order all db entries
my %db_no = ();
die "cannot find $database\n" if(! -e $database);
open(DB, $database);
my $num = 0;
while(<DB>) {
    if(/^\>(\S+)\s+/) {
	$db_no{$1} = $num++;
    }
}
close(DB);

# compile list of all prots for cov
my @cov_prots = ();

my %prot_degen_groups = ();
foreach(reverse sort { $protein_probs{$a} <=> $protein_probs{$b} } keys %protein_probs) {
    if($protein_probs{$_} >= $min_prot_prob) {
	my @parsed = split(' ');
	for(my $k = 0; $k < @parsed && $k < $max_num_prots; $k++) {

	    if(exists $db_no{$parsed[$k]}) {
		push(@cov_prots, $parsed[$k]);
		$prot_degen_groups{$parsed[$k]} = $_;
	    }
	}
    } # above min prob 

}

# sort by db_no
@cov_prots = sort {$db_no{$a} <=> $db_no{$b}} @cov_prots;

# now write to file
open(OUT, ">$outfile");
foreach(@cov_prots) {
    print OUT ">$_\n";
    my @peps = sort keys %{$prot_peps{$prot_degen_groups{$_}}};
    my %next = ();
    for(my $k = 0; $k < @peps; $k++) {
	    if(exists $equivalent_peps{$peps[$k]}) {
		my @actualpeps = sort keys %{$equivalent_peps{$peps[$k]}};
		for(my $kk = 0; $kk < @actualpeps; $kk++) {
		    $next{strip($actualpeps[$kk])}++;
		}
	    }
	    else {
		$next{strip($peps[$k])}++;
	    }
    }
    my @unique_peps = sort keys %next;
    for(my $k = 0; $k < @unique_peps; $k++) {
	print OUT "$unique_peps[$k]\n";
    }
}
close(OUT);
}



sub computeCoverage {
(my $min_prot_prob, my $max_num_prots) = @_;
my $covinfofile = $OUTFILE . '.covinfo';
my $covresultsfile = $OUTFILE . '.cov';
my $coverage_exec = "";
#my $coverage_exec = 'batchcoverage'; #'/data2/search/akeller/COVERAGE/BATCH/batchcoverage';
if($WINDOWS_CYGWIN) {
  $coverage_exec = '/usr/bin/batchcoverage.exe';
}
else {
  # linux:
  # assume batchcoverage is installed to same dir as this script
  $coverage_exec = $BINARY_DIRECTORY . 'batchcoverage';
}
if(! -e $coverage_exec) {
    print " unable to calculate coverage information: ";
    print " cannot find $coverage_exec\n" ;
    print " please check your installation\n";
    return;
}



if(! -e $database) {
    print " cannot find database: $database, no coverage information possible\n";
    return;
}
writeCoverageInfo($covinfofile, $min_prot_prob, $max_num_prots);
system("$coverage_exec '$database' $covinfofile $covresultsfile") if(-e $covinfofile);
readCoverageResults($covresultsfile) if(-e $covresultsfile);
unlink($covresultsfile) if(-e $covresultsfile);
unlink($covinfofile) if(-e $covinfofile);
}



sub readCoverageResults {
(my $infile) = @_;
die "cannot find $infile\n" if(! -e $infile);
%coverage = ();
open(FILE, $infile);
while(<FILE>) {
    if(/^(\S+)\s+(\S+)/) {
	$coverage{$1} = $2;
    }
}
close(FILE);
}

sub getCoverageForEntry {
(my $entry, my $max_num_prots) = @_;
return $coverage{$entry} if(exists $coverage{$entry});
my @prots = split(' ', $entry);
my $max = -1;
for(my $k = 0; $k < @prots && $k < $max_num_prots; $k++) {
    $max = $coverage{$prots[$k]} if(exists $coverage{$prots[$k]} &&
				    $coverage{$prots[$k]} > $max);
}
return $max;
}

sub updateProteinWeights {
(my $include_groups) = @_;

print STDERR " updateProteinWeights!\n" if($DEBUG);
    my $max_prob = 1.1; #0.85; #1.1; #0.9; #1.1;
    my $PRIOR = 0.005; #2;
    $PRIOR = 0 if($ACCURACY_MODE);
    my $MAX_DIFF = 0.005; #0.02;
    my $tot;
    my $next_wt;
    my $change = 0;
    my $verbose;
    my $peptide = '3_VYDGPSSNSHLLTQLCGDEK';
    my $next_prob;
    my $skip;
    foreach(sort keys %pep_wts) {

	$verbose = 0;

	my @prots = sort keys %{$pep_wts{$_}};

	$PRIOR = $USE_WT_PRIORS ? 0.1 / @prots : $PRIOR;

	$tot = 0;

	for(my $k = 0; $k < @prots; $k++) {
	    print STDERR "$prots[$k] for $peptide...\n" if($verbose);
            $skip = $include_groups && exists $member{$prots[$k]} && ! exists $degen{$prots[$k]};	    
	    print STDERR "found $prots[$k] for $_\n" if($verbose);
            if(! $skip) {

		$next_prob = $protein_probs{$prots[$k]};
		$next_prob = 1 if($next_prob >= $max_prob);
		$tot += $next_prob + $PRIOR;
		print STDERR "$prots[$k] prob: $protein_probs{$prots[$k]} ($PRIOR)\n" if($verbose);
	    }
	}
	for(my $k = 0; $k < @prots; $k++) {
            $skip = $include_groups && exists $member{$prots[$k]} && ! exists $degen{$prots[$k]};	    
            if(! $skip) {

		$next_prob = $protein_probs{$prots[$k]};
		$next_prob = 1 if($next_prob >= $max_prob);


		if($tot > 0) {
		    $next_wt = ($next_prob + $PRIOR) / $tot;
		}
		elsif(@prots > 0) {
		    $next_wt = 1 / @prots;
		}
		else {
		    $next_wt = 0;
		}
		$next_wt = $next_wt**$WT_POWER;

		if ( abs($next_wt - ${$pep_wts{$_}}{$prots[$k]}) > $MAX_DIFF){
            print STDERR "update wts for  $_ $prots[$k] ${$pep_wts{$_}}{$prots[$k]} $next_wt, with tot: $tot and next_prob $next_prob\n" if($verbose);
	        ${$pep_wts{$_}}{$prots[$k]} = $next_wt; # BSP formery once one updated they all updated
			$change = 1;
        }
            } # if not skip
	}

    }
return $change;
}

sub iterate1 {
(my $max_iters) = @_;
my $counter = 1;
updateProteinProbs();
while($OCCAM && $counter < $max_iters && updateProteinWeights(0)) {
    print STDERR " updating protein probs.....\n" if(! $SILENT);
    $counter++;
    updateProteinWeights(0) if($OCCAM);
}
return $counter;

while($counter < $max_iters && updateProteinProbs()) {
    print STDERR " updating protein probs.....\n" if(! $SILENT);
    $counter++;
    updateProteinWeights(0) if($OCCAM);
}
return $counter;
}

sub final_iterate {
(my $max_iters) = @_;
my $counter = 0;
return $counter if(! $OCCAM);
computeFinalProbs(); # with wts of degenerate groups
while($counter < $max_iters && updateProteinWeights(1)) {
    $counter++;
    computeFinalProbs();
    print STDERR " final update of weights and protein probabilities.....\n" if(! $SILENT);
}
return $counter;
}

sub setPepMaxProbs {
(my $use_nsp, my $use_joint_probs, my $compute_spectrum_cnts) = @_;
%pep_max_probs = ();
%orig_pep_max_probs = () if(! $use_nsp);
my $pep2;
my @prots2 = ();
my @probs2;
my $max2 = 0;  # hold the maximum prob for all prots
my $pep3;
my @prots3 = ();
my @probs3;
my $max3 = 0;
my $VERBOSE = 0;
my $pep1;
my @prots1 = ();
my @probs1;



foreach(@spectra) {

    $pep2 = ${$specpeps{$_}}[0];
$max2 = 0;
$max3 = 0;
    my $verbose = 0; #/haloICAT2\_40\.1288\.1288/; #   0; #${$specpeps{$_}}[0] eq '2_LLGPNCPGLLTPGEAK'; #3_YQHDVEDGVSPR';0; #$pep2 eq '2_HNPVFGVMS';
    if(! ($pep2 eq $NODATA)) {

       @prots2 = sort keys %{$pep_wts{$pep2}};    
       @probs2 = ();
       $max2 = 0;
       for(my $k = 0; $k < @prots2; $k++) {
	   if($use_nsp) {
	       $probs2[$k] = getNSPAdjustedProb(
                   ${${$specprobs{$_}}[0]}[${$pep_prob_ind{$pep2}}{$prots2[$k]}],
                   ${$pep_nsp{$pep2}}{$prots2[$k]});
             } # use nsp
            else {
               $probs2[$k] = ${${$specprobs{$_}}[0]}[${$pep_prob_ind{$pep2}}{$prots2[$k]}];
            }
            $max2 = $probs2[$k] if($use_joint_probs && $probs2[$k] > $max2);
	   print STDERR "$_ $pep2 $prots2[$k] $probs2[$k] max2: $max2\n" if($verbose);
        } # next protein
    } # if not no data
    $pep3 = ${$specpeps{$_}}[1];
    #$verbose = 0;
    if(! ($pep3 eq $NODATA)) {
        @prots3 = sort keys %{$pep_wts{$pep3}};    
        @probs3 = ();
        $max3 = 0;
        for(my $k = 0; $k < @prots3; $k++) {
	    #print "here\n" if($prots3[$k] =~ /AB028127/);

	    if($use_nsp) {
	        $probs3[$k] = getNSPAdjustedProb(
                   ${${$specprobs{$_}}[1]}[${$pep_prob_ind{$pep3}}{$prots3[$k]}],
                   ${$pep_nsp{$pep3}}{$prots3[$k]});
            } # use nsp
            else {
                $probs3[$k] = ${${$specprobs{$_}}[1]}[${$pep_prob_ind{$pep3}}{$prots3[$k]}];
            }
	    print STDERR "$pep3: max3 $max3, probs: $probs3[$k]\n" if($verbose);
            $max3 = $probs3[$k] if($use_joint_probs && $probs3[$k] > $max3);
        } # next protein
    } # if not no data
    # now assign pep_max_probs using adjusted for joint 2+/3+ if specified
    my $REF = '2_ANVPESLK'; 
    $VERBOSE = 0; 

    print STDERR "$_ $REF max2: $max2, max3: $max3\n" if($verbose || $VERBOSE);

    for(my $k = 0; $k < @prots2; $k++) {
	$VERBOSE = 0;
	print "$prots2[$k] prob $probs2[$k]\t" if($verbose || $VERBOSE);

        # NOW MAKE JOINT 2+/3+ ADJUSTMENTS
	if($use_joint_probs && $probs2[$k] > 0) {
	    my $factor = $probs2[$k] + $max3 > 1 ? ($probs2[$k] + $max3 - $probs2[$k] * $max3) / ($probs2[$k] + $max3) : 1;
	    if(exists $pep_max_probs{$pep2}) {
		if(! exists ${$pep_max_probs{$pep2}}{$prots2[$k]} || 
                   $probs2[$k] * $factor > ${$pep_max_probs{$pep2}}{$prots2[$k]}) {
		       ${$pep_max_probs{$pep2}}{$prots2[$k]} = $probs2[$k] * $factor;
	               ${$orig_pep_max_probs{$pep2}}{$prots2[$k]} = $probs2[$k] * $factor if(! $use_nsp);
                }
	    }
	    else {
	        my %next = ($prots2[$k] => $factor * $probs2[$k]);
	        $pep_max_probs{$pep2} = \%next;
		if(! $use_nsp) {
		    my %next1 = ($prots2[$k] => $factor * $probs2[$k]);
		    $orig_pep_max_probs{$pep2} = \%next1;
		}
	    }
	}
	else {
	    if(exists $pep_max_probs{$pep2}) {
		if(! exists ${$pep_max_probs{$pep2}}{$prots2[$k]} || 
                   $probs2[$k] > ${$pep_max_probs{$pep2}}{$prots2[$k]}) {
	             ${$pep_max_probs{$pep2}}{$prots2[$k]} = $probs2[$k];
	             ${$orig_pep_max_probs{$pep2}}{$prots2[$k]} = $probs2[$k] if(! $use_nsp);
                }
	    }
	    else {
	        my %next = ($prots2[$k] => $probs2[$k]);
	        $pep_max_probs{$pep2} = \%next;
		if(! $use_nsp) {
		    my %next1 = ($prots2[$k] => $probs2[$k]);
		    $orig_pep_max_probs{$pep2} = \%next1;
		}
	    }
	} # no joints or zero prob
	$VERBOSE = 0; 
	print STDERR "set pep max prob for $pep2 to $prots2[$k] to ${$pep_max_probs{$pep2}}{$prots2[$k]}...\n" if($verbose || $VERBOSE);

	if($compute_spectrum_cnts && $k == 0 && ! ($pep2 eq $NODATA)) {
	    $spectrum_counts{$pep2} += $probs2[$k];
	    $total_spectrum_counts += $probs2[$k];
	} # if compute total spec counts
    } # next protein
    for(my $k = 0; $k < @prots3; $k++) {
	$VERBOSE = 0; #$prots3[$k] =~ /AB028127/;
;
	print STDERR "$prots3[$k] prob $probs3[$k]\n" if($VERBOSE);
	if($use_joint_probs && $probs3[$k] > 0) {
	    my $factor = $probs3[$k] + $max2 > 1 ? ($probs3[$k] + $max2 - $probs3[$k] * $max2) / ($probs3[$k] + $max2) : 1;
            print STDERR "factor $factor\n" if($VERBOSE);
	    if(exists $pep_max_probs{$pep3}) {
		if(! exists ${$pep_max_probs{$pep3}}{$prots3[$k]} || 
                   $probs3[$k] * $factor > ${$pep_max_probs{$pep3}}{$prots3[$k]}) {
		${$pep_max_probs{$pep3}}{$prots3[$k]} = $probs3[$k] * $factor;
		${$orig_pep_max_probs{$pep3}}{$prots3[$k]} = $probs3[$k] * $factor if(! $use_nsp);
               }
	    }
	    else {
	        my %next = ($prots3[$k] => $factor * $probs3[$k]);
	        $pep_max_probs{$pep3} = \%next;
		if(! $use_nsp) {
		    my %next1 = ($prots3[$k] => $factor * $probs3[$k]);
		    $orig_pep_max_probs{$pep3} = \%next1;
		}
	    }
	}
	else {
	    if(exists $pep_max_probs{$pep3}) {
		if(! exists ${$pep_max_probs{$pep3}}{$prots3[$k]} || 
                   $probs3[$k] > ${$pep_max_probs{$pep3}}{$prots3[$k]}) {
		${$pep_max_probs{$pep3}}{$prots3[$k]} = $probs3[$k];
		${$orig_pep_max_probs{$pep3}}{$prots3[$k]} = $probs3[$k] if(! $use_nsp);
               }
	    }
	    else {
	        my %next = ($prots3[$k] => $probs3[$k]);
	        $pep_max_probs{$pep3} = \%next;
		if(! $use_nsp) {
		    my %next1 = ($prots3[$k] => $probs3[$k]);
		    $orig_pep_max_probs{$pep3} = \%next1;
		}
	    }
	} # no joints or zero prob
	$VERBOSE = 0; #$prots3[$k] eq 'Chr_ORF0931';
     print "max prob: ${$pep_max_probs{$pep3}}{$prots3[$k]}\n" if($verbose || $VERBOSE);
print STDERR "set pep max prob for $pep3 to $prots3[$k] to ${$pep_max_probs{$pep3}}{$prots3[$k]}...\n" if($verbose || $VERBOSE);
	if($compute_spectrum_cnts && $k == 0 && ! ($pep3 eq $NODATA)) {
	    $spectrum_counts{$pep3} += $probs3[$k];
	    $total_spectrum_counts += $probs3[$k];
	} # if compute total spec counts

    } # next protein

   $VERBOSE = 0; # reset

} # next spectrum

# now do the singly charged...
my $verbose1 = 0;
foreach(@singly_spectra) {
    $pep1 = $singly_specpeps{$_};

    @prots1 = sort keys %{$pep_wts{$pep1}};    
    @probs1 = ();
    print STDERR "num prots for $pep1: ", scalar @prots1, "\n" if($verbose1);
    for(my $k = 0; $k < @prots1; $k++) {

	if($use_nsp) {
	    $probs1[$k] = getNSPAdjustedProb(
	           ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep1}}{$prots1[$k]}],
                   ${$pep_nsp{$pep1}}{$prots1[$k]});
         } # use nsp
         else {
             $probs1[$k] = ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep1}}{$prots1[$k]}];
         }
	 if(exists $pep_max_probs{$pep1}) {
	     if(! exists ${$pep_max_probs{$pep1}}{$prots1[$k]} || 
                   $probs1[$k] > ${$pep_max_probs{$pep1}}{$prots1[$k]}) { # update
		${$pep_max_probs{$pep1}}{$prots1[$k]} = $probs1[$k];
		${$orig_pep_max_probs{$pep1}}{$prots1[$k]} = $probs1[$k] if(! $use_nsp);
             }
	 }
	 else {
	     my %next = ($prots1[$k] => $probs1[$k]);
	     $pep_max_probs{$pep1} = \%next;
	     if(! $use_nsp) {
		 my %next1 = ($prots1[$k] => $probs1[$k]);
		 $orig_pep_max_probs{$pep1} = \%next1;
	     }
	 }
	if($compute_spectrum_cnts && $k == 0 && ! ($pep1 eq $NODATA)) {
	    $spectrum_counts{$pep1} += $probs1[$k];
	    $total_spectrum_counts += $probs1[$k];
	} # if compute total spec counts


    } # next protein

} # next singly spectrum

}

sub setExpectedNumSiblingPeps {
    print STDERR " computing NSP values for peptides.....\n" if(! $SILENT);
    my $index = 1;
    my $total = 0;
    $total = scalar keys %pep_wts if($DEBUG);

    foreach(sort keys %pep_wts) {
	if($DEBUG) {
	    print STDERR "$index/$total  ";
	    $index++;
	}
	my $VERBOSE = 0; #($_ eq '2_K.NLVSMLTYTYDPVEK.Q' || $_ eq '2_K.ETMQSLNDR.L');
	my @prots = sort keys %{$pep_wts{$_}};
	for(my $k = 0; $k < @prots; $k++) {
	    printf STDERR "[%d/%d] ", $k+1, scalar @prots if($DEBUG);
	    ${$estNSP{$_}}{$prots[$k]} = getSharedProtProb($_, $prots[$k]);
	    ${$pep_nsp{$_}}{$prots[$k]} = getSharedProtIndex(getSharedProtProb($_, $prots[$k]));
	if($VERBOSE) {
	    print "$_ $prots[$k]: ", getSharedProtProb($_, $prots[$k]), ", ", getSharedProtIndex(getSharedProtProb($_, $prots[$k])), "\n";
	}

        } # next protein
    } # next pep
print STDERR "\n" if($DEBUG);
}

sub getSharedProtProb {
(my $pep, my $prot) = @_;
my $MIN_WT2 = $MIN_WT;
my $numer_tot = 0;
my $PSEUDOCOUNTS = 1;
my $denom_tot = $PSEUDOCOUNTS;
my $mult;
my @siblingpeps = sort keys %{$prot_peps{$prot}};

my $VERBOSE = 0; #$prot =~ /GP\:AF020194\_1/;
for(my $j = 0; $j < @siblingpeps; $j++) {
	$mult = 1;
    if(! ($pep eq $siblingpeps[$j])) { # no min prob or wt for denominator
	print "$siblingpeps[$j] - ${$pep_max_probs{$siblingpeps[$j]}}{$prot} - ${$pep_wts{$siblingpeps[$j]}}{$prot}" if($VERBOSE);
	if(${$pep_wts{$siblingpeps[$j]}}{$prot} >= $MIN_WT2 &&
           ${$pep_max_probs{$siblingpeps[$j]}}{$prot} >= $MIN_PROB) {
                $numer_tot += ${$pep_max_probs{$siblingpeps[$j]}}{$prot} * ${$pep_wts{$siblingpeps[$j]}}{$prot} * $mult;
        }
    }
    # this option invokes minimum prob and wt for denom and numerator...
} # next sibling
print "$numer_tot\n" if ($VERBOSE);
return $numer_tot / $denom_tot if($denom_tot > 0);
return $shared_prot_prob_threshes[$#shared_prot_prob_threshes] + 1; # max allowable

}

sub getSharedProtIndex {
(my $sharedprotprob) = @_;
for(my $k = 0; $k < @shared_prot_prob_threshes; $k++) {
    return $k if($sharedprotprob < $shared_prot_prob_threshes[$k]);
}
return scalar @shared_prot_prob_threshes;
}

sub getNSPAdjustedProb {
(my $prob, my $nsp_index) = @_;
my $USE_MIN_PROB = 0.45;
my $USE_MAX_DIFF = 0.3;
return 0 if($prob == 0);
my $eff_nsp_index = $nsp_index;
$eff_nsp_index = $NSP_BIN_EQUIVS[$nsp_index];

print "$pos_shared_prot_distrs[$eff_nsp_index] $neg_shared_prot_distrs[$eff_nsp_index] $prob $eff_nsp_index\n" if($DEBUG);

my $pos = $prob * $pos_shared_prot_distrs[$eff_nsp_index];
return 0 if($pos == 0);
my $neg = (1 - $prob) * $neg_shared_prot_distrs[$eff_nsp_index];
my $new_prob = $pos / ($pos + $neg);
if($new_prob > $prob) {
    return $prob if($USE_MIN_PROB && $prob < $USE_MIN_PROB);
    return ($prob + $USE_MAX_DIFF) if($USE_MAX_DIFF && $new_prob > $prob + $USE_MAX_DIFF);
}

return ($pos / ($pos + $neg));
}

sub updateNSPDistributions {
    my $pep;
    my $nsp_ind;
    my $probptr;
    my $nextprob;
    my $totpos = 0;
    my $totneg = 0;
    my @newpos = (0);
    my @newneg = (0);
    my $output = 0;
    my $MIN_DIFF = 0.02;
    my $shared_prot_prob_pseudocounts = 0.01;  # how many times the total num to add as pseudocounts to each bin

    $shared_prot_prob_pseudocounts = $NSP_PSEUDOS;

    foreach(@shared_prot_prob_threshes) {
	push(@newpos, 0);
	push(@newneg, 0);
    }
    $shared_prot_prob_pseudocounts *= @newpos;
    foreach(@spectra) {
	for(my $ch = 0; $ch < 2; $ch++) {
            $probptr = ${$specprobs{$_}}[$ch];
	    $pep = ${$specpeps{$_}}[$ch];
	    if(! ($pep eq $NODATA)) {
		my @prots = sort keys %{$pep_wts{$pep}};
		for(my $k = 0; $k < @prots; $k++) {
		    $nsp_ind = ${$pep_nsp{$pep}}{$prots[$k]};
		
		    $nextprob = getNSPAdjustedProb(${$probptr}[${$pep_prob_ind{$pep}}{$prots[$k]}], $nsp_ind);
                    $newpos[$nsp_ind] += $nextprob * ${$pep_wts{$pep}}{$prots[$k]};
                    $totpos += $nextprob * ${$pep_wts{$pep}}{$prots[$k]};
                    $newneg[$nsp_ind] += (1-$nextprob) * ${$pep_wts{$pep}}{$prots[$k]};
                    $totneg += (1-$nextprob) * ${$pep_wts{$pep}}{$prots[$k]};
               } # next prot
            } # if this spectrum has data
        } # next charge state

    } # next spectrum

# now the singlys...
    foreach(@singly_spectra) {
	$probptr = $singly_specprobs{$_};
	$pep = $singly_specpeps{$_};
	my @prots = sort keys %{$pep_wts{$pep}};
	for(my $k = 0; $k < @prots; $k++) {
	    $nsp_ind = ${$pep_nsp{$pep}}{$prots[$k]};
		
	    $nextprob = getNSPAdjustedProb(${$probptr}[${$pep_prob_ind{$pep}}{$prots[$k]}], $nsp_ind);
	    $newpos[$nsp_ind] += $nextprob * ${$pep_wts{$pep}}{$prots[$k]};
	    $totpos += $nextprob * ${$pep_wts{$pep}}{$prots[$k]};
	    $newneg[$nsp_ind] += (1-$nextprob) * ${$pep_wts{$pep}}{$prots[$k]};
	    $totneg += (1-$nextprob) * ${$pep_wts{$pep}}{$prots[$k]};
	} # next prot
    }  # next spectrum

    if($SMOOTH) {
	my $tot;
	my $neighbor_wt = $SMOOTH;
	my @newerpos = ();
	my @newerneg = ();
	$totpos = 0;
	$totneg = 0;
	for(my $k = 0; $k < @newpos; $k++) {
	    $tot = 0;
	    if($k == 0) {
		$tot = 1 + $neighbor_wt;
		$newerpos[$k] = ($newpos[$k] + $neighbor_wt * $newpos[$k+1])/$tot;
		$newerneg[$k] = ($newneg[$k] + $neighbor_wt * $newneg[$k+1])/$tot;
	    }
	    elsif($k == @newpos-1) {
		$tot = 1 + $neighbor_wt;
		$newerpos[$k] = ($newpos[$k] + $neighbor_wt * $newpos[$k-1])/$tot;
		$newerneg[$k] = ($newneg[$k] + $neighbor_wt * $newneg[$k-1])/$tot;
	    }
	    else {
		$tot = 1 + 2 * $neighbor_wt;
		$newerpos[$k] = ($newpos[$k] + $neighbor_wt * ($newpos[$k-1]+$newpos[$k+1]))/$tot;
		$newerneg[$k] = ($newneg[$k] + $neighbor_wt * ($newneg[$k-1]+$newneg[$k+1]))/$tot;
	    }
	    $totpos += $newerpos[$k];
	    $totneg += $newerneg[$k];
	}
	@newpos = @newerpos;
	@newneg = @newerneg;
    }
    my $option = 1;
    if($option) {


	my $NUM_PSS = 2;
	my $NUM_PSS2 = $totpos > 0 ? $NUM_PSS * $totneg / $totpos : $NUM_PSS;
	for(my $k = 0; $k < @newpos; $k++) {
	    $newpos[$k] += $NUM_PSS;
	    $totpos += $NUM_PSS;
	    $newneg[$k] += $NUM_PSS2;
	    $totneg += $NUM_PSS2;
	}
	for(my $k = 0; $k < @newpos; $k++) {
	    $newpos[$k] /= $totpos if($totpos > 0);
	    $output ||= abs($newpos[$k] - $pos_shared_prot_distrs[$k]) > $MIN_DIFF;
	    $newneg[$k] /= $totneg if($totneg > 0);
	    $output ||= abs($newneg[$k] - $neg_shared_prot_distrs[$k]) > $MIN_DIFF;
	}
    }
    else {
# add the pseudocounts here...
	for(my $k = 0; $k < @newpos; $k++) {
	    $newpos[$k] += $shared_prot_prob_pseudocounts * $totpos / @newpos;
	    $newneg[$k] += $shared_prot_prob_pseudocounts * $totneg / @newpos;
	}


	for(my $k = 0; $k < @newpos; $k++) {
	    $newpos[$k] /= ($totpos * (1 + $shared_prot_prob_pseudocounts)) if($totpos > 0);
	    $output ||= abs($newpos[$k] - $pos_shared_prot_distrs[$k]) > $MIN_DIFF;
	    $newneg[$k] /= ($totneg * (1 + $shared_prot_prob_pseudocounts)) if($totneg > 0);
	    $output ||= abs($newneg[$k] - $neg_shared_prot_distrs[$k]) > $MIN_DIFF;
	}
    } # if not option
    return 0 if(! $output); # nothing to change

    @pos_shared_prot_distrs = @newpos;
    @neg_shared_prot_distrs = @newneg;


# reset these
    @NSP_BIN_EQUIVS = ();

    my @max_rat = (0, -1);
    my @min_rat = (9999, -1);
    my $next_rat;
    for(my $k = 0; $k <= @shared_prot_prob_threshes; $k++) {
	$next_rat = $neg_shared_prot_distrs[$k] > 0 ? $pos_shared_prot_distrs[$k] / $neg_shared_prot_distrs[$k] : 9999;
	@min_rat = ($next_rat, $k) if($next_rat < $min_rat[0]);
	@max_rat = ($next_rat, $k) if($next_rat > $max_rat[0]);
	$NSP_BIN_EQUIVS[$k] = $next_rat < $max_rat[0] ? $max_rat[1] : $k;
    }
# now the ones less than min
    for(my $k = 1; $k < $min_rat[1] && $k < $max_rat[1]; $k++) {
	$NSP_BIN_EQUIVS[$k] = $min_rat[1];
    }
    my $joined = join(',', @NSP_BIN_EQUIVS);
    print STDERR " ---nsp bin equivs: ($joined)\n" if(! $SILENT);

    return $output;
}



# generalization of equileucine to accommodate multiple aa substitutions (specified by hash)
sub equivalentPeptide {
(my $substitutionptr, my $equivalenceptr, my $pep) = @_;
my $abort = 1;
foreach(keys %{$substitutionptr}) {
    $abort = 0 if(index($pep, $_) >= 0);
}
return $pep if($abort);
my $output = '';
my $next;
for(my $k = 0; $k < length $pep; $k++) {
    $next = substr($pep, $k, 1);
    if(exists ${$substitutionptr}{$next}) {
        $output .= ${$substitutionptr}{$next};
    }
    else {
	$output .= $next;
    }
}
if(exists ${$equivalenceptr}{$output}) {
    ${${$equivalenceptr}{$output}}{$pep}++;
}
else {
    my %next = ($pep => 1);
    ${$equivalenceptr}{$output} = \%next;
}
return $output;

}

sub computeFinalProbs {
    %final_prot_probs = ();
    foreach(keys %degen) {
	$final_prot_probs{$_} = computeDegenProtProb($_);
    }
    foreach(keys %prot_peps) {
	if(! exists $degen{$_} && ! exists $member{$_}) {
	    $final_prot_probs{$_} = computeProteinProb($_);
	}
    }
    %protein_probs = ();
    foreach(keys %final_prot_probs) {
	$protein_probs{$_} = $final_prot_probs{$_} > 1 ? 1 : sprintf("%0.2f", $final_prot_probs{$_}); # truncate after 2 decimal places
    }

}

sub getOrderedSignPeps {
(my $prot, my $min_wt, my $min_prob) = @_;

my $verbose = 0;

my @peps = sort keys %{$prot_peps{$prot}};

if($verbose) {
    for(my $k = 0; $k < @peps; $k++) {
	print "found $peps[$k] for $prot\n";
    }
}
print STDERR "min wt: $min_wt, min prob: $min_prob\n" if($verbose);
# get all the peptides that have wt greater than min
my @s_peps = ();
for(my $k = 0; $k < @peps; $k++) {
    push(@s_peps, $peps[$k]) if(${$pep_wts{$peps[$k]}}{$prot} >= $min_wt &&
	                           ${$pep_max_probs{$peps[$k]}}{$prot} >= $min_prob);
    print STDERR "$peps[$k] (${$pep_wts{$peps[$k]}}{$prot}, ${$pep_max_probs{$peps[$k]}}{$prot}) for $prot\n" if($verbose);
    print STDERR "adding $peps[$k] (${$pep_wts{$peps[$k]}}{$prot}, ${$pep_max_probs{$peps[$k]}}{$prot}) for $prot\n" if($verbose && ${$pep_wts{$peps[$k]}}{$prot} >= $min_wt &&
	                           ${$pep_max_probs{$peps[$k]}}{$prot} >= $min_prob);
}
print STDERR "min wt: $min_wt, min prob: $min_prob\n" if($verbose);
return sort @s_peps;
}


sub isSubOrSuperset2 {
(my $firstprot, my $firstptr, my $secondprot, my $secondptr, my $use_ntt_info) = @_;
return 0 if(scalar @{$firstptr} ==  scalar @{$secondptr});
return 0 if(scalar @{$firstptr} ==  0 || scalar @{$secondptr} ==  0);
print STDERR "still here with ", scalar @{$firstptr}, " first and ", scalar @{$secondptr}, " second\n" if($use_ntt_info == 2);
if(scalar @{$firstptr} >  scalar @{$secondptr}) {
    for(my $k = 0; $k < @{$secondptr}; $k++) {
	my $found = 0;
	for(my $j = 0; $j < @{$firstptr}; $j++) {
	    if(${$secondptr}[$k] eq ${$firstptr}[$j] && (! $use_ntt_info ||
	       ${$pep_prob_ind{${$secondptr}[$k]}}{$secondprot} eq  ${$pep_prob_ind{${$firstptr}[$j]}}{$firstprot})) {
		$found = 1;
		$j = @{$firstptr};
	    }
	} # next second
	return 0 if(! $found);
    } # next first
    return 1;
}
else {
    for(my $k = 0; $k < @{$firstptr}; $k++) {
	my $found = 0;
	print STDERR "$firstprot=>${$firstptr}[$k] (${$pep_prob_ind{${$firstptr}[$k]}}{$firstprot}): " if($use_ntt_info == 2);
	print STDERR "[ind ${$firstptr}[$k]} $firstprot ${$pep_prob_ind{${$firstptr}[$k]}}{$firstprot}] "if($use_ntt_info == 2);
	for(my $j = 0; $j < @{$secondptr}; $j++) {

	    print STDERR "$secondprot=>${$secondptr}[$j] (${$pep_prob_ind{${$secondptr}[$j]}}{$secondprot}): " if($use_ntt_info == 2);
	    print STDERR "[ind ${$secondptr}[$j]} $secondprot ${$pep_prob_ind{${$secondptr}[$j]}}{$secondprot}] " if($use_ntt_info == 2);
	    if(${$firstptr}[$k] eq ${$secondptr}[$j] && 
	       ${$pep_prob_ind{${$firstptr}[$k]}}{$firstprot} eq  ${$pep_prob_ind{${$secondptr}[$j]}}{$secondprot}) {
		$found = 1;
		$j = @{$secondptr};
	    }
	} # next second
	print STDERR "$found\n" if($use_ntt_info == 2);
	
	return 0 if(! $found);
    } # next first
    return -1;
}
return 0;

}

sub equalList {
(my $firstptr, my $secondptr) = @_;
return 0 if(scalar @{$firstptr} ==  0 || scalar @{$secondptr} == 0);
return 0 if(scalar @{$firstptr} != scalar @{$secondptr});
for(my $k = 0; $k < @{$firstptr}; $k++) {
    return 0 if(! (${$firstptr}[$k] eq ${$secondptr}[$k]));
}
return 1;
}

# this one requires that all peptides have same ntt with respect to their protein
sub equalList2 {
(my $firstprot, my $firstptr, my $secondprot, my $secondptr) = @_;
return 0 if(scalar @{$firstptr} ==  0 || scalar @{$secondptr} == 0);
return 0 if(scalar @{$firstptr} != scalar @{$secondptr});
for(my $k = 0; $k < @{$firstptr}; $k++) {
    return 0 if(! (${$firstptr}[$k] eq ${$secondptr}[$k]));
    return 0 if(! (${$pep_prob_ind{${$firstptr}[$k]}}{$firstprot} eq  ${$pep_prob_ind{${$secondptr}[$k]}}{$secondprot}));
}
return 1;
}


sub findDegenGroups3 {
(my $min_wt, my $min_prob, my $use_ntt_info) = @_;
my @prots;
my $num;

my $verbose;
my $orig_min_prob = $min_prob;

%degen = ();
%member = (); # hash by protein pointer to hash of prots in group
my $cluster;
my @last_peps = ();
my $subsumed;
my %included;
my $newverbose = 0;
my @sign_peps;
# go through all proteins looking for those with no independent evidence
foreach(sort keys %prot_peps) {
    #$verbose = /215894/;
    $num = 0;
    $min_prob = $orig_min_prob;
    print STDERR "here with protein $_...\n" if($verbose);
    if($MERGE_SUBSETS) {
	$subsumed = '';
	%included = ();
    }
    if(! exists $member{$_}) {
	$cluster = $_;
	@sign_peps = getOrderedSignPeps($_, $min_wt, $min_prob);
	while(@sign_peps == 0 && $min_prob > 0) {
	    $min_prob -= 0.1;
		@sign_peps = getOrderedSignPeps($_, $min_wt, $min_prob);
	    }

	for(my $k = 0; $k < @sign_peps; $k++) {
	    print STDERR "got $sign_peps[$k] for $_...\n" if($verbose);
	    my @new_prots = sort keys %{$pep_nsp{$sign_peps[$k]}};
	    for(my $j = 0; $j < @new_prots; $j++) {

		$newverbose = 0; # $_ =~ /IPI00140449/ || $new_prots[$j] =~ /IPI00140449/;
		print STDERR "$_ with $new_prots[$j]\n" if($newverbose);
		$verbose = 0; #$_ =~ /32328/ && $new_prots[$j] =~ /215894/;
		print STDERR "here with $new_prots[$j] --- \n" if($verbose);
		if(! ($_ eq $new_prots[$j]) && ! exists $member{$new_prots[$j]} && ! exists $degen{$new_prots[$j]}) {
		    my @new_peps = getOrderedSignPeps($new_prots[$j], $min_wt, $min_prob);
		    if($verbose) {
			print "got ", scalar @new_peps, " peps for $new_prots[$j]\n";
		    }

		    if($verbose) {
			print STDERR "peptides for $_:\n";
			for(my $a = 0; $a < @sign_peps; $a++) {
			    print STDERR "$sign_peps[$a] ";
			}
			print STDERR "\n";
			    print STDERR "peptides for $new_prots[$j]:\n";
			    for(my $a = 0; $a < @new_peps; $a++) {
				print STDERR "$new_peps[$a] ";
			    }
			    print STDERR "\n";

			}

			if(  (! $use_ntt_info && equalList(\@sign_peps, \@new_peps)) || 
			     ($use_ntt_info && equalList2($_, \@sign_peps, $new_prots[$j], \@new_peps))) {

			    # add the members......
			    $cluster .= ' ' . $new_prots[$j];
			    $num++;
			    $member{$new_prots[$j]}++;
			    print "adding $new_prots[$j] to member list $cluster\n" if($verbose);
                    
			    @last_peps = @new_peps;
			    if($verbose) {
				print STDERR "%%%%\t$_ vs $new_prots[$j]: \n";
				for(my $s = 0; $s < @sign_peps; $s++) {
				    print STDERR "$sign_peps[$s] ";
				}
				print STDERR "\n";
				for(my $s = 0; $s < @new_peps; $s++) {
				    print STDERR "$new_peps[$s] ";
				}
				print STDERR "\n\n";
			    }
			    if($MERGE_SUBSETS && ! ($new_prots[$j] eq $subsumed)) {
				if($newverbose) {
				    print "1: $new_prots[$j] subsumed by $subsumed\n";
				}
				$included{$new_prots[$j]}++;
			    }

			} # if equal lists
		    elsif($MERGE_SUBSETS && $subsumed eq '') { # not equal
			    my $result = isSubOrSuperset2($_, \@sign_peps, $new_prots[$j], \@new_peps, $use_ntt_info);
			    print STDERR "Comparison results between $_ and $new_prots[$j]: $result\n" if($verbose);
			    if($result == -1) { # first is subset of second, set first to 0 prob, give wts to second
				if($newverbose) {
				    print STDERR "2: $_ subsumed by $new_prots[$j]\n";
				    for(my $z = 0; $z < @sign_peps; $z++) {
					print STDERR "$sign_peps[$z] ";
				    }
				    print STDERR "\n";
				    for(my $z = 0; $z < @new_peps; $z++) {
					print STDERR "$new_peps[$z] ";
				    }
				    print STDERR "\n";


				}
				# climb up the tree as far as relevant for $_
				my $parent = $new_prots[$j];
				my $done = 0;
				while(! $done && exists $subsumed{$parent}) { 
				    my @parent_peps = getOrderedSignPeps($subsumed{$parent}, $min_wt, $min_prob);
				    if(isSubOrSuperset2($_, \@sign_peps, $subsumed{$parent}, \@parent_peps) == -1) {
					$parent = $subsumed{$parent};
				    }
				    else {
					$done = 1;
				    }

				}
				$subsumed = $parent;

				$included{$_}++;
			    }
			}
		    elsif($verbose) {
			print "subsumed: $subsumed\n";

		    }
		} # if merge subsets
		elsif($MERGE_SUBSETS && $subsumed eq '' && exists $degen{$new_prots[$j]}) {
		    my @new_peps = getOrderedSignPeps($new_prots[$j], $min_wt, $min_prob);
		    if($newverbose) {
			print "got ", scalar @new_peps, " peps for $new_prots[$j]\n";
		    }

		    if($verbose) {
			print STDERR "peptides for $_:\n";
			for(my $a = 0; $a < @sign_peps; $a++) {
			    print STDERR "$sign_peps[$a] ";
			}
			print STDERR "\n";
			print STDERR "peptides for $new_prots[$j]:\n";
			for(my $a = 0; $a < @new_peps; $a++) {
			    print STDERR "$new_peps[$a] ";
			}
			print STDERR "\n";

		    }
		    my $result = isSubOrSuperset2($_, \@sign_peps, $new_prots[$j], \@new_peps, $use_ntt_info);
		    print STDERR "Comparison results between $_ and $new_prots[$j]: $result\n" if($verbose);
		    if($verbose) {
			for(my $z = 0; $z < @sign_peps; $z++) {
			    print STDERR "$sign_peps[$z] ";
			}
			print STDERR "\n";
			for(my $z = 0; $z < @new_peps; $z++) {
			    print STDERR "$new_peps[$z] ";
			}
			print STDERR "\n";
			
		    }
		    if($result == -1) { # first is subset of second, set first to 0 prob, give wts to second
			if($newverbose) {
			    print "3: $_ subsumed by $new_prots[$j]\n";
			}
			my $parent = $new_prots[$j];

			# go as high up family tree as warranted
			my $done = 0;
			while(! $done && exists $subsumed{$parent}) { 
			    my @parent_peps = getOrderedSignPeps($subsumed{$parent}, $min_wt, $min_prob);
			    if(isSubOrSuperset2($_, \@sign_peps, $subsumed{$parent}, \@parent_peps) == -1) {
				$parent = $subsumed{$parent};
			    }
			    else {
				$done = 1;
			    }
			}

			$subsumed = $parent;
			$included{$_}++;
		    }
		}
	    } # next new prot
	} # next new pep
    } # if not already examined
	if($num > 0) {
	
		# sort individual IPI names in cluster string into ascending order
		my @cluster_prots = split( ' ', $cluster );
		my @new_cluster = sort { $a cmp $b } @cluster_prots;
		$cluster = join( ' ', @new_cluster );
		#
		 
	    $member{$_}++; # add self
        print STDERR "adding $_ to member list "  if($newverbose);
	    $degen{$cluster}++;  # new cluster
	    print STDERR "\nhave new cluster: $cluster\n" if($verbose);

	    if($MERGE_SUBSETS) {
		$subsumed{$cluster} = $subsumed if(! ($subsumed eq ''));
		# might have to go through all preveious subsume targets and redirect them to $subsumed
		my @previous = sort keys %subsumed;
		for(my $p = 0; $p < @previous; $p++) {
		    if(exists $subsumed{$previous[$p]} && exists $included{$subsumed{$previous[$p]}}) {
			if($newverbose) {
			    print STDERR "Redirecting $previous[$p] from $subsumed{$previous[$p]} to $subsumed\n";
			}
			$subsumed{$previous[$p]} = $subsumed eq '' ? $cluster : $subsumed;
		    }
		}

	    }




	    # add on low prob peptides that are shared among them all
            @last_peps = @{getAllSharedPeptides($cluster)};

	    for(my $m = 0; $m < @last_peps; $m++) {

		${$prot_peps{$cluster}}{$last_peps[$m]}++;
	        ${$pep_wts{$last_peps[$m]}}{$cluster} = 
		    ($MERGE_SUBSETS && exists $subsumed{$cluster}) ? 0.0 : getDegenWt($cluster, $last_peps[$m]); # set wt to 1
	my $verb = 0; #$last_peps[$m] eq '3_NLAFFSTNCVEGTAR' || $cluster =~ /SW\:A1A1\_HUMAN/;

		# NSP VALUE HERE....
		${$estNSP{$last_peps[$m]}}{$cluster} = ${$estNSP{$last_peps[$m]}}{$_} * ($num + 1) * ${$pep_wts{$last_peps[$m]}}{$cluster};
		${$pep_nsp{$last_peps[$m]}}{$cluster} = getSharedProtIndex(${$estNSP{$last_peps[$m]}}{$cluster});
		${$pep_max_probs{$last_peps[$m]}}{$cluster} = getNSPAdjustedProb(${$orig_pep_max_probs{$last_peps[$m]}}{$_}, 
									    ${$pep_nsp{$last_peps[$m]}}{$cluster});


		${$pep_prob_ind{$last_peps[$m]}}{$cluster} = ${$pep_prob_ind{$last_peps[$m]}}{$_};
		if(0 && $cluster =~ /86909/) {
		    print STDERR "setting ind for $last_peps[$m] of $cluster to ${$pep_prob_ind{$last_peps[$m]}}{$_}\n";
		    print STDERR "$last_peps[$m] $cluster ${$pep_prob_ind{$last_peps[$m]}}{$cluster}\n";
		}

	        ${$orig_pep_wts{$last_peps[$m]}}{$cluster} = ${$pep_wts{$last_peps[$m]}}{$cluster}; #
printf "yeah, setting wt for $last_peps[$m] to $cluster at %0.2f\n", ${$orig_pep_wts{$last_peps[$m]}}{$cluster} if($verb);
                # reset all other proteins with shared peptides to that cluster
	        my @other_prots = sort keys %{$pep_wts{$last_peps[$m]}};
	        for(my $other_p = 0; $other_p < @other_prots; $other_p++) {
	             ${$pep_wts{$last_peps[$m]}}{$other_prots[$other_p]} = ${$orig_pep_wts{$last_peps[$m]}}{$other_prots[$other_p]};
printf "\tresetting wt for $last_peps[$m] to $other_prots[$other_p] to %0.2f\n", ${$pep_wts{$last_peps[$m]}}{$other_prots[$other_p]} if($verb);
                }

	    }
	} # if num > 0


    if($MERGE_SUBSETS && ! ($subsumed eq '')) { # do the trasfers
	my @included = sort keys %included;
		for(my $in = 0; $in < @included; $in++) {
		    my @all_sign_peps = getOrderedSignPeps($included[$in], 0.0, 0.0); # get everything

		    if($newverbose) {
			print STDERR "4: $included[$in] subsumed by $subsumed\n";

		    }
		    for(my $i = 0; $i < @all_sign_peps; $i++) {
			if(exists ${$pep_wts{$all_sign_peps[$i]}}{$subsumed}) {
			    ${$pep_wts{$all_sign_peps[$i]}}{$subsumed} += ${$pep_wts{$all_sign_peps[$i]}}{$included[$in]}; # BSP this was "+= ${$pep_wts{$sign_peps[$i]}}{$included[$in]}"
			    ${$pep_wts{$all_sign_peps[$i]}}{$subsumed} = 1.0 if(${$pep_wts{$all_sign_peps[$i]}}{$subsumed} > 1.0);
			}
			${$pep_wts{$all_sign_peps[$i]}}{$included[$in]} = 0.0;
			if(exists ${$orig_pep_wts{$all_sign_peps[$i]}}{$subsumed}) {
			    ${$orig_pep_wts{$all_sign_peps[$i]}}{$subsumed} += ${$orig_pep_wts{$all_sign_peps[$i]}}{$included[$in]};
			    ${$orig_pep_wts{$all_sign_peps[$i]}}{$subsumed} = 1.0 if(${$orig_pep_wts{$all_sign_peps[$i]}}{$subsumed} > 1.0);
			}
			${$orig_pep_wts{$all_sign_peps[$i]}}{$included[$in]} = 0.0;
		    } # next pep

		} # next included prot
		    if($newverbose) {
			print STDERR "\n";
		    }
	$subsumed{$_} = $subsumed;
	# update any references to $_
	my @presubsumed = sort keys %subsumed;
	for(my $z = 0; $z < @presubsumed; $z++) {
	    $subsumed{$presubsumed[$z]} = $subsumed if($subsumed{$presubsumed[$z]} eq $_);
	}

    }


} # next protein

}


sub getDegenWt {
(my $name, my $pep) = @_;
return 1 if(! $OCCAM);
my @prots = split(' ', $name);
my $tot = 0;
foreach(@prots) {
    $tot += ${$orig_pep_wts{$pep}}{$_};
}
return $tot;
}


sub computeDegenWts {
    my @peps = keys %pep_wts;
    foreach(@peps) {
	my @prots = keys %{$pep_wts{$_}};
	my $have_cluster = 0;

	for(my $k = 0; $k < @prots; $k++) {
	    if($degen{$prots[$k]}) {
		$have_cluster += split(' ', $prots[$k]); # add the number of cluster members
		# $k = @prots; BSP/ADK : why is this here? need to consider all degen proteins, not just the first in hash
	    }
	} # next prot
	if($have_cluster & @prots - $have_cluster > 0) { # recompute wts
	    for(my $k = 0; $k < @prots; $k++) {
		${$pep_wts{$_}}{$prots[$k]} = 1.0 / (@prots - $have_cluster);
	    } 
	}


    } # next pep

}




sub computeDegenProtProb{
(my $name) = @_;
my $VERBOSE = 0; 
my @members = split(' ', $name);
return 0 if(@members == 0);

my @peps = sort keys %{$prot_peps{$name}};
my $prob = 1;
my $nextprob;
my $next_nsp;

foreach(@peps) {
    print "pep $_\n" if($VERBOSE);
    $nextprob = 1;
    $next_nsp = 0;

    my $tot_wt = 0;
    my $tot_max = 0;
    my $orig_tot_max = 0;  # compute the average max prob for peptide with respect to each member protein
    for(my $k = 0; $k < @members; $k++) {

	if($VERBOSE) {
	    print STDERR "$_ to $members[$k]: ${$pep_max_probs{$_}}{$members[$k]}, ${$pep_wts{$_}}{$members[$k]}, ${$orig_pep_max_probs{$_}}{$members[$k]}, nsp: ${$pep_nsp{$_}}{$members[$k]}\n";
	    $DEBUG = 1;
            print "of...", getNSPAdjustedProb(${$orig_pep_max_probs{$_}}{$members[$k]}, ${$pep_nsp{$_}}{$members[$k]}), "\n";
           $DEBUG = 0;
	}
	$tot_max += ${$pep_max_probs{$_}}{$members[$k]} / @members;
	$orig_tot_max += ${$orig_pep_max_probs{$_}}{$members[$k]} / @members;
        $tot_wt += ${$pep_wts{$_}}{$members[$k]} if(! exists ${$pep_wts{$_}}{$name});
	$nextprob -= ${$pep_max_probs{$_}}{$members[$k]} * ${$pep_wts{$_}}{$members[$k]};
        $next_nsp += ${$pep_nsp{$_}}{$members[$k]} * ${$pep_wts{$_}}{$members[$k]};
    }
    ${$pep_max_probs{$_}}{$name} = $tot_max if(! exists ${$pep_max_probs{$_}}{$name}); 
    ${$orig_pep_max_probs{$_}}{$name} = $orig_tot_max if(! exists ${$orig_pep_max_probs{$_}}{$name}); 

	if($VERBOSE) {
	    print STDERR "total: ${$pep_max_probs{$_}}{$name} ${$orig_pep_max_probs{$_}}{$name}\n";
	}
    print STDERR "totals for $_: $tot_max, $orig_tot_max\n" if($VERBOSE);
printf "computeDegenProtProb for $name: $_ max prob: %0.2f, wt: %0.2f\n", ${$pep_max_probs{$_}}{$name}, ${$pep_wts{$_}}{$name} if($VERBOSE);

    ${$pep_wts{$_}}{$name} = $tot_wt if(! exists ${$pep_wts{$_}}{$name});
print STDERR "wt for $_ on $name: ${$pep_wts{$_}}{$name}, next_nsp: $next_nsp\n" if($VERBOSE);
    $prob *= (1 - ${$pep_max_probs{$_}}{$name} * ${$pep_wts{$_}}{$name}) if(${$pep_wts{$_}}{$name} >= $MIN_WT && ${             $pep_max_probs{$_}}{$name} >= $MIN_PROB);
    $nextprob = 0 if($nextprob < 0); # just in case of roundoff

    if($OCCAM) {
	${$pep_nsp{$_}}{$name} = ${$pep_wts{$_}}{$name} > 0 ? $next_nsp / ${$pep_wts{$_}}{$name} : 0 if(! exists ${$pep_nsp{$_}}{$name});
    }
    else {
	${$pep_nsp{$_}}{$name} = $tot_wt > 0 ? $next_nsp / $tot_wt : 0 if(! exists ${$pep_nsp{$_}}{$name});
    }
    print STDERR "$_ to $name: nsp: ${$pep_nsp{$_}}{$name}\n" if($VERBOSE);

} # next peptide

print STDERR "*** $name: ", 1-$prob, "\n" if($VERBOSE);
return (1 - $prob);
}

sub strip {
(my $pep) = @_;
my $output = '';
my $next;
for(my $k = 0; $k < length $pep; $k++) {
    $next = substr($pep, $k, 1);
    $output .= $next if($next =~ /[A-Z]/);
}
return $output;
}


sub getPeptideCGITag {
(my $pep, my $totlength) = @_;
# get the originial....
my $COLOR_MISSED_CL = (scalar (keys %ENZYMES)) == 1 ? 1 : 0;
my $COLOR_ICAT = $ICAT;

(my $modified_pep = $pep) =~ s/\#/p/g;  # substitute pound signs (since make trouble as html tags)
my $html_lead = '<A TARGET="Win1" HREF="' . $CGI_HOME . 'peptide_html.pl?Ref=';
my $html_mid = '&amp;Infile=' . join('+', @cgifiles) . '">';
my $html_final = '</A>';
for(my $k = 0; $k < $totlength - (length $pep); $k++) {
    $html_final .= ' ';
}
if($COLOR_ICAT) {
    $pep =~ s/C/\<FONT color\=\"\#DD00DD\"\>C\<\/FONT\>/g; # 
    $pep =~ s/\<\/FONT\>\*/\*\<\/FONT\>/g; # do heavy '*; also
}

# color modifications
$pep =~ s/([A-Z]\*)/\<FONT color\=\"\#DD00DD\"\>$1\<\/FONT\>/g; 
$pep =~ s/([A-Z]\#)/\<FONT color\=\"\#DD00DD\"\>$1\<\/FONT\>/g; 
$pep =~ s/([A-Z]\@)/\<FONT color\=\"\#DD00DD\"\>$1\<\/FONT\>/g; 



if($COLOR_MISSED_CL) {

    $pep =~ s/R/\<FONT color\=\"\#00C6FF\"\>R\<\/FONT\>/g if(exists $ENZYMES{'tryptic'}); # light blue
    $pep =~ s/K/\<FONT color\=\"\#00C6FF\"\>K\<\/FONT\>/g if(exists $ENZYMES{'tryptic'}); # light blue
    $pep =~ s/E/\<FONT color\=\"\#00C6FF\"\>E\<\/FONT\>/g if(exists $ENZYMES{'gluC'} || exists $ENZYMES{'gluC_bicarb'}); # light blue
    $pep =~ s/D/\<FONT color\=\"\#00C6FF\"\>D\<\/FONT\>/g if(exists $ENZYMES{'gluC'}); # light blue


    if(exists $ENZYMES{'chymotryptic'}) {
	$pep =~ s/F/\<FONT color\=\"\#00C6FF\"\>F\<\/FONT\>/g; # light blue
	$pep =~ s/Y/\<FONT color\=\"\#00C6FF\"\>Y\<\/FONT\>/g; # light blue
	$pep =~ s/W/\<FONT color\=\"\#00C6FF\"\>W\<\/FONT\>/g; # light blue
	$pep =~ s/M/\<FONT color\=\"\#00C6FF\"\>M\<\/FONT\>/g; # light blue
    } # chymo
    elsif(exists $ENZYMES{'elastase'}) {
	$pep =~ s/G/\<FONT color\=\"\#00C6FF\"\>G\<\/FONT\>/g; # light blue
	$pep =~ s/V/\<FONT color\=\"\#00C6FF\"\>V\<\/FONT\>/g; # light blue
	$pep =~ s/L/\<FONT color\=\"\#00C6FF\"\>L\<\/FONT\>/g; # light blue
	$pep =~ s/I/\<FONT color\=\"\#00C6FF\"\>I\<\/FONT\>/g; # light blue
	$pep =~ s/A/\<FONT color\=\"\#00C6FF\"\>A\<\/FONT\>/g; # light blue
    }
    elsif(exists $ENZYMES{'CNBr'}) {
	$pep =~ s/M([\#,\@,\*]?)/\<FONT color\=\"\#00C6FF\"\>M\1\<\/FONT\>/g; # light blue
    }
    elsif(exists $ENZYMES{'AspN'}) {
	$pep =~ s/D([\#,\@,\*]?)/\<FONT color\=\"\#00C6FF\"\>D\1\<\/FONT\>/g; # light blue
	$pep =~ s/E([\#,\@,\*]?)/\<FONT color\=\"\#00C6FF\"\>\1\<\/FONT\>/g; # light blue
    }
}
if($GLYC) {
    $pep =~ s/N([\#,\@,\*]?[A-O,Q-Z])T/\<FONT color\=\"\#DD00DD\"\>N\1T\<\/FONT\>/g; # motifs with or w/o modified N
    $pep =~ s/N([\#,\@,\*]?[A-O,Q-Z])S/\<FONT color\=\"\#DD00DD\"\>N\1S\<\/FONT\>/g;
    $pep =~ s/N([\#,\@,\*]?[A-O,Q-Z][\#,\@,\*])T/\<FONT color\=\"\#DD00DD\"\>N\1T\<\/FONT\>/g; # modified internal aa
    $pep =~ s/N([\#,\@,\*]?[A-O,Q-Z][\#,\@,\*])S/\<FONT color\=\"\#DD00DD\"\>N\1S\<\/FONT\>/g;
}

return $html_lead . $modified_pep . $html_mid . $pep . $html_final;
}

sub getWeightCGITag {
(my $prot, my $pep, my $pepptr) = @_;
my $counter = 1;
my @temp = split(' ', $prot);
my $altered_prot = join('+', @temp);
my $altered_pep = '';
if(! $pepptr) {
    $altered_pep = $pep;
}
else {

    for(my $p = 0; $p < @{$pepptr}; $p++) {
	$altered_pep .= ${$pepptr}[$p];
	$altered_pep .= '+' if($p < @{$pepptr} - 1);
    }
}
$altered_pep =~ s/\#/\p/g;

my $output = '<A TARGET="Win1" HREF="' . $CGI_HOME . 'prot_wt_html.pl?Prot=' . $altered_prot . '&amp;Db=' . $database . '&amp;Pep=' . $altered_pep . '&amp;Me=' . $OUTFILE . '&amp;';

if( $WINDOWS_CYGWIN) {
    my $local_htmlfile = $OUTFILE;
    if((length $SERVER_ROOT) <= (length $local_htmlfile) && 
       index((lc $local_htmlfile), (lc $SERVER_ROOT)) == 0) {
	$local_htmlfile = '/' . substr($local_htmlfile, (length $SERVER_ROOT));
    }
    else {
	die "problem: $local_htmlfile is not mounted under webserver root: $SERVER_ROOT\n";
    }
    $output .= 'local_html=' . $local_htmlfile . '&amp;';
}

foreach(sort keys %{$pep_wts{$pep}}) {
    if(exists $degen{$_} || (! exists $member{$_})) {
        my $prot;
	if(exists $degen{$_}) {
	    my @prots = split(' ');
	    $prot = join('+', @prots);
	}
	else {
	    $prot = $_;
	}
	$output .= 'Wt' . $counter . '=' . ${$pep_wts{$pep}}{$_} . '&amp;Prot' . $counter . '=' . $prot . '&amp;';
	$counter++;
    } # if
}
$output .= 'Num=' . ($counter-1) . '">';
return $output;
}


sub getDegenWts2 {
(my $name, my $pepptr, my $protprob, my $grp) = @_;
my $html_lead = '<A TARGET="Win1" HREF="' . $CGI_HOME . 'comet-fastadb.cgi?Ref='; #'consensus_html4?Ref=';
my $html_mid1 = '&amp;Db=' . $database . '&amp;Pep=';
my $html_mid2 = '">'; 
my $html_final = '</A>';
my %peps = ();


my $explorer_color_pre = ''; # <font color="#0000FF">
my $explorer_color_suf = ''; # </font>

my $verbose = 0; #$name =~ /230594$/;

foreach(@{$pepptr}) {
    my @equivs;
    if(exists $equivalent_peps{$_}) {
	@equivs = sort keys %{$equivalent_peps{$_}};
    }
    else {
	@equivs = ($_);
    }
    for(my $k = 0; $k < @equivs; $k++) {
	if($equivs[$k] =~ /\d\_(\S+)$/) {
	    $peps{strip($1)}++;
       } 
   }
}
if($verbose) {
    foreach(sort keys %peps) {
	print STDERR "$_: $peps{$_}\n";
    }
    print STDERR "\n";
    print STDERR "peps: ", join('+', sort keys %peps), "\n";
}

my $output_tag = '';
my $color = 0;
my $color_pre = '<font color="red">';
my $color_aft = '</font>';
if(! exists $degen{$name}) {
    my $nextprot = $name;
    if($COLOR_CORRECTS && getClass($nextprot)) {
	$color = 1;
    }

    if($IPI_DATABASE) { 
	if($name =~ /^IPI\:(IPI\S+)(\.\d)$/) {
	    
	    my $nextprot = $1 . $2;
	    if($COLOR_CORRECTS && getClass($nextprot)) {
		$nextprot = '<font color="red">' . $nextprot . '</font>';
	    }

	    my $next_annot;
	    if($E_EXPLORE) {
		$next_annot = getAnnotation($name, $database, 0);
		if($next_annot =~ /ENSEMBL\:(\S+)\s+/) {

		    $output_tag .= "<a TARGET=\"Win1\" href=\"" . $E_EXPLORER_PRE . $E_EXPLORER_MID . $E_EXPLORER_SUF . $1 . "\">E</a> ";
		}
	    }

	    $output_tag .= "<a TARGET=\"Win1\" href=\"$IPI_EXPLORER_PRE$1$IPI_EXPLORER_SUF\">$explorer_color_pre" . "IPI$explorer_color_suf</a> ";

	    if($color) {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $1 . $2 . $color_aft . $html_final;
	    }
	    else {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $1 . $2 . $html_final;
	    }

	}
	elsif($name =~ /^(IPI\S+)$/) {
	    my $nextprot = $name;
	    if($COLOR_CORRECTS && getClass($nextprot)) {
		$nextprot = '<font color="red">' . $nextprot . '</font>';
	    }

	    my $next_annot;
	    if($E_EXPLORE) {
		$next_annot = getAnnotation($name, $database, 0);
		if($next_annot =~ /ENSEMBL\:(\S+)\s+/) {
		    $output_tag .= "<a TARGET=\"Win1\" href=\"" . $E_EXPLORER_PRE . $E_EXPLORER_MID . $E_EXPLORER_SUF . $1 . "\">E</a> ";
		}
	    }

	    $output_tag .= "<a TARGET=\"Win1\" href=\"$IPI_EXPLORER_PRE$1$IPI_EXPLORER_SUF\">$explorer_color_pre" . "IPI$explorer_color_suf</a> ";

	    if($color) {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $name . $color_aft . $html_final;
	    }
	    else {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $name . $html_final;
	    }
	}
	else {
	    if($color) {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $name . $color_aft . $html_final;
	    }
	    else {
		$output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $name . $html_final;
	    }

	}
    }
    else {
	if($color) {
	    $output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $name . $color_aft . $html_final;

	}
	else {
	    $output_tag .= $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $name . $html_final;
	}
    }
    print STDERR "output tag: $output_tag\n" if($verbose);
    return $output_tag; 
    return $html_lead . $name . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $name . $html_final;
    return $name;
}
my @prots = split(' ', $name);
my $output = '';
my $start = 1;
my $num_per_line = 7;
for(my $k = 0; $k < @prots; $k++) {

    $output .= ' ' if(! $start && $k%$num_per_line != 0);
    $start = 0;

    $color = 0;
    if($COLOR_CORRECTS && getClass($prots[$k])) {
	$color = 1;
    }
    if($IPI_DATABASE) {
	if($prots[$k] =~ /^IPI\:(IPI\S+)(\.\d)$/) {
	    my $next_annot;
	    if($E_EXPLORE) {
		$next_annot = getAnnotation($name, $database, 0);
		if($next_annot =~ /ENSEMBL\:(\S+)\s+/) {
		    $output .= "<a TARGET=\"Win1\" href=\"" . $E_EXPLORER_PRE . $E_EXPLORER_MID . $E_EXPLORER_SUF . $1 . "\">E</a> ";
		}
	    }

	    if($color) {
		$output .= $html_lead . $prots[$k] . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $1 . $2 . $color_aft . $html_final;

	    }
	    else {
		$output .= $html_lead . $prots[$k] . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $1 . $2 . $html_final;
	    }
	}
	elsif($prots[$k] =~ /^(IPI\S+)$/) {
	    my $next_annot;
	    if($E_EXPLORE) {
		$next_annot = getAnnotation($name, $database, 0);
		if($next_annot =~ /ENSEMBL\:(\S+)\s+/) {
		    $output .= "<a TARGET=\"Win1\" href=\"" . $E_EXPLORER_PRE . $E_EXPLORER_MID . $E_EXPLORER_SUF . $1 . "\">E</a> ";
		}
	    }


	    $output .= "<a TARGET=\"Win1\" href=\"$IPI_EXPLORER_PRE$1$IPI_EXPLORER_SUF\">$explorer_color_pre" . "IPI$explorer_color_suf</a> ";

	    if($color) {
		$output .= $html_lead . $prots[$k] . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $1 . $color_aft . $html_final;

	    }
	    else {
		$output .= $html_lead . $prots[$k] . $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $1 . $html_final;
	    }
	}
	else {
	    $output .= " <a TARGET=\"Win1\" href=\"$IPI_EXPLORER_PRE$name$IPI_EXPLORER_SUF\">$explorer_color_pre" . "IPI$explorer_color_suf</a> ";
	}
    }
    else {


	$output .= $html_lead;
	$output .= $prots[$k];
	if($color) {
	    $output .= $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $color_pre . $prots[$k] . $color_aft . $html_final;

	}
	else {
	    $output .= $html_mid1 . join('+', sort keys %peps) . $html_mid2 . $prots[$k] . $html_final;
	}
    }
    $output .= ' ' if($k < @prots - 1);

    if(($k+1)%$num_per_line == 0 && $k < @prots - 1) {
	$output .= "<!-- Prob=$protprob --><p>";
	$output .= '|' if($grp);
	$output .= "\t";
    }

}
return $output;
}

sub findCommonPeps {
    (my $pepptr) = @_;
    my %inds = ();
    my $char = 'a';
    for(my $k = 0; $k < scalar @{$pepptr}; $k++) {
	for(my $j = 0; $j < $k; $j++) {
	    if(substr(${$pepptr}[$k], 2) eq substr(${$pepptr}[$j], 2)) {
	        if(exists $inds{${$pepptr}[$k]}) {
                    $inds{${$pepptr}[$j]} = $inds{${$pepptr}[$k]};
                }
                elsif(exists $inds{${$pepptr}[$j]}) {
                    $inds{${$pepptr}[$k]} = $inds{${$pepptr}[$j]};
                }
                else {
	            $inds{${$pepptr}[$k]} = $char;
	            $inds{${$pepptr}[$j]} = $char;
                    $char++;
                 }
             } # if equal peptides (other than charge)
        } #next pep j
    } # next pep k
return \%inds;
}

sub numInstancesPeptide {
(my $pep, my $prot, my $min_prob, my $use_nsp) = @_;
my $charge = substr($pep, 0, 1);
my $num = 0;
my $verbose = 0; #$pep =~ /VNQLGSVTESLQAC/ && $charge == 3;


if($verbose) {
    print STDERR "peptide: $pep for prot $prot\n";
}
if($charge eq '1') {
    print STDERR "  $min_prob min prob, $pep: " if($verbose);
    foreach(@singly_spectra) {
	$num++ if($singly_specpeps{$_} eq $pep && (
            (! $use_nsp && ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep}}{$prot}] >= $min_prob) ||
	    ($use_nsp && getNSPAdjustedProb(
                                    ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep}}{$prot}],
		                    ${$pep_nsp{$pep}}{$prot}) 
                          >= $min_prob) 
            ));
        printf STDERR "\n$_: %0.2f (%0.2f %d %d)", getNSPAdjustedProb(
                                    ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep}}{$prot}],
                                    ${$pep_nsp{$pep}}{$prot}), 
                                    ${$pep_prob_ind{$pep}}{$prot}, 
                                    ${$singly_specprobs{$_}}[${$pep_prob_ind{$pep}}{$prot}],
		                    ${$pep_nsp{$pep}}{$prot}  if($singly_specpeps{$_} eq $pep && $verbose);
    }
print STDERR "\nTOT: $num\n\n" if($verbose);
}
elsif($charge eq '2') {
    foreach(@spectra) {
	$num++ if(${$specpeps{$_}}[0] eq $pep && (
	    (! $use_nsp && ${${$specprobs{$_}}[0]}[${$pep_prob_ind{$pep}}{$prot}] >= $min_prob) ||
	    ($use_nsp && getNSPAdjustedProb(${${$specprobs{$_}}[0]}[${$pep_prob_ind{$pep}}{$prot}],
		${$pep_nsp{$pep}}{$prot}) >= $min_prob)
         ));
    }
}
elsif($charge eq '3') {
    foreach(@spectra) {
	if($verbose && (/media11A.1810.1810/ || /media11.0764.0764/)) {
	    print STDERR "$_ pep: ${$specpeps{$_}}[1] with prob: ${${$specprobs{$_}}[1]}[${$pep_prob_ind{$pep}}{$prot}]\n";
	}
	$num++ if(${$specpeps{$_}}[1] eq $pep && (
	    (! $use_nsp && ${${$specprobs{$_}}[1]}[${$pep_prob_ind{$pep}}{$prot}] >= $min_prob) ||
	    ($use_nsp && getNSPAdjustedProb(${${$specprobs{$_}}[1]}[${$pep_prob_ind{$pep}}{$prot}],
		${$pep_nsp{$pep}}{$prot}) >= $min_prob)
         ));
    }
}
else {
    die "error with charge $charge\n";
}
print STDERR "returning $num\n" if($verbose);
return $num;

}

sub getNumberDegenProteins {
(my $pep) = @_;
my $verbose = 0; #$pep =~ /2\_ALEM\*GVFGAYFNVLLNLR/;
my @prots = sort keys %{$pep_wts{$pep}};
my $tot = 0;
print "$pep\n" if($verbose);
foreach(@prots) {
    if($verbose) {
	print "$_\t";
	if(exists $member{$_}) {
	    print "member\t";

	}
	else {
	    print "-\t";

	}
	if(exists $degen{$_}) {
	    print "degen";

	}
	else {
	    print "-";

	}
	print "\n";
    }
    $tot++ if(! exists $member{$_});
}
if($tot == 0) {
    print "warning: $pep found to have $tot non-groupmember proteins\n";
    $tot++;
}
return $tot;
}


sub getAllSharedPeptides {
(my $cluster) = @_;
my @prots = split(' ', $cluster);
my @output = ();
my @peps = sort keys %{$prot_peps{$prots[0]}};
my $ok;
for(my $p = 0; $p < @peps; $p++) {
    $ok = 1;
    for(my $members = 0; $members < @prots; $members++) {
	$ok &&= exists ${$prot_peps{$prots[$members]}}{$peps[$p]};
    }
    push(@output, $peps[$p]) if($ok);
} # next peptide
return \@output;
}

sub getBatchAnnotation {
(my $db) = @_;
die "cannot find $db\n" if(! -e $db);
open(DB, $db) or die "cannot open DB $db $!\n";
while(<DB>) {
    if(/^\>(\S+)\s+(\S.*\S)/) {
	my $new_annot = $1;
	$annotation{$new_annot} = $2;

	# get rid of illegal xml symbols
	$annotation{$new_annot} =~ s/\"/\'/g; # cover quotes
	$annotation{$new_annot} =~ s/\&/and/g; # cover &
	$annotation{$new_annot} =~ s/\>/\)/g;
	$annotation{$new_annot} =~ s/\</\(/g;
    }
    elsif(/^\>(\S+)/) {
	$annotation{$1} = ''; # blank
    }
}
close(DB);

}

sub getAnnotation {
(my $prot, my $db, my $grp) = @_;
#return if($XML_INPUT);
return if($BATCH_ANNOTATION);

die "cannot find $db\n" if(! -e $db);


my @prots = split(' ', $prot);
my $output = '';
my $first = 1;
foreach(@prots) {
    if(! exists($annotation{$_}) || length($annotation{$_}) <= 0 ) {
	open GREP, "grep \"$_\" $db |";
	my @results = <GREP>;
	if(@results > 0) {
	    $annotation{$_} = $results[0];
	    $annotation{$_} =~ s/\"/\&quot\;/g; # cover quotes
	    $annotation{$_} =~ s/\'/\&apos\;/g; # cover quotes
	    
	    $annotation{$_} =~ s/\&/and/g; # cover &
	    $annotation{$_} =~ s/\>/\&gt\;/g;
	    $annotation{$_} =~ s/\</\&lt\;/g;

	}
	else {
	    $annotation{$_} = '&gt;' . "\n";
	}
	close(GREP);
    }
    if($grp > -1 && exists $annotation{$_}) {
	$output .= "</FONT>" . '|' . "<FONT COLOR=\"\#$grp\">" if($grp);
	if($IPI_DATABASE && $annotation{$_} =~ /^(\S+IPI\S+)\s+(\S+.*?Tax\_Id\=\d+)\s+(\S.*\S)/) {
	    $output .= "\t" . $1 . ' ' . $3 . ' [' . $2 . ']' . "\n";
	}
	else {
	    $output .= "\t" . $annotation{$_};
	}
    }
} # next prot

return $output;
}

sub maxPeptideLength {
    my $length = 0;
    foreach(keys %pep_max_probs) {
	$length = (length $_) if((length $_) > $length);
    }
    return $length;
}


sub hasIndependentEvidence {
(my $prot_entry, my $min_prob) = @_;
foreach(keys %{$prot_peps{$prot_entry}}) {
    return 1 if(${$pep_max_probs{$_}}{$prot_entry} >= $min_prob && getNumberDegenProteins($_) == 1);
}
return 0; # no idep evidence
}

sub group {
(my $prot_entry1, my $prot_entry2) = @_;
return 0 if($prot_entry1 eq $prot_entry2);
my $min_prob = 0.5;
my $min_pct = 0.4;
my $suff_num = 5;

my @peps1 = sort keys %{$prot_peps{$prot_entry1}};
my @peps2 = sort keys %{$prot_peps{$prot_entry2}};
my $num_common = 0;
my $num_tot = 0;
foreach(@peps1) {
    if(${$pep_max_probs{$_}}{$prot_entry1} >= $min_prob) {
	$num_tot++;
	for(my $p = 0; $p < @peps2; $p++) {
	    if($_ eq $peps2[$p]) {
		$num_common++;
		$p = @peps2;
	    }
	}
    }
}
return 1 if($num_tot > 0 && ($num_common >= $suff_num || $num_common / $num_tot >= $min_pct));

$num_common = 0;
$num_tot = 0;
foreach(@peps2) {
    if(${$pep_max_probs{$_}}{$prot_entry2} >= $min_prob) {
	$num_tot++;
	for(my $p = 0; $p < @peps1; $p++) {
	    if($_ eq $peps1[$p]) {
		$num_common++;
		$p = @peps1;
	    }
	}
    }
}
return 1 if($num_tot > 0 && ($num_common >= $suff_num || $num_common / $num_tot >= $min_pct));
return 0;
}

sub findGroups {
    my $min_evid_prob = 0.5;
    my $min_num_peps = 0; #3;
    my $max_prot_prob = 1.0; #0.05;
    $group_index = 0;
    my $num1;
    my $num2;
    my @parsed;
    my @prots = sort { rank_protein_probs($protein_probs{$a}) <=> rank_protein_probs($protein_probs{$b}) || $a cmp $b} keys %protein_probs; #  sort at output accuracy
    for(my $p1 = 0; $p1 < @prots; $p1++) {
	@parsed = split(' ', $prots[$p1]);
	if($protein_probs{$prots[$p1]} > $max_prot_prob) { # done
	    $p1 = @prots;
	}

	elsif(scalar keys %{$prot_peps{$parsed[0]}} >= $min_num_peps &&
					   ! hasIndependentEvidence($prots[$p1], $min_evid_prob)) {
	
	    for(my $p2 = 0; $p2 < $p1; $p2++) {
		@parsed = split(' ', $prots[$p2]);
		if($protein_probs{$prots[$p2]} > $max_prot_prob) { # done
		    $p2 = $p1; # done
		}
		elsif(scalar keys %{$prot_peps{$parsed[0]}} >= $min_num_peps &&
                   ! hasIndependentEvidence($prots[$p2], $min_evid_prob) && group($prots[$p1], $prots[$p2])) {

		    if(! exists $group_members{$prots[$p1]} && ! exists $group_members{$prots[$p2]}) {
			$group_members{$prots[$p1]} = $group_index;
			$group_members{$prots[$p2]} = $group_index;
			my @next = ($prots[$p1], $prots[$p2]);
			$groups[$group_index++] = \@next;
		    }
		    elsif(! exists $group_members{$prots[$p1]}) {
			$group_members{$prots[$p1]} = $group_members{$prots[$p2]};
			push(@{$groups[$group_members{$prots[$p2]}]}, $prots[$p1]);
		    }
		    elsif(! exists $group_members{$prots[$p2]}) {
			$group_members{$prots[$p2]} = $group_members{$prots[$p1]};
			push(@{$groups[$group_members{$prots[$p1]}]}, $prots[$p2]);
		    }
		    else { # reassign and merge
			if($group_members{$prots[$p1]} != $group_members{$prots[$p2]}) {
			    for(my $k = 0; $k < @{$groups[$group_members{$prots[$p2]}]}; $k++) {
				push(@{$groups[$group_members{$prots[$p1]}]}, ${$groups[$group_members{$prots[$p2]}]}[$k]);
			    }
			    my @next = ();
			    $groups[$group_members{$prots[$p2]}] = \@next; # reset
			    $group_members{$prots[$p2]} = $group_members{$prots[$p1]};
			} # if not same groups
		    }
		} # if prob 0 and groups
	    } # next p2
	} # if prob 0 for p1
    } # next p1
# now display each group
    for(my $k = 0; $k < $group_index; $k++) {
	if(@{$groups[$k]} > 0) {
	    $group_probs{$k} = computeGroupProb($k);
	} # if group
    } # next index
    orderGroups(); # order within each group by prob, name
	# order groups by (output accuracy) probability, then lead protein name
    @grp_indeces = reverse sort { rank_protein_probs($group_probs{$a}) <=> rank_protein_probs($group_probs{$b}) || $groups[$b][0] cmp $groups[$a][0]  } keys %group_probs;
    extractGroupNames();
}

sub computeGroupProb {
(my $ind) = @_;
my %gr_pep_wts = ();
my %gr_pep_probs = ();
my $next_prot;
for(my $k = 0; $k < @{$groups[$ind]}; $k++) {
    $next_prot = ${$groups[$ind]}[$k];
    my @parsed = split(' ', $next_prot);
    my @peps = sort keys %{$prot_peps{$parsed[0]}};
    my $prob = 0;
    for(my $p = 0; $p < @peps; $p++) {
	$gr_pep_wts{$peps[$p]} = 0 if(! exists $gr_pep_wts{$peps[$p]});
	$gr_pep_probs{$peps[$p]} = 0 if(! exists $gr_pep_probs{$peps[$p]});
    if (exists ${$pep_wts{$peps[$p]}}{$next_prot}) { # BSP avoid using uninit values
	$gr_pep_wts{$peps[$p]} += ${$pep_wts{$peps[$p]}}{$next_prot};
	}
    if (exists ${$pep_max_probs{$peps[$p]}}{$next_prot}) { # BSP avoid using uninit values
	$gr_pep_probs{$peps[$p]} = ${$pep_max_probs{$peps[$p]}}{$next_prot} if(${$pep_max_probs{$peps[$p]}}{$next_prot} > $gr_pep_probs{$peps[$p]});
	}
    } # next peptide

} # next prot
# now final prob.....
my $prob = 1;

if($OCCAM) { 
    foreach(keys %pep_wts) {
	$prob *= (1 - $gr_pep_wts{$_} * $gr_pep_probs{$_}) if($gr_pep_wts{$_} >= $MIN_WT && $gr_pep_probs{$_} >= $MIN_PROB);
    }
}
else { # all wts are 1 
    foreach(keys %pep_wts) {
	$prob *= (1 - $gr_pep_probs{$_}) if($gr_pep_probs{$_} >= $MIN_PROB);
    }
}
return (1 - $prob);
}


sub printProteinInfo {
(my $entry, my $index, my $max_peplength, my $min_pep_prob, my $grp, my $tail, my $prot_color) = @_;
my @peps;
my $PRINT_NUM_PEP_INSTANCES = 1;
my $min_pep_instance_prob = 0.2; # only record peptide instance if (NSP adjusted) prob at least 0.2

# HTML font colors
my $prot_prob_color = 'FF0000'; # red
$prot_prob_color = $prot_color if($prot_color);
my $asterisk_color = '990000'; # brown 
my $pep_prob_color = 'FF9933'; # orange
my $annot_color = '007800'; # green
my $match_color = 'DD00DD';
$grp = $annot_color if($grp);
my $VERBOSE = 0;
my $grp_index = '';

if($index =~ /^(\d+)(\-\d+)$/) {
    $grp_index = $1;
    $index = $2;
}
else {
    $grp_index = 0 - $index if($index < 0);
    $index = '' if($index < 0);
}

print "printProtProbs with $entry...\n" if($VERBOSE);
@peps = reverse sort { rank_protein_probs(${$pep_max_probs{$a}}{$entry}) <=> rank_protein_probs(${$pep_max_probs{$b}}{$entry}) || $b cmp $a } keys %{$prot_peps{$entry}};

print OUTFILE "<a name=\"$entry\"></a>";
if(exists $group_members{$entry}) {
    print OUTFILE "<!-- Grp=$group_names{$group_members{$entry}}";
    print OUTFILE " Ind=$grp_index" if(! ($grp_index eq ''));
    print OUTFILE " -->";
}

print OUTFILE "|" if($grp);

print OUTFILE "<a name=\"" . $index . "\"></a>$index\t", getDegenWts2($entry, \@peps, $protein_probs{$entry}, $grp);
printf OUTFILE "  <FONT COLOR=\"\#$prot_prob_color\"><b>%0.2f</b></FONT>", $protein_probs{$entry} if(! $prot_color);
printf OUTFILE "  <FONT COLOR=\"\#$prot_prob_color\">%0.2f</FONT>", $protein_probs{$entry} if($prot_color); # no bold
print OUTFILE "           ", getASAPRatio($ASAP_IND, $entry, \@peps) if($ASAP);
print OUTFILE "\n";

if($PRINT_PROT_COVERAGE) { # only one protein in degenerate group
    if($protein_probs{$entry} >= 0.05) {
	if(! exists $coverage{$entry}) {
	    $coverage{$entry} = getCoverageForEntry($entry, $PRINT_PROT_COVERAGE); #, \@peps, 0.5, 0.5, $PRINT_PROT_COVERAGE);
	}
	if($coverage{$entry} != -1) {
	    print OUTFILE "|" if($grp);
	    printf OUTFILE "\t";
	    printf OUTFILE "max " if($entry =~ /\s/); # if more than one protein in entry
	    printf OUTFILE "coverage: %0.1f %\n", $coverage{$entry};
	}
    }
}

if($ANNOTATION) {
    print OUTFILE "<FONT COLOR=\"\#$annot_color\">";
    print OUTFILE "", getAnnotation($entry, $database, $grp);
    print OUTFILE "</FONT>";
}

print STDERR "here1\n" if($VERBOSE);
die "no entry for $entry\n" if(! exists $prot_peps{$entry});
if($VERBOSE) {
    for(my $z = 0; $z < @peps; $z++) { print STDERR "$peps[$z] "; } print STDERR "\n";
}
my $indsptr = findCommonPeps(\@peps) if($UNIQUE_2_3);

for(my $k = 0; $k < @peps; $k++) {
    print "peptide $peps[$k]\n" if($VERBOSE);
printf "pep max for $peps[$k] with $entry: %0.4f\n", ${$pep_max_probs{$peps[$k]}}{$entry} if($VERBOSE);
    if(${$pep_max_probs{$peps[$k]}}{$entry} >= $min_pep_prob) {

	if(exists $equivalent_peps{$peps[$k]}) {
	    my @actualpeps = keys %{$equivalent_peps{$peps[$k]}};
	    die "problem with no actual peps for $peps[$k]\n" if(@actualpeps == 0);
	    print OUTFILE "|" if($grp);
	    print OUTFILE "\t";
	    print OUTFILE "<FONT COLOR=\"\#$match_color\">${$indsptr}{$peps[$k]}</FONT>"  # pink
		if($UNIQUE_2_3 && exists ${$indsptr}{$peps[$k]});
	    print OUTFILE "<FONT COLOR=\"\#$match_color\">-", substr($peps[$k], 0, 1), "</FONT>" if($UNIQUE_2_3 && exists ${$indsptr}{$peps[$k]});
	    print OUTFILE "\t";
	    if(getNumberDegenProteins($peps[$k]) == 1) {
		print OUTFILE "<FONT COLOR=\"#$asterisk_color\">";
		print OUTFILE "*";
		print OUTFILE "</FONT>";
	    }
	    else {
		print OUTFILE " ";
	    }
	    print OUTFILE "", getWeightCGITag($entry, $peps[$k], \@actualpeps);
	    printf OUTFILE "wt-%0.2f", ${$pep_wts{$peps[$k]}}{$entry};
	    print OUTFILE "</A>";

	    print OUTFILE "\t", getPeptideCGITag($actualpeps[0], $max_peplength+3);

	    my $color =  ${$pep_max_probs{$peps[$k]}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$peps[$k]}}{$entry} >= $FINAL_PROB_MIN_WT;
	    
	    print OUTFILE "<FONT COLOR=\"\#$pep_prob_color\">" if($color);
	    printf OUTFILE "%0.2f", ${$pep_max_probs{$peps[$k]}}{$entry};
	    print OUTFILE "</FONT>" if($color);
	    printf OUTFILE " / %0.2f    ", ${$orig_pep_max_probs{$peps[$k]}}{$entry};
	    printf OUTFILE "ntt %d, ", maxNTT($entry, $peps[$k]);
	    printf OUTFILE "nsp %d", ${$pep_nsp{$peps[$k]}}{$entry};
	    printf OUTFILE ", tot %d", numInstancesPeptide($peps[$k], $entry, 0, 0) if($PRINT_NUM_PEP_INSTANCES);
	    print OUTFILE "\n";
	    for(my $a = 1; $a < @actualpeps; $a++) {
		print OUTFILE "|" if($grp);
		print OUTFILE "\t\t\t       \t--", getPeptideCGITag($actualpeps[$a], 0), "\n";
	    }
	}
	else { # no equiv peps
	    print OUTFILE "|" if($grp);
	    print OUTFILE "\t";
	    print OUTFILE "<FONT COLOR=\"\#$match_color\">${$indsptr}{$peps[$k]}</FONT>"  # pink
		if($UNIQUE_2_3 && exists ${$indsptr}{$peps[$k]});

	    print OUTFILE "<FONT COLOR=\"\#$match_color\">-", substr($peps[$k], 0, 1), "</FONT>" if($UNIQUE_2_3 && exists ${$indsptr}{$peps[$k]});
	    print OUTFILE "\t";
	    if(getNumberDegenProteins($peps[$k]) == 1) {
		print OUTFILE "<FONT COLOR=\"#$asterisk_color\">";
		print OUTFILE "*";
		print OUTFILE "</FONT>";
	    }
	    else {
		print OUTFILE " ";
	    }
	    print OUTFILE "", getWeightCGITag($entry, $peps[$k], 0);
	    printf OUTFILE "wt-%0.2f", ${$pep_wts{$peps[$k]}}{$entry};
	    print OUTFILE "</A>";

	    print OUTFILE "\t", getPeptideCGITag($peps[$k], $max_peplength+3);
	    my $color =  ${$pep_max_probs{$peps[$k]}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$peps[$k]}}{$entry} >= $FINAL_PROB_MIN_WT;
	    print OUTFILE "<FONT COLOR=\"\#$pep_prob_color\">" if($color);
	    printf OUTFILE "%0.2f", ${$pep_max_probs{$peps[$k]}}{$entry};
	    print OUTFILE "</FONT>" if($color);
	    printf OUTFILE " / %0.2f    ", ${$orig_pep_max_probs{$peps[$k]}}{$entry};
	    printf OUTFILE "ntt %d, ", maxNTT($entry, $peps[$k]);
	    printf OUTFILE "nsp %d", ${$pep_nsp{$peps[$k]}}{$entry};
	    printf OUTFILE ", tot %d", numInstancesPeptide($peps[$k], $entry, 0, 0) if($PRINT_NUM_PEP_INSTANCES);
	    print OUTFILE "\n";
	} # no equiv peps
    } # if above thresh
}
print OUTFILE "|" if($tail);
print OUTFILE "\n";

}
 

sub printGroup {
(my $group_ind, my $max_peplength, my $min_pep_prob, my $index, my $prot_prob_color) = @_;
my $group_prot_prob_color = 'B40000'; 
print OUTFILE "<a name=\"$group_names{$group_ind}\"></a>";
printf OUTFILE "$index\t";

print OUTFILE "", getGroupLabel($group_names{$group_ind});
printf OUTFILE "  <FONT COLOR=\"\#$prot_prob_color\"><b>%0.2f</b></FONT>\n", $group_probs{$group_ind};
for(my $g = 0; $g < @{$groups[$group_ind]}; $g++) {
    printProteinInfo(${$groups[$group_ind]}[$g], $index . '-' . ($g+1), $max_peplength, $min_pep_prob, 1, $g < @{$groups[$group_ind]} - 1, $group_prot_prob_color);
}
}


sub extractGroupName {
(my $grp_index, my $excludeptr, my $index) = @_;
my $num = 0;
my %words = ();
my $next;
my $n;
foreach(@{$groups[$grp_index]}) {
    my @parsed1 = split("\n", getAnnotation($_, $database, 0));
    $num += @parsed1;
    for(my $p = 0; $p < @parsed1; $p++) {
	$next = '';
	for(my $z = 0; $z < length $parsed1[$p]; $z++) { 
	    $n = lc substr($parsed1[$p], $z, 1);
	    if($n =~ /[a-z]/) { 
		$next .= $n;
	    }
	    elsif($n =~ /[0-9]/) {
		$next .= $n;;
	    }
	    else { 
		$words{$next}++ if($next =~ /[a-z]/ && ! exists ${$excludeptr}{$next});
		$next = '';
	    }
	}
    }
    if($next =~ /\S/) {
	$words{$next}++ if(! exists ${$excludeptr}{$next});
    }

}

if($num > 1) {
    foreach(keys %words) {
	$words{$_} /= $num;
    }
}

 # totals
my @results = reverse sort { $words{$a} <=> $words{$b} } keys %words;
my $max_num = @results;

my $output = $index;
my $k = 0;
my $total = 0;
my $MAX_GRP_NAME_LENGTH = 60;
while($k < @results && $words{$results[$k]} >= 0.7) {
    $output .= '_' . $results[$k++];
    return $output if((length $output) > $MAX_GRP_NAME_LENGTH);
    $total++;
}

if(@results > 0 && $total < 5) { # nothing happened
    for(my $w = $total; $w < $max_num; $w++) {
	$output .= '_' . $results[$w] if($words{$results[$w]} > 0.5);
	return $output if((length $output) > $MAX_GRP_NAME_LENGTH);
    }
}
return $output;

}


sub extractGroupNames {
    my $excludes = 'the at a for an or and no not is cds this that mass gp sw pir start codon mrna human homo sapiens to complete partial clone of pir2 non ec mgc image kd kda tax id ipi gt np ensembl refseq xp trembl';
    my @excludes = split(' ', $excludes);
    my %excludes = ();
    foreach(@excludes) {
	$excludes{$_}++;
    }
    my $index = 1;
    foreach(@grp_indeces) {
	$group_names{$_} = extractGroupName($_, \%excludes, $index++);
    }
    
}

sub getGroupLabel {
(my $group_name) = @_;
my $output = '[PROTEIN GROUP ';
chomp $group_name;
if($group_name =~ /^(\d+)\_(\S+)$/) {
    $output .= $1 . ': ' . $2;
}
elsif($group_name =~ /^(\d+)$/) {
    $output .= $1;
}
else {
    die "cannot parse group label from $group_name\n";
}
return $output . ']';
}


sub maxNTT {
(my $prot_entry, my $pep) = @_;
my @prots = split(' ' , $prot_entry);
die "error with prot entry $prot_entry and pep $pep\n" if(@prots == 0);

my $max = ${$pep_prob_ind{$pep}}{$prots[0]};
return $max if(@prots == 1 || $max == 2);

for(my $k = 1; $k < @prots; $k++) {
    $max = ${$pep_prob_ind{$pep}}{$prots[$k]} if(${$pep_prob_ind{$pep}}{$prots[$k]} > $max);
    return $max if($max == 2);
}
return $max;
}


sub weightedPeptideProbs {
(my $prot, my $unique_wt) = @_;
my @peps = sort keys %{$prot_peps{$prot}};
my $tot = 0;
foreach(@peps) {
    if($unique{$_}) {
	$tot += ${$pep_max_probs{$_}}{$prot} * $unique_wt;
    }
    else {
	$tot += ${$pep_max_probs{$_}}{$prot};
    }
}
return $tot;
}

sub numUniquePeps {
(my $prot) = @_;
my @peps = sort keys %{$prot_peps{$prot}};
my $num = 0;
foreach(@peps) {
    $num += $unique{$_};
}
return $num;
}

sub numTrypticEnds {
(my $peptide) = @_;

my $num = 0;
if($peptide =~ /^(\S)\.(\S+)\.(\S)$/) {
    my $prev = $1;
    my $root = $2;
    my $following = $3;
    $num++ if($prev eq 'R' || $prev eq 'K' || $prev eq '-' || $prev eq '1' || $prev eq '@');
    if($following eq '-') {
	$num++;
    }
    else {
	# first must strip off all symbols
	my $next;
	my $stripped = '';
	my $last = '';
	for(my $k = 0; $k < length $root; $k++) {
	    $next = substr($root, $k, 1);
	    if($next =~ /[A-Z]/) {
		$stripped .= $next;
		$last = $next;
	    }
	}
	$num++ if($last eq 'R' || $last eq 'K');
    }
	
    return $num;
}
die "problem parsing peptide $peptide\n";
}


sub orderGroups {
    foreach(keys %group_probs) {
	# now order by prob
	my @next = reverse sort { rank_protein_probs($protein_probs{$a}) <=> rank_protein_probs($protein_probs{$b}) || $b cmp $a} @{$groups[$_]};
	$groups[$_] = \@next;
    }
}

sub getASAPIndex {
(my $entry, my $pepptr) = @_;
die "cannot get ASAP ratio when more than 1 input file\n" if($MULTI_FILES);
my $executable = '/data2/search/akeller/bin/getProtInd';
die "cannot find $executable\n" if(! -e $executable);
my $prophetfile = 'ASAPRatio_prophet.bof';
if($ASAP_FILE =~ /interact\-(\S+)\-data\.htm$/) {
    $prophetfile = 'ASAPRatio_' . $1 . '_prophet.bof';
}

die "cannot find $prophetfile\n" if(! -e $prophetfile);
my $indexec = '/data2/search/akeller/bin/getSeqInd.pl';
die "cannot find $indexec\n" if(! -e $indexec); # will only work on singe input file!!!!

my $verbose = 0; #$entry =~ /224729/;
my $args = $prophetfile;
my $nextindex;
my $nextpep;
my $nopeps = 1; # guilty until proven
my %inds = ();
if(@{$pepptr} > 0) {
    foreach(@{$pepptr}) {
	if(${$pep_max_probs{$_}}{$entry} >= $FINAL_PROB_MIN_PROB && ${$pep_wts{$_}}{$entry} >= $FINAL_PROB_MIN_WT) {

	    if(exists $equivalent_peps{$_}) {
		my @next = sort keys %{$equivalent_peps{$_}};
		for(my $n = 0; $n < @next; $n++) {
		    $nextpep = substr($next[$n], 2);
		    print STDERR "1:$indexec $source_files \"$nextpep\" |\n" if($verbose); 
		    open INDEX, "$indexec $source_files \"$nextpep\" |";
		    my @results = <INDEX>;
		    if(@results > 0) {
			chomp $results[0];
			if($results[0] >= 0) {
			    $inds{$results[0]}++;
			}
		    }
		}
	    }
	    else {
		$nextpep = substr($_, 2);
		open INDEX, "$indexec $source_files \"$nextpep\" |";
		print STDERR "2:$indexec $source_files \"$nextpep\" |\n" if($verbose); 
		my @results = <INDEX>;
		if(@results > 0) {
		    chomp $results[0];
		    if($results[0] >= 0) {
			$inds{$results[0]}++;
		    }
		}
	    }
	    $nopeps = 0;
	} # if enough prob and wt
    }
# now get the result index.....
    foreach(sort keys %inds) {
	$args .= ' ' . $_;
    }
print STDERR "$executable $args |\n" if($verbose);
    open INDEX, "$executable $args |";

    my @results = <INDEX>;

    print STDERR "results: ", join(' ', @results), "\n" if($verbose);

    if(@results > 0) {
	chomp $results[0];
	return $results[0];
    }		
    

} # if

return -1;
}

sub getASAPRatio {
(my $index, my $entry, my $pepptr) = @_;
my $executable = '/tools/bin/add_ASAPRatio';
die "cannot get ASAP ratio when more than 1 input file\n" if($MULTI_FILES);
die "cannot find ASAP file\n" if(! -e $ASAP_FILE);
return $ASAP{$entry} if(exists $ASAP{$entry});

my $arg = $ASAP_REFRESH ? '1' : '0';
my $pepargs = '';

my $nopeps = 1; # guilty until proven
my $verbose = 0; #$entry =~ /133916/;

if(@{$pepptr} > 0) {
    foreach(@{$pepptr}) {
	if(${$pep_max_probs{$_}}{$entry} >= $ASAP_MIN_PEP_PROB && ${$pep_wts{$_}}{$entry} > $ASAP_MIN_WT) {

	    if(exists $equivalent_peps{$_}) {
		my @next = sort keys %{$equivalent_peps{$_}};
		for(my $n = 0; $n < @next; $n++) {
		    $pepargs .= ' "' . substr($next[$n], 2) . '"' if(! $ASAP_REFRESH);
		}
	    }
	    else {
		$pepargs .= ' "' . substr($_, 2) . '"' if(! $ASAP_REFRESH);
	    }
	    $nopeps = 0;
	} # if enough prob and wt
    }
    if($nopeps) {
	$ASAP{$entry} = '';
	return '';
    }
}

# valid call to asapratio....
$ASAP_IND++; 

# here if use original, must look up correct index number now
if($ASAP_REFRESH && $ASAP_EXTRACT) {
    if(exists $EXTRACTED_INDS{$entry}) {
	$index = $EXTRACTED_INDS{$entry};
    }
    else {
	$index = getASAPIndex($entry, $pepptr);
	$EXTRACTED_INDS{$entry} = $index ;
    }
    if($index == -1) {
	$ASAP{$entry} = '';
	return '';
    }
}

$arg .= ' ' . $index . ' ' . $ASAP_FILE . $pepargs;


if(! $ASAP_REFRESH && $ASAP_INIT) {
    system("$executable 0 -1 $ASAP_FILE");
    $ASAP_INIT = 0;
}
open ASAP, "$executable $arg |";

my @result = <ASAP>;
if(@result > 0) {
    chomp $result[$#result];
    $ASAP{$entry} = "ASAP: " . join('', @result);
    return "ASAP: " . join('', @result);
}
$ASAP{$entry} = '';
return ''; #'ASAP: error';
}

sub getDegeneracies {
(my $file) = @_;
return if(! $DEGEN);
setWritePermissions($file);
my $executable = 'PeptideProphetOutput';
#die "cannot find $executable\n" if(! -e $executable);

# check for PPO
open(WHICH, "which $executable |");
my $found = 0;
my @results = <WHICH>;
close(WHICH);
if(@results > 0) {
    chomp $results[0];
    $found = 1 if($results[0] =~ /^\//);
}
if(! $found) {
    print STDERR " Error: cannot find $executable.  No peptide degeneracy information possible\n\n";
    return;
}


my $probfile = $file . '.prob';
my $esifile = $file . '.esi';
if(-e $probfile && -e $esifile) {
    system("$executable $file") if(! -e $file . '.dgn');
}
elsif(-e $probfile) {
    if($WINDOWS) {
	system("$executable $probfile $file WINDOWS") if(! -e $file . '.dgn');
    }
    else {
	system("$executable $probfile $file") if(! -e $file . '.dgn');
    }
}
else {
    print STDERR " could not find .prob file for $file, no degeneracy information possible\n";
}
}

sub Bool2Alpha {
(my $bool) = @_;
if($bool) {
    return "Y";
}
return "N";
}


sub getClass {
(my $prot) = @_;
my $dbase = '';
if($database eq '/data/search/akeller/databases/halobacterium_111401_plus_human.prot') {
    $dbase = '/data/search/akeller/databases/halobacterium_111401.prot';
}
else {
    return 0;
}


if(@db_prots == 0) {
    # must open db and get results now
    open(DB, $dbase) or die "cannot open DB $dbase $!\n";
    while(<DB>) {
	chomp();
	if(/^\>(\S+)/) {
	    push(@db_prots, $1);
	}
    } # next db
    close(DB);
}
foreach(@db_prots) {
    return 1 if($_ eq $prot);
}
return 0;

open GREP, "grep \"$prot\" $dbase |";
my @results = <GREP>;
if(@results > 0) {
    chomp $results[0];
    my @parsed = split(' ', $results[0]);
    if($parsed[0] =~ /^\>(\S+)/) {
	if($1 eq $prot) {
	    return 1;
	}
	else {
	    return 0;
	}
    }

    return 1 if($prot eq $parsed[0]);
}
return 0;
}

sub isSTYMod {
(my $pep) = @_;
return $pep =~ /[S,T,Y][\*,\@,\#]/;
}

# given std name, extract stripped peptide seq, nterm, cterm, and modification info
sub interpretStdModifiedPeptide {
(my $std_pep) = @_;

# strip off preceding charge
my $peptide = '';
if($std_pep =~ /^(\d\_)(\S+)$/) {
    $peptide .= $1;
    $std_pep = $2;
}
my $nterm = 0;
my $cterm = 0;
my %mods = (); # hashed by position

my $counter = 1; # expect first amino acid to be 'n'
my $next;
my $next_aa;
my $next_mass;
my $next_orig_mass;
for(my $k = 0; $k < (length $std_pep); $k++) {
    $next = substr($std_pep, $k);
    if($next =~ /^([A-Z,c,n])\[(.*?)\]/) { # modified
	$next_aa = $1;
	$next_orig_mass = $2;
	$next_mass = $next_orig_mass;
	# now go back to the original to get full mass
	if(exists $MODIFICATION_MASSES{$next_aa}) {
	    for(my $z = 0; $z < @{$MODIFICATION_MASSES{$next_aa}}; $z++) {
		if(withinError($next_mass, ${$MODIFICATION_MASSES{$next_aa}}[$z], $MODIFICATION_ERROR)) {
		    $next_mass = ${$MODIFICATION_MASSES{$next_aa}}[$z];
		    $z = @{$MODIFICATION_MASSES{$next_aa}};
		}
	    }
	}


	if($next_aa eq 'n') {
	    $nterm = $next_mass;
	}
	elsif($next_aa eq 'c') {
	    $cterm = $next_mass;
	}
	else {
	    $mods{$counter} = $next_mass;
	}
	$k += (length $next_orig_mass) + 2; # advance
    }
    else {
	$next_aa = substr($next, 0, 1);
    }
    if($next_aa =~ /[A-Z]/) {
	$peptide .= $next_aa; # except for n and c
	$counter++;
    }

} # next pos
return ($peptide, $nterm, $cterm, \%mods);
}

sub streamlineStdModifiedPeptide {
(my $std_pep) = @_;
return $std_pep if(! $OMIT_CONST_STATICS);
my $peptide = '';
if($std_pep =~ /^(\d\_)(\S+)$/) {
    $peptide .= $1;
    $std_pep = $2;
}

my $next;
my $next_aa;
my $next_mass;
my $omit = 0;
for(my $k = 0; $k < (length $std_pep); $k++) {
    $next = substr($std_pep, $k);
    $omit = 0;
    $next_mass = 0.0; # default

    if($next =~ /^([A-Z,c,n])\[(.*?)\]/) { # modified
	$next_aa = $1;
	$next_mass = $2; # default

	$omit = (exists $constant_static_mods{$next_aa} && exists ${$constant_static_mods{$next_aa}}{$next_mass}
		 && ${$constant_static_mods{$next_aa}}{$next_mass} >= $constant_static_tots);


	if($omit) {
	    $peptide .= $next_aa if($next_aa =~ /[A-Z]/); # except for n and c;
	}
	else {
	    $peptide .= $next_aa . '[' . $next_mass . ']';
	}

	$k += (length $next_mass) + 2; # advance
    }
    else {
	$next_aa = substr($next, 0, 1);
	$peptide .= $next_aa if($next_aa =~ /[A-Z]/); # except for n and c
    }
} # next pos
return $peptide;

}
# given (stripped) peptide seq and modification info, returns std modified peptide name (while entering modified masses in REF)
sub getStdModifiedPeptide {
(my $peptide, my $nterm, my $cterm, my $modptr, my $error) = @_;
my $std_pep = '';
if($peptide =~ /^(\d\_)(\S+)$/) {
    $std_pep .= $1;
    $peptide = $2;
}

$std_pep .= getStdModifiedAminoAcid('n', $nterm, $error) if($nterm > 0.0);
my $next;
for(my $k = 0; $k < (length $peptide); $k++) {
    $next = substr($peptide, $k, 1);
    $std_pep .= getStdModifiedAminoAcid($next, exists ${$modptr}{$k+1} ? ${$modptr}{$k+1} : 0, $error);
} # next pos
$std_pep .= getStdModifiedAminoAcid('c', $cterm, $error) if($cterm > 0.0);
#print "std: $std_pep\n";
return $std_pep;
}

sub getStdModifiedAminoAcid {
(my $aa, my $mass, my $error) = @_;
return $aa if($mass == 0.0);



my $stdmass = sprintf("%0.0f", $mass); # ensure 2 decimal places

if(exists $MODIFICATION_MASSES{$aa}) {
    for(my $k = 0; $k < @{$MODIFICATION_MASSES{$aa}}; $k++) {
	return $aa . '[' . sprintf("%0.0f", ${$MODIFICATION_MASSES{$aa}}[$k]) . ']' if(withinError($stdmass, ${$MODIFICATION_MASSES{$aa}}[$k], $error));
    }
    # still here
    push(@{$MODIFICATION_MASSES{$aa}}, $mass); #$stdmass);
    return $aa . '[' . $stdmass . ']';
}
my @next = ();

push(@next, $mass);
$MODIFICATION_MASSES{$aa} = \@next;
return $aa . '[' . $stdmass . ']';

}

# DEPRECATED 7.6.04
# for next generation modification tracking (xml only)
sub generateSubstitutedPeptide {
(my $pep, my $mod_indexptr, my $equivalenceptr) = @_;

my @additional_symbols = ('~', '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '-', '+', '|', 'a', 'b', 'd', 'e', 'f', 'g', 'h', 'i', 'j', 'k', 'l', 'm', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v', 'w', 'x', 'y', 'z');
my $output = '';
my $next1;
my $next2;
my $found = 0;
my @mods = sort keys %{$mod_indexptr};
my $modified = 0;
for(my $k = 0; $k < (length $pep); $k++) {
    $found = 0;
    $next1 = substr($pep, $k, 1);
    $output .= $next1;
    # try the variable ones first (with symbol)
    if($k < (length $pep) - 1) {
	$next2 = substr($pep, $k, 2);
	for(my $j = 0; $j < @mods; $j++) {
	    if($next2 eq $mods[$j]) {
		# make the change
		if(${$mod_indexptr}{$mods[$j]} < 10) {
		    $output .= ${$mod_indexptr}{$mods[$j]};
		}
		elsif(${$mod_indexptr}{$mods[$j]} < 10 + @additional_symbols) {
		    $output .= $additional_symbols[${$mod_indexptr}{$mods[$j]}-10];
		}
		else {
		    print "error: too many modification symbols\n";
		    exit(1);
		}
		$found = 1;
		$modified = 1;
		$j = @mods;
		$k++;
	    }
	}
    }
    if(! $found) {
	for(my $j = 0; $j < @mods; $j++) {
	    if($next1 eq $mods[$j]) {
		# make the change
		if(${$mod_indexptr}{$mods[$j]} < 10) {
		    $output .= ${$mod_indexptr}{$mods[$j]};
		}
		elsif(${$mod_indexptr}{$mods[$j]} < 10 + @additional_symbols) {
		    $output .= $additional_symbols[${$mod_indexptr}{$mods[$j]}-10];
		}
		else {
		    print "error: too many modification symbols\n";
		    exit(1);
		}
#		$output .= ${$mod_indexptr}{$mods[$j]};
		$found = 1;
		$modified = 1;
		$j = @mods;
		$k++;
	    }
	}
    } # if still not found
} # next position
if($modified) {
    if(exists ${$equivalenceptr}{$output}) {
	${${$equivalenceptr}{$output}}{$pep}++;
    }
    else {
	my %next = ($pep => 1);
	${$equivalenceptr}{$output} = \%next;
    }
}
return $output;
}

sub withinError {
(my $first, my $second, my $error) = @_;
return 1 if($first == $second);
return 1 if($first < $second && $first >= $second - $error);
return 1 if($second < $first && $second >= $first - $error);
return 0;
}

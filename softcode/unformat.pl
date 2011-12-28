#!/usr/bin/perl
#############################################################################
# Define the above so that it points to your perl program
#############################################################################
#
#     Unformat.pl version 2.0
#     Copyright (C) 1996,1997 Adam Dray / adam@legendary.org
#     All Rights Reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
#
# The author can be contacted by emailing adam@legendary.org or by U.S
# Mail:
#
#     Adam Dray
#     9873 Bayline Circle
#     Owings Mills, MD 21117
#
#############################################################################
#
#                    WHAT IT DOES
#
# Basically, this program takes a file containing some pretty formatted
# code (presumably softcode for a MUSH or somesuch), and turns it into
# the terribly hard-to-read, unformatted stuff that the MUSH servers like.
# For example (ignoring my leading '# '), the following code:
#
# &CMD-TEST me = $@test:
#   @switch hasflag(%#, wizard) = 1, {
#     @pemit %# =
#        Test worked. You're a wizard.
#   }, {
#     @pemit %# = You ain't no wizard!
#   }
# -
#
# And turns it into (I'll use \ to signify lines that are continued,
# but note that the unformatter will put the following all on one long
# line):
#
# &CMD-TEST me = $@test: @switch hasflag(%#, wizard) = 1. {@pemit %# = \
# Test worked. You're a wizard.}, {@pemit %# = You ain't no wizard!}
#
#
#
#                    HOW TO USE IT WITH TINYFUGUE
#
# I'm assuming you've named this program unformat.pl, and that you've
# put it in a directory that's guaranteed to be in your executable path...
#
# Define a macro in TinyFugue (tf) called /upload in the following manner:
#         /def upload=/quote -0 !unformat.pl %*
#
# Then, in tf, you can upload file 'commands.mux' (for example) by
# typing '/upload commands.mux' into tf.  Commands.mux would contain
# formatted code.
#
#
#
#                    HOW TO USE IT WITH UNIX
#
# Assuming you've named this program unformat.pl, and that you've
# put it in a directory that's guaranteed to be in your executable path...
#
# Translate files from formatted to unformatted using standard Unix
# file redirection:
#        unformat.pl < myformatted > myunformatted
# ...or...
#        cat file1 file2 file3 > unformat.pl > myunformatted
#
# Then you can take myunformatted and upload it to a MUSH using whatever
# mushclient you normally use, assuming it has the ability to do this.
#
#
#
#                    FORMATTING RULES
#
# 1. Any line starting with a '#' is a comment, and is totally ignored,
#    unless it's one of the special directives (include or define).
#    See below, in 6.
#
# 2. Any line not starting with white space starts a command.
#
# 3. Once in a command, whitespace at the beginning of a line is
#    ignored, and subsequent lines are appended to the first until
#    a line containing a '-' as the first character and nothing except
#    whitespace following it is reached.
#
# 4. Once the '-' marker is reached, the command is output and the
#    unformatter looks for a new command.
#
# 5. Inline '/@@ @@/' comments are handled properly.
#
# 6. Exception to comments:
#
#   a. a line saying '#include something' (with the '#include' at the
#      beginning of the line) includes the entire text of a file called
#      'something' at that point.
#
#   b. a line saying '#define word anything' will do a macro replacement
#      throughout all files from that point on, replacing all instances
#      of 'word' with the full text of 'anything'.  'Anything' may contain
#      spaces and other special characters.
#
#    Note that valid include and define directives can have whitespace
#    before and after the '#' (e.g., '#define', '# define', ' #define').
#
#
# Multiple files can be unformatted at once by listing them on the
# unformat.pl command line: e.g., '/unformat a.mux b.mux c.mux' will
# unformat and concatenate three files in order.



#############################################################################
# Configuration stuff
#
#############################################################################

# Define $extraspace (to anything except null or 0) if you want \n\n
# between commands; otherwise, comment-out the line.  Extra space is
# usually ignored by mu* servers.
#
$extraspace = Yes;

# Output command. Comment-out all but one.
#
$outputcommand = "\@pemit %# =";
# $outputcommand = "think";
# $outputcommand = "/echo -w";

# Command to notify user at end. Comment-out all but one.
#
$donecommand = "\@pemit %#=Uploaded.";
# $donecommand = "think Uploaded.";
# $donecommand = "/echo -w Uploaded.";

# Command to postpone end notification by some queue-cycles.
# Useful if you have @dolists or somesuch at the end of your code.
#
$postpone_command = "\@wait 0 = \@wait 0 = \@wait 0 = ";


#############################################################################
# End of configuration stuff
#############################################################################

$rcs = '$Id: unformat.pl,v 1.4 1997/09/25 19:12:28 adam Exp $';
$version = "1.1";
$header1 = "Unformat.pl version $version";
# $header2 = "Copyright (C) 1996,1997 by Adam Dray.  All Rights Reserved.";

$DEBUG_DEFINES = 0;

# $filetable is a global associative array of files that have been visited

&output("$header1\n");
# &output("$header2\n");

$numargs = $#ARGV + 1;
if ($numargs) {
        foreach $file (@ARGV) {
                &command( $file, "filehandle00");
                print "\n";
        }
} else {
        &command( "", "file");
}

if ($successful) {
        print "\n" . $postpone_command . $donecommand . "\n";
        exit 0;
} else {
        exit -1;
}


#############################################################################

sub command {
    local($file, $input) = @_;

    $input++;                   # string increment for filename;

    if (!$file) {
        $input = \*STDIN;
        $file = "(stdin)";
    } else {
        unless(open($input, $file)) {
            &error("Can't open $file: $!.", -1);
            $successful = 0;
        }
    }

  GETTEXT:
    #
    # Start looking for commands.
    #
    # Commands start at the beginning of a line, without leading whitespace.
    # Any line starting with #include or #define (ignore leading whitespace)
    # is processed appropriately.  All other lines starting with '#' are
    # tossed out as comments (note that in this case, leading whitespace
    # followed by a # is NOT a comment).
    # Macro substitution is done on a per-line basis.
    #
    while (<$input>) {
        chomp;
        next GETTEXT if /^\s*$/;        # skip empty lines

        study;


        #################
        # handle includes
        #
        if ( /^\s*#\s*include\s+(\S.*)/ ) {
            if ( !$filetable{$1} ) {
                $filetable{$1} ++;
                &command($1, $input);
                next GETTEXT;
            } else {
                &output("WARNING: Attempted to include file '$1' more than once. Ignored.\n");
                next GETTEXT;
            }
        }


        ########################
        # read and store defines
        #
        if ( /^\s*#\s*define\s+(\S+)\s*$/ ) {
            $macros{$1} = 1;
            next GETTEXT;
        }
        elsif ( /^\s*#\s*define\s+(\S+)\s+(.+)/ ) {
               $macros{$1} = $2;
               next GETTEXT;
        }
        elsif ( /^\s*#\s*define/ ) {
               &output("WARNING: Bad #define on line $. of file $file. Ignored.");
               next GETTEXT;
        }

        
        ###############
        # skip comments
        #
        if ( /^#.*/ ) {
            next GETTEXT;
        }

        #########################
        # start reading a command
        #
        if ( /^\S/ ) {
            $text = $_;
        
            #########################
            # zap all inline comments
            #
            $text =~ s|/@@.+@@/||g;

            # make macro substitutions on text
            #
#           $text = &macro_substitute($text, %macros);
            $text = &substitute($text, %macros);
            print $text;        # print the first part of it
        }

      GETCOMMAND:
        #
        # At this point, we're 'inside' a command.
        # That is, we're going to ignore leading whitespace and append
        # all text onto our command string until we reach a - at the
        # beginning of a line, by itself (trailing whitespace is okay).
        # Macro replacements occur on a per-line basis.
        #
        while (<$input>) {
            chomp;
        
            ##########################################
            # end if '-' (trailing whitespace is okay)
            #
            last GETCOMMAND if /^-\s*$/;
        
            #################
            # handle includes
            #
            if ( /^\s*#\s*include\s+(\S.*)/ ) {
                if ( !$filetable{$1} ) {
                    $filetable{$1} ++;
                    &command($1, $input);
                    next;
                } else {
                    &output("WARNING: Attempted to include file '$1' more than once. Ignored.\n");
                    next;
                }
            }

            ###################
            # handle ascii mode
            #
            if ( /^\s*#\s*ascii\s*$/ ) {
                &process_ascii($input);
            }
            elsif ( /^\s*#\s*ascii/ ) {
                   &output("WARNING: Bad #ascii directive on line $. of file $file. Ignored.\n");

            }

            ###############
            # skip comments
            #
            next GETCOMMAND if /^#/;
        

            #############################################################
            # remove leading space and inline comments and print the rest
            #
            $text = $_;
            $text =~ s/^\s*//;
            $text =~ s|/@@.+@@/||g;
            $text = &substitute($text, %macros);
            print $text;
        }
        print "\n";                     # flush with a newline
        print "\n" if $extraspace;      # or two
    }
    close $input;

    if ( $DEBUG_DEFINES ) {
        print "-----------------------------------------------\n";
        print "                   Defines\n";
        print "-----------------------------------------------\n";
        foreach $macro (sort keys %macros) {
            print "$macro = '$macros{$macro}'\n";
        }
        print "-----------------------------------------------\n";
    }
}



# &error("error text message", integer_exit_code);
#
# Outputs an error message to the game and to STDERR, then
# exits with the exit code.
#
sub error {
    local ($text, $exitcode) = @_;

    $text = "Unknown error" unless $text;
    $exitcode = -1 unless $exitcode;

    &output("ERROR: $text\n");
    print STDERR "ERROR: $text\n";

    exit $exitcode;
}


# &output("line to be outputted to game");
#
# Issues the proper command to send a message to the game
#
sub output {
    local ($text) = @_;

    $text = "\n" unless $text;
    print "$outputcommand $text\n";
}


# &substitute($text, %macros)
#
# Returns a new string which represents a new version of $text
# after processing all macro substitutions in %macros.
#
# At this time, the macro substitutions happen in an unpredictable order.
#
sub substitute {
    local ($text, %macros) = @_;

    foreach $macro (sort keys %macros) {
        $with = $macros{$macro};
        $text =~ s/$macro/$with/g;
    }

    return $text;
}


# &process_ascii($file)
#
# Read lines of text from filehandle $file until an #ascii line is reached.
# Process all lines as if they were literal text, translating characters
# as follows, in order to load them into a MUSH: all spaces are converted
# to %b, a %r is placed at the end of each line, all literal tabs are changed
# to %t's, and a \ is placed before any [, {, and ( character.  All %'s are
# prepended with another % except when the % is followed by any of the
# following characters: aclnopqsvACLNOPQSV0123456789#! (%-substitutions
# used in programming on MUSH and MUX).
#
sub process_ascii {
    local ($infile) = @_;
    my $line;

    while (<$infile>) {
        chomp;

        if ( /^\s*#\s*ascii\s*$/ ) {
            print "\n";
            exit;
        }
        if ( /^\s*#\s*ascii/ ) {
            print "\n";
            &output("WARNING: Bad #ascii directive on line $. in file $file. Exiting anyhow.\n");
            exit;
        }

        $line = $_;

        ################################################
        # convert % to %% except when % is followed by a
        # substitution character.
        #
        $line =~ s/%([^aclnopqsvACLNOPQSV0123456789#!])/%%$1/g;

        ####################
        # other translations
        #
        $line =~ s#\\#\\\\#g;   # \\
        $line =~ s/  / %b/g;    # %b
        $line =~ s/\t/%t/g;     # %b
        $line =~ s/\{/\\\{/g;   # \{
        $line =~ s/\[/\\\[/g;   # \[
        $line =~ s/\(/\\\(/g;   # \(
        $line =~ s/$/%r/;

        print "$line";
    }
}

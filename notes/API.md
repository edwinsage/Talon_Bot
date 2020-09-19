# API for unit files, a.k.a. commands

This will get moved to docs/ once there's something worth releasing here.

## Current implementation:

    Command: !command_name !alternate_name !com_name
    
    Help: Display this help when users type "!help command_name"|Multiple lines are separated by a vertical bar.|This is line 3.
    
    Code:
    # This is now a block of Perl code.
    # Everything after the 'Code:' line is treated as the body of the command
    # subroutine, until the end of the block or end of file.
    
    # Send messages to chat with &chat():
    &chat("Hello world!");
    
    # Local variables can be used freely.
    # All local variables only last for that single call of the command.
    my $variable = 3;
    
    # To keep information beyond the current call, use the VARS space.
    # VARS should generally be treated as a hash, with keys for variables.
    # Anything stored in VARS will not persist after the bot exits.
    $VARS{times_command_run}++;
    
    # Other data structures can be created via references.
    # Some Perl knowledge recommended.
    $VARS{user_list} = [ ('Alison', 'Steve', 'Xobiv') ];
    
    foreach my $name ( @{ $VARS{user_list} } )  {  # This takes some dereferencing
        &chat("Hello, $name!");
        # The next line makes a nested data structure
        $VARS{"$name"}{was_greeted} = 'yes';
        }
    
    # To have data persist long-term (even after the bot exits and is started
    # again), store it in DATA.  Unlike VARS, DATA can only be used to store
    # name/value pairs, where the name consists of only alphanumeric characters
    # plus underscore, and the value is a string without newlines.
    $DATA{note_to_self} = "You really wanted yourself to remember $args";
    
    &&
    
    Command: !another_command
    ...etc.
    


## Odds & ends notes

startup
regex hooks
storage
OBS plugin-teraction
timers
other triggers?


All calls to commands are provided with three variables: $user, $tags, and $args

$user is the Twitch username of the user who invoked the command

$tags is a hash reference to all of the Twitch tags passed with the message. 
These are accessible as, for example, $tags{badges}. 
The &admin_test subroutine takes $tags as its argument:
if (&admin_test{$tags}) { do stuff }

$args is everything the user typed after the command, minus the leading space. 
It may be empty.



use whatever local variables you want
They will not pass between calls

for variables to persist between calls, use:
%VARS{variable}
and do whatever you want in that namespace

for data to persist between sessions (write to disk), use
%DATA{variable}
In this case, each [variable] should be a single word, and its value should be
a string, rather than any sort of reference.
Multiple such variables can exist.












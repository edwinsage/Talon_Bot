# API for unit files, a.k.a. commands

This will get moved to docs/ once there's something worth releasing here.

## Current implementation:

Use whatever local variables you want
They will not pass between calls

For variables to persist between calls, use:

    %VARS{variable}

and do whatever you want in that namespace

For data to persist between sessions (write to disk), use `%DATA{variable}`
In this case, each [variable] should be a single word, and its value
should be a string, rather than any sort of reference.  Multiple such
variables can exist.


### Commands

All calls to commands are provided with four variables:
`$user`, `$tags`, `$args`, and `$cfg`

`$user` is the Twitch username of the user who invoked the command

`$tags` is a hash reference to all of the Twitch tags passed with the message. 
These are accessible as, for example, `$$tags{badges}`. 
The `&admin_test` subroutine takes `$tags` as its argument:

    if (&admin_test{$tags}) { do stuff }

`$args` is everything the user typed after the command, minus the leading
space.  It may be empty.

`$cfg` is a hash reference for the config read at startup.

### Triggers

Instead of (or in addition to) a command name, a block can be activated
by a trigger.  A trigger is a test that operates on `$user`, `$tags`, or
`$msg`, where $msg is the full text of a chat message.  For example, the line

     Trigger: $msg =~ /^\d+$/

would activate any time a chat message consisting of only digits was
sent. 

## Example unit:

    Command: !command_name !alternate_name !com_name
    
    Trigger: $msg =~ /^test/i
    
    Help: Display this help when users type "!help command_name"
    Help: Multiple lines can be shown by repeating the Help header.
    Help: This is line 3.
    Help+: Help+ lines will only be shown when a moderator asks for help on this command.
    
    Code:
    # This is now a block of Perl code.
    # Everything after the 'Code:' line is treated as the body of the command
    # subroutine, until the end of the block or end of file.  It is executed
    # whenever the command is typed, or whenever the trigger is triggered.
    
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
    
    # You can put subroutines in your unit file and they will be useable
    # normally.  To prevent naming conflicts, you should name any such internal
    # routines as "sub_[unit]_[whatever], eg. sub_test_detonate in the 'test'
    # unit.



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










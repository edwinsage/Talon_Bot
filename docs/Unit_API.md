# API for unit files

Unit files have the ability to access a number of internal functions;
however, only those documented here should be considered good practice.

## Current implementation:

Each unit file contains one or more blocks,
separated by a line that only contains two ampersands `&&`.
Each block contains header lines, and ends with a code section.
The headers are used to specify when the code should run,
generally as a command, trigger, or subroutine,
and also to provide supporting information like help text.


### Headers

Each header is a single line, starting with an identifier.
The same identifier may appear more than once,
with the exception of the `Code:` header.


#### `Command:`

The `Command` header is used to list command names
that can be used in chat to activate the code.
Each command name may only contain letters, numbers, and underscores,
and is treated case insensitively.
They may optionally be prefixed with `!`.
Multiple names may be specified on one line separated by space,
or can be given using multiple `Command` lines.
In all cases, the very first command name that appears in a block will be
treated as the default command name;
others are treated simply as aliases of the first.


#### `Trigger:`

The `Trigger` header is used to specify a test
to be run on all incoming messages.
If the test passes, the code will be run.
All tests are executed as Perl code.
For those not experienced with Perl, some examples are given below;
reading up on "regular expressions" will also help.

Trigger tests may operate on the variables `$user`, `$tags`, or `$msg`,
where `$user` is the login username of the sender of the incoming message,
`$tags` is a hash reference of all the tags sent along with the message,
and `$msg` is the actual text of the message.

For more information on the tags a message can have, see
https://dev.twitch.tv/docs/irc/tags#privmsg-twitch-tags


##### Examples:

    Trigger: $msg eq "F"

Activates on an exact match.  In this case, typing only F in chat.

----

    Trigger: $msg =~ /^\d+$/

Activates any time a chat message consisting of only digits is sent.

----

    Trigger: $$tags{bits} > 9

Activates when a user Cheers more than 9 bits in one message.





### Code

Each block ends with a code section.
It starts after the `Code:` header, and goes to the end of the block.
The code section contains Perl code that will be run
every time a command or trigger from the headers is matched.

The code is provided with the following variables every time it is run:
`$user`, `$user_id`, `$tags`, `$msg`, `$cfg`, and `$args`.

`$user` is the Twitch username of the user who invoked the command,
or activated the trigger if applicable.

`$user_id` is the numeric Twitch id for the user.  It is helpful for
uniquely tracking users as this cannot be changed for an account, unlike
username.

`$tags` is a hash reference to all of the Twitch tags passed with the message.
These are accessible as, for example, `$$tags{badges}`.
(The extra $ is needed to dereference the hash.)

`$msg` is the body of the message that activated the code, if applicable.

`$cfg` is a hash reference for the config read at startup.
It contains authentication data used for interacting with the Twitch API.
This is not usually used directly,
but several subroutines provided to units need to be passed this.

`$args` will be an empty string unless the code was activated by
a command followed by additional arguments.
It is identical to $msg except that the command at the beginning of the message
is removed, to simplify parsing the arguments.



## Coding Guidelines

Use whatever local variables you want.
They will not pass between calls.

For variables to persist between calls, use:

    %VARS{variable}

and do whatever you want in that namespace.

For data to persist between sessions (write to disk), use `%DATA{variable}`.
In this case, each [variable] should be a single word,
and its value should be a string, rather than any sort of reference.
Multiple such variables can exist.


### Available subroutines

To send messages to chat, simply use the `chat()` subroutine:

    chat("Hello, world!");


The `admin_test()` subroutine can be used to test
if a user is a mod or broadcaster.
It needs to be passed the variable `$tags` as its argument:

    if ( admin_test{$tags} ) { do stuff }


The `get_commands()` subroutine can be used to inspect available commands. 
`get_commands()` will return a hash reference with keys consisting of all
available commands and one or more fields depending on the command type. 
All commands will have the key `type`, indicating the origin of the
command, which will be one of `core`, `unit`, `alias`, or `user`.  Other
keys include `unit` for the unit file that added a unit or alias type,
`dup_of` for aliases that shows what command it is an alias of, and
`attr` which contains a nested hash of any attribute values that a user
command has.

The `add_command()`, and `delete_command()` subroutines can be used to
manipulate user commands.  They will not affect commands of any other
type.  `add_command()` expects to be passed two or three arguments: the
name of the command to add, the text to display when the command is
called, and optionally a hash reference containing any attributes that
should be set for the command.  It will overwrite an existing user
command with the same name.  `delete_command()` simply expects to be
passed the name of the user command to remove.  It is recommended that a
unit track any user commands it creates, and not modify any that it did
not create.



## Caveats:

Both `VARS` and `DATA` are used as keywords, and are rewritten to their
proper contextual names before the unit code is run.  This conversion
happens anywhere those keywords show up preceeded by a sigil (`$`, `%`);
it does not parse quoted text as special.  This means that for example if
you ever have need to have the literal string `'$VARS'` appear in output,
you will have to take care to break it up; in this case you could write
`'$' . 'VARS'` instead.


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
    
    # Send messages to chat with chat():
    chat("Hello world!");
    
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
        chat("Hello, $name!");
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
    






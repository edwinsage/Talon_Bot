There are multiple ways of changing the commands available to users.
What should take priority when conflicts arise?

### For loading:
- Core commands are loaded first.
- Units are loaded alphabetically, first-come first-served,
  and commands aren't loaded if they overlap core or already loaded units.
  Primary names will override existing aliases, however.
- User commands are not checked for overlap,
  but are overridden by core and units commands.


### For running:
- First check core commands
- Next check units (though these should never conflict)
- Last look for user commands (which won't be seen if they conflict)



## User commands

Adding new user commands can be done by admins using the `!commands`
command.  Syntax follows that used by Nightbot for the sake of being
familiar to more users.  An example could be:

    !commands add !beep -cd=10 BEEP BEEP!

which would add a new command called !beep that would echo the text "BEEP
BEEP!" when run, with a cooldown of 10 seconds between uses.

Any attributes can be set by putting `-attribute=value` between the
command name and the text. Currently, Talon_Bot supports the following
attributes:

- `cd`: Cooldown.  This is the minimum number of seconds that must pass
  before the command will be recognized again.  Admins skip the cooldown
  waiting period.
- TODO: `ul`: User level.  This will restrict the users that are able to activate the
  command.  The levels are, from highest to lowest, `owner`, `moderator`,
  `vip`, `subscriber`, and `everyone`.  If one of these values is given,
  only users of the specified level or higher may use it.

Talon_Bot also supports the following variables in user commands:

- `$(count)`: This will display a number that increases by one each time
  the command is used.
- `$(query)`: This will be replaced with any text the user types after the
  command name.
- `$(user)`: The username of the user who activated the command.



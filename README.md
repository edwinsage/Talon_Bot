# Talon_Bot - A simple Perl bot for Twitch

Talon_Bot is intended to be an extendable, hackable bot for Twitch chat.


### Features:

* Extensible user commands

* Can create timestamped logs of chats

* Interactive help system


### Requirements:

* A Twitch account, and an associated OAuth token as described in
  https://dev.twitch.tv/docs/irc/guide

* Perl, minimum v5.20.  This could be lowered with little effort if needed,
  but for simplicity a non-ancient version is assumed.

* A POSIX environment to run in - Talon_Bot has only been tested on Linux,
  though it should presumably run well in other similar environments.


### How to:

0. Clone the repository with `git clone https://github.com/edwinsage/Talon_Bot`, or download and extract one of the releases.

0. Run Talon_Bot to create a default config file, `.Talon_Bot.rc`.

0. Edit the config file, particularly the lines for `user` and `auth`.  (Not needed to run in test mode)

0. Run the bot.  It will connect to the Twitch chat of the username (or other channel specified in the config), and will respond to commands.  Alternatively, run the bot in test mode using `./Talon_Bot -t`, which will skip the connection process and allow interaction directly on the command line.


### Hacking:

Code is still in alpha and a bit of a mess.  However, there is a fledgling plugin
 API for adding commands that lets you avoid all knowledge of the Talon_Bot code,
 except for a few variables.  Check out notes/API.md for details so far.



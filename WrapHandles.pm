package WrapHandles;

# Code from Reddit user u/raevnos

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.



use warnings;
use strict;

# Usage:
# use WrapHandles;
# use Symbol;
# my $handle = gensym;
# tie *$handle, 'WrapHandles', \*STDIN, \*STDOUT;
# print $handle "output";
# my $line = <$handle>;

sub TIEHANDLE {
  my ($class, $reader, $writer) = @_;
  bless { IN => $reader, OUT => $writer }, $class;
}

sub WRITE {
  my $this = shift;
  syswrite $this->{OUT}, @_;
}

sub PRINT {
  my $this = shift;
  print {$this->{OUT}} @_;
}

sub PRINTF {
  my $this = shift;
  printf {$this->{OUT}} @_;
}

sub READ {
  my $this = shift;
  my ($length, $offset) = @_[1,2];
  read $this->{IN}, $_[0], $length, $offset // 0;
}

sub READLINE {
  my $this = shift;
  if (wantarray) {
    my @lines = readline $this->{IN};
    return @lines
  } else {
    return scalar readline $this->{IN};
  }
}

sub GETC {
  my $this = shift;
  getc $this->{IN};
}

sub EOF {
  my $this = shift;
  eof $this->{IN};
}

sub CLOSE {
  my $this = shift;
  close $this->{IN};
  close $this->{OUT};
}

1;
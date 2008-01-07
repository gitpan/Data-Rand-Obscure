package Data::Rand::Obscure;

use warnings;
use strict;

=head1 NAME

Data::Rand::Obscure - Generate (fairly) random strings easily.

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    use Data::Rand::Obscure qw/create create_b64/;

    # Some random hexadecimal string value.
    $value = create;

    ...

    # Random base64 value:
    $value = create_b64;

    # Random binary value:
    $value = create_bin;

    # Random hexadecimal value:
    $value = create_hex;

    ...

    # A random value containing only hexadecimal characters and 103 characters in length:
    $value = create_hex(length => 103);

=head1 DESCRIPTION

Data::Rand::Obscure provides a method for generating random hexadecimal, binary, and base64 strings of varying length.
To do this, it first generates a pseudo-random "seed" and hashes it using a SHA-1, SHA-256, or MD5 digesting algorithm.

Currently, the seed generator is:

    join("", <an increasing counter>, time, rand, $$, {})

You can use the output to make obscure "one-shot" identifiers for cookie data, "secret" values, etc.

Values are not GUARANTEED to be unique (see L<Data::UUID> for that), but should be sufficient for most purposes.

This package was inspired by (and contains code taken from) the L<Catalyst::Plugin::Session> package by Yuval Kogman

=cut

use Digest;
use Carp::Clan;

sub _create() {
    my $digest = _find_digester();
    my $seeder = \&_default_seeder;
    $digest->add($seeder->());
    return $digest;
}

sub _create_to_length($$) {
    my $method = shift;
    my $length = shift;
    $length > 0 or croak "You need to specify a length greater than 0";

    my $result = "";
    while (length($result) < $length) {
        $result .= $method->();
    }

    return substr $result, 0, $length;
}

sub _create_bin {
    return _create()->digest;
}

sub _create_hex {
    return _create()->hexdigest;
}

sub _create_b64 {
    return _create()->b64digest;
}

=head1 EXPORTS 

=cut

use vars qw/@ISA @EXPORT_OK/; use Exporter(); @ISA = qw/Exporter/;
@EXPORT_OK = qw/create create_hex create_bin create_b64/;

=head2 $value = create([ length => <length> ])

=head2 $value = create_hex([ length => <length> ])

Create a random hexadecimal value and return it. If <length> is specificied, then the string will be <length> characters long.

If <length> is specified and not a multiple of 2, then $value will technically not be a valid hexadecimal value.

=head2 $value = create_bin([ length => <length> ])

Create a random binary value and return it. If <length> is specificied, then the value will be <length> bytes long.

=head2 $value = create_b64([ length => <length> ])

Create a random base64 value and return it. If <length> is specificied, then the value will be <length> bytes long.

If <length> is specified, then $value is (technically) not guaranteed to be a "legal" b64 value (since padding may be off, etc).

=cut

sub create {
    return create_hex(@_);
}

for my $name (map { "create_$_" } qw/hex bin b64/) {
    no strict 'refs';
    my $method = "_$name";
    *$name = sub {
        return $method->() unless @_;
        local %_ = @_;
        return _create_to_length(\&$method, $_{length}) if exists $_{length};
        croak "Don't know what you want to do: length wasn't specified, but \@_ was non-empty.";
    };
}

# HoD not required. :)
my $default_seeder_counter = 0;
sub _default_seeder {
    return join("", ++$default_seeder_counter, time, rand, $$, {});
}

my $digest_algorithm;

sub _find_digester() {
    unless ($digest_algorithm) {
        foreach my $algorithm (qw/SHA-1 SHA-256 MD5/) {
            if ( eval { Digest->new($algorithm) } ) {
                $digest_algorithm = $algorithm;
                last;
            }
        }
        die "Could not find a suitable Digest module. Please install "
              . "Digest::SHA1, Digest::SHA, or Digest::MD5"
            unless $digest_algorithm;
    }

    return Digest->new($digest_algorithm);
}

=head1 AUTHOR

Robert Krimen, C<< <rkrimen at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-rand-obscure at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Rand-Obscure>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Rand::Obscure


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Rand-Obscure>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Rand-Obscure>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Rand-Obscure>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Rand-Obscure>

=back


=head1 ACKNOWLEDGEMENTS

This package was inspired by (and contains code taken from) the L<Catalyst::Plugin::Session> package by Yuval Kogman

=head1 COPYRIGHT & LICENSE

Copyright 2007 Robert Krimen, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Data::Rand::Obscure

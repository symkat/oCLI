package oCLI::Plugin::Settings;
use Moo;

has rules => (
    is => 'ro',
    default => sub {
        return +{
            def     => sub { defined $_[0] ? $_[0] : $_[1] },
            defined => sub { defined $_[0] or die "Error: Setting not defined" },
            num     => sub { looks_like_number($_[0] or die "Error: Setting is not a number.") },
            gte     => sub { $_[0] >= $_[1] or die "Error: Setting must be a number greater than or equal to $_[1]" },
            lte     => sub { $_[0] <= $_[1] or die "Error: Setting must be a number less than or equal to $_[1]" },
        };
    }
);


sub before_code {
    my ( $self, $c, $d ) = @_;

    $c->trace( "Running validate settings..." );
    $self->validate_settings( $c, @{$d->{settings}} )
        if $d->{settings};

    return $c;
}

sub after_code {
    my ( $self, $c ) = @_;

    return $c;
}

sub validate_settings {
    my ( $self, $c, @in ) = @_;

     while ( my $setting = shift @in ) {
        my $meta  = shift @in;
        my $tests = $meta->[0];
        
        foreach my $test ( @$tests ) {
            my ( $name, $value ) = split( /=/, $test );
            $c->req->settings->{$setting} = $self->rules->{$name}->( $c->req->settings->{$setting}, $value );
        }
    }
}

1;

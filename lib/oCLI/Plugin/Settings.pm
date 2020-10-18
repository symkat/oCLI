package oCLI::Plugin::Settings;
use Moo;

has rules => (
    is => 'ro',
    default => sub {
        return +{
            def     => sub { defined $_[2] ? $_[2] : $_[3] },
            defined => sub { defined $_[2] or die "Error: --$_[1] was expected.\n" },
            num     => sub { looks_like_number($_[2] or die "Error: --$_[1] expects a number.\n") },
            gte     => sub { $_[2] >= $_[3] or die "Error: --$_[1] must be a number greater than or equal to $_[3]" },
            lte     => sub { $_[2] <= $_[3] or die "Error: --$_[1] must be a number less than or equal to $_[3]" },
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








# Settings is an arrayref, we set the structure via @in
#
# The valid arrayref begins with a string that is a setting name.
#
# Following the setting name string, it is followed by either:
# 
# 1. Array ref with data about the preceeding setting name
# 2. A string, the next setting name.
#
# settings => [ setting_name ]
# settings => [ setting_name, [ setting_data ] ]
# settings => [ setting_name, setting_name_two, [setting_data_two], setting_name_three ]
#
# The setting_data contains an arrayref of tests to validate the data, followed by a hashref
# that can describe the setting or add any meta data requird.
#
# For validation, the following are valid:
#
# [ 'function_name' ]
# [ 'function_name=value_for_function' ]
# [ sub { my ( $setting_value, $setting_structure ) = @_; } ]
#
#
sub validate_settings {
    my ( $self, $c, @in ) = @_;

    # function [ $c, $setting_name, $setting_value, $extra  ]

    while ( my $setting = shift @in ) {
        $c->trace("Validating setting: $setting" );

        if ( ref($in[0]) eq 'ARRAY' ) {
            $c->trace("Found setting validation structure.");
        } else {
            $c->trace("No validation structure found - verify only that the setting exists");
            next;
        }
        
        my $meta = shift @in;

        foreach my $test ( @{$meta->[0]} ) {

            if ( ref($test) eq 'CODE' ) {
                $c->trace("Running validation code block.");
                $c->req->settings->{$setting} = $test->($c, $setting, $c->req->settings->{$setting});
                next;
            }

            if ( index($test, '=') != -1 ) {
                my ( $function, $value ) = split(/=/, $test, 2);
                $c->trace("Running validation function $function with user-supplied value $value.");

                die "Error: unknown function $function called in validation."
                    unless defined $self->rules->{$function};
                $c->req->settings->{$setting} = $self->rules->{$function}->($c, $setting, $c->req->settings->{$setting}, $value );
                next;
            }

            # Last case, a bare function name.
            die "Error: unknown function $test called in validation."
                unless defined $self->rules->{$test};

            $c->req->settings->{$setting} = $self->rules->{$test}->($c, $setting, $c->req->settings->{$setting});
        }
    }
}

1;

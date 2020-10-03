package oCLI::Plugin;
use Moo;

has plugins => (
    is      => 'rw',
    default => sub { return [] },
);

sub add {
    my ( $self, $plugin ) = @_;

    push @{$self->plugins}, $plugin;
}

sub hook_before_code {
    my ( $self, $c, $command ) = @_;
    
    foreach my $plugin ( @{$self->plugins} ) {
        $plugin->before_code($c, $command);
    }
    return;
}

sub hook_after_code {
    my ( $self, $c ) = @_;
    
    foreach my $plugin ( @{$self->plugins} ) {
        $plugin->before_code($c);
    }
    return;
}

sub before_code {
    my ( $self, $c, $command ) = @_;

    return $c;
}

sub after_code {
    my ( $self, $c ) = @_;

    return $c;
}

1;

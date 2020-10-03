#!/usr/bin/env perl
use warnings;
use strict;
use Test::More;
use oCLI::Request;

my $tests = [
    {
        in   => [qw( /foo )],
        out  => { override => { foo => 1 } },
        desc => "Override: No argument results in 1 ",
        line => __LINE__,
    },
    {
        in   => [qw( /foo /bar=10 )],
        out  => { override => { foo => 1, bar => 10 } },
        desc => "Override: Numerical value assignment",
        line => __LINE__,
    },
    {
        in   => [qw( /foo /bar=10 /baz=10.5 )],
        out  => { override => { foo => 1, bar => 10, baz => 10.5} },
        desc => "Override: Floating point numerical value assignment",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar )],
        out  => { override => { foo => 1, bar => 10, baz => 10.5, bing => 'bar' } },
        desc => "Override: string assignment",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar )],
        out  => { override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' } },
        desc => "Override: Later assignments overwrite earlier",
        line => __LINE__,
    },
    
    {
        in   => [qw( /foo /bar=10 ), '/blee=foo bar'],
        out  => { override => { foo => 1, bar => 10, blee => 'foo bar' } },
        desc => "Override: token value can have spaces ",
        line => __LINE__,
    },

    #-- 

    {
        in   => [ qw( server --foo ) ],
        out  => { command => 'server', setting => { foo => 1 } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo ) ],
        out  => { command => 'server', setting => { foo => 1 } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee) ],
        out  => { command => 'server', setting => { foo => 1, bar => 'blee' } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee --bar baz) ],
        out  => { command => 'server', setting => { foo => 1, bar => [ 'blee', 'baz' ] } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server --foo --bar blee --bar baz --no-bat) ],
        out  => { command => 'server', setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    #--
    
    {
        in   => [ qw( server:create bar --foo ) ],
        out  => { command => 'server:create', setting => { foo => 1 }, args => [ 'bar' ] },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create bar blee --foo ) ],
        out  => { command => 'server:create', setting => { foo => 1 }, args => [ 'bar', 'blee' ] },
        desc => 'Settings',
        line => __LINE__,
    },

    #-- 

    {
        in   => [ qw( server:create --foo ) ],
        out  => { command => 'server:create', setting => { foo => 1 } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create --foo --bar blee) ],
        out  => { command => 'server:create', setting => { foo => 1, bar => 'blee' } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create --foo --bar blee --bar baz) ],
        out  => { command => 'server:create', setting => { foo => 1, bar => [ 'blee', 'baz' ] } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in   => [ qw( server:create --foo --bar blee --bar baz --no-bat) ],
        out  => { command => 'server:create', setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 } },
        desc => 'Settings',
        line => __LINE__,
    },
    
    {
        in    => [ qw( server:create --foo --bar blee --bar baz --no-bat) ],
        out   => { command => 'server:create', setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 } },
        desc  => 'Settings',
        line  => __LINE__,
    },


    #-- 
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create --minus - --neg -5 --foo --bar blee --bar baz --no-bat )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command => 'server:create',
            setting => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, minus => '-', neg => -5 }  
        },
        desc => "Override",
        line => __LINE__,
    },

    #-- File expansion in @file arguments

    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar @t/etc/data --foo --bar blee --bar baz --no-bat )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', "I am a data file.\nI have two lines.\n" ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0 },
        },
        desc => "Data Expansion in arguments",
        line => __LINE__,
    },
    
    #-- Data file
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar blee --foo --bar blee --bar baz --no-bat --data @t/etc/data )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', 'blee' ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, data => "I am a data file.\nI have two lines.\n" },
        },
        desc => "Override",
        line => __LINE__,
    },
    
    #-- STDIN
    {
        in   => [qw( /foo /bar=10 /baz=10.5 /bing=bar /foo=bar server:create bar blee --foo --bar blee --bar baz --no-bat --data @t/etc/data )],
        out  => { 
            override => { foo => "bar", bar => 10, baz => 10.5, bing => 'bar' }, 
            command  => 'server:create',
            args     => [ 'bar', 'blee' ],
            setting  => { foo => 1, bar => [ 'blee', 'baz' ], bat => 0, data => "I am a data file.\nI have two lines.\n" },
            stdin    => "I am from STDIN.\nI have two lines.\n"
        },
        desc => "Override",
        line => __LINE__,
        stdin   => "I am from STDIN.\nI have two lines.\n"
    },

];


my $stdin = *STDIN;
foreach my $test ( @{$tests} ) {

    # Stuff STDIN if we have content.
    if ( $test->{stdin} ) {
        open my $sf, "<", \"$test->{stdin}" or die "Failed to inject STDIN content: $!";
        *STDIN = $sf;
    }

    my $cmd = oCLI::Request_process_command_line( @{$test->{in}} );

    # Handle bug in STDIN between "" and undef under test_harness, vs prove
    is ( delete $cmd->{stdin} || "", delete $test->{out}{stdin} || "", sprintf( "Line %d: %s", $test->{line}, $test->{desc}));

    # Normal CDS testing
    is_deeply( $cmd, $test->{out}, sprintf( "Line %d: %s", $test->{line}, $test->{desc}) );

    # Reset STDIN if we stuffed it.
    *STDIN = $stdin if $test->{stdin};
}

done_testing();

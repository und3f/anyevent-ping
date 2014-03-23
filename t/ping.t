#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use AnyEvent;

# TODO: determinate local address and broadcast address

plan skip_all => 'You can run tests just as root' if $<;

use_ok 'AnyEvent::Ping';

my $ping = new_ok 'AnyEvent::Ping' => [timeout => 1];

subtest 'ping 127.0.0.1' => sub {
    my $result;
    my $cv = AnyEvent->condvar;

    $ping->ping(
        '127.0.0.1',
        2,
        sub {
            my $lres = shift;

            $result = $lres;

            $cv->send;
        }
    );

    $cv->recv;

    is_deeply $result, [['OK', $result->[0][1]], ['OK', $result->[1][1]]],
      'ping 127.0.0.1';

    done_testing;
};

subtest 'check two concurrent ping' => sub {
    my $cv = AnyEvent->condvar;
    my @res;

    my $ping_cb = sub {
        my $res = shift;
        push @res, $res;
        $cv->send if @res >= 2;
    };

    $ping->ping('127.0.0.1', 4, $ping_cb);
    $ping->ping('127.0.0.1', 4, $ping_cb);

    $cv->recv;

    is $res[0][0][0], 'OK', 'first concurrent ping ok';
    is $res[1][0][0], 'OK', 'second concurrent ping ok';

    done_testing;
};

subtest 'ping broadcast' => sub {
    my $result;
    my $cv = AnyEvent->condvar;

    $ping->ping(
        '127.255.255.255',
        2,
        sub {
            my $lres = shift;

            $result = $lres;

            $cv->send;
        }
    );

    $cv->recv;

    is_deeply $result, [['ERROR', $result->[0][1]]],
      'error reply on ping 127.255.255.255';

    done_testing;
};

$ping->end;

done_testing;

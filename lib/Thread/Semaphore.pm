package Thread::Semaphore;

use strict;

our $VERSION = '1.00';

use Thread qw(cond_wait cond_broadcast);

BEGIN {
    use Config;
    if ($Config{useithreads}) {
	require 'threads/shared/semaphore.pm';
	for my $meth (qw(new up down)) {
	    no strict 'refs';
	    *{"Thread::Semaphore::$meth"} = \&{"threads::shared::semaphore::$meth"};
	}
    } elsif ($Config{use5005threads}) {
	for my $meth (qw(new up down)) {
	    no strict 'refs';
	    *{"Thread::Semaphore::$meth"} = \&{"Thread::Semaphore::${meth}_othread"};
	}
    } else {
        require Carp;
        Carp::croak("This Perl has neither ithreads nor 5005threads");
    }
}


=head1 NAME

Thread::Semaphore - thread-safe semaphores (for old code only)

=head1 CAVEAT

For new code the use of the C<Thread::Semaphore> module is discouraged and
the direct use of the C<threads>, C<threads::shared> and
C<threads::shared::semaphore> modules is encouraged instead.

For the whole story about the development of threads in Perl, and why you
should B<not> be using this module unless you know what you're doing, see the
CAVEAT of the C<Thread> module.

=head1 SYNOPSIS

    use Thread::Semaphore;
    my $s = new Thread::Semaphore;
    $s->up;	# Also known as the semaphore V -operation.
    # The guarded section is here
    $s->down;	# Also known as the semaphore P -operation.

    # The default semaphore value is 1.
    my $s = new Thread::Semaphore($initial_value);
    $s->up($up_value);
    $s->down($up_value);

=head1 DESCRIPTION

Semaphores provide a mechanism to regulate access to resources. Semaphores,
unlike locks, aren't tied to particular scalars, and so may be used to
control access to anything you care to use them for.

Semaphores don't limit their values to zero or one, so they can be used to
control access to some resource that may have more than one of. (For
example, filehandles) Increment and decrement amounts aren't fixed at one
either, so threads can reserve or return multiple resources at once.

=head1 FUNCTIONS AND METHODS

=over 8

=item new

=item new NUMBER

C<new> creates a new semaphore, and initializes its count to the passed
number. If no number is passed, the semaphore's count is set to one.

=item down

=item down NUMBER

The C<down> method decreases the semaphore's count by the specified number,
or one if no number has been specified. If the semaphore's count would drop
below zero, this method will block until such time that the semaphore's
count is equal to or larger than the amount you're C<down>ing the
semaphore's count by.

=item up

=item up NUMBER

The C<up> method increases the semaphore's count by the number specified,
or one if no number's been specified. This will unblock any thread blocked
trying to C<down> the semaphore if the C<up> raises the semaphore count
above what the C<down>s are trying to decrement it by.

=back

=cut

sub new_othread {
    my $class = shift;
    my $val = @_ ? shift : 1;
    bless \$val, $class;
}

sub down_othread : locked : method {
    my $s = shift;
    my $inc = @_ ? shift : 1;
    cond_wait $s until $$s >= $inc;
    $$s -= $inc;
}

sub up_othread : locked : method {
    my $s = shift;
    my $inc = @_ ? shift : 1;
    ($$s += $inc) > 0 and cond_broadcast $s;
}

1;

package p5iq_web;
use Dancer2;

use P5iq::Search;
use Data::Dumper;

our $VERSION = '0.1';

get '/' => sub {
    my $query = params->{'q'};
    my $search_args = params->{'search_args'};

    my $res;
    my $freq_hash_keys_res;
    my $freq_args_res;
    my $freq_invocant_res;
    if($search_args =~ /^variable_/){
        $res = locate_variable( $query, (substr $search_args, 9));
        $freq_hash_keys_res = freq_hash_keys( $query );
    }
    elsif( $search_args =~ /^sub_/ ){
        $res = locate_sub( $query, (substr $search_args, 4));
        $freq_invocant_res = freq_invocant( $query );
        $freq_args_res = freq_args( $query );
    }
    elsif( $search_args =~ /^value/ ){
        $res = locate_value( $query, $search_args);
    }
    else{
    }


    template 'index', {
        'query' => $query,
        'search_args' => $search_args,
        'results' => $res,
        'freq_hash_keys' => $freq_hash_keys_res,
        'freq_invocant' => $freq_invocant_res,
        'freq_args' => $freq_args_res,
    };
};


my $default_call_back = sub {
    my $res = shift;
    my @ret;
    foreach ( @{$res->{hits}{hits}} ){
        my $src = $_->{_source};
        push @ret, {
            file => $src->{file},
                 line_number  => $src->{line_number},
                 content  => $src->{content},
        }
    }
    return \@ret;
};

sub locate_variable{
    my ($query, $args) = @_;
    my %args = ( $args => 1 );
    P5iq::Search::locate_variable(\%args, $query, $default_call_back);
}

sub locate_sub{
    my ($query, $args) = @_;
    my %args = ( $args => 1 );
    P5iq::Search::locate_sub(\%args, $query, $default_call_back);
}

sub locate_value{
    my ($query, $args) = @_;
    my %args = ( $args => 1 );
    P5iq::Search::locate_value(\%args, $query, $default_call_back);
}

sub freq_hash_keys {
    my ($query) = @_;
    my %args;
    P5iq::Search::frequency_hash_keys(\%args, $query,
        sub {
            my $res = shift;
            my @ret;
            for (@{$res->{aggregations}{hash_keys}{buckets}}) {
                my $k = substr($_->{key}, length('subscript::content=') - 1 );
                push @ret, {
                    doc_count => $_->{doc_count},
                    content => $k,
                }
            }
            return \@ret;
        }
    );
}

sub freq_invocant {
    my ($query) = @_;
    my %args;
    P5iq::Search::frequency_invocant(\%args, $query,
        sub {
            my $res = shift;
            my @ret;
            for (@{$res->{aggregations}{invocant}{buckets}}) {
                my $k = $_->{key} =~ s/^method:context=//r;
                push @ret, {
                    doc_count => $_->{doc_count},
                    content => $k,
                }
            }
            return \@ret;
        }
    );
}

sub freq_args {
    my ($query) = @_;
    my %args;
    P5iq::Search::frequency_invocant(\%args, $query,
        sub {
            my $res = shift;
            my @ret;
            for (@{$res->{aggregations}{args}{buckets}}) {
                my (undef,$k) = split("=", $_->{key}, 2);
                push @ret, {
                    doc_count => $_->{doc_count},
                    content => $k,
                }
            }
            return \@ret;
        }
    );
}

true;

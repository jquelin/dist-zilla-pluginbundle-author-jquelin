use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::JQUELIN;
# ABSTRACT: build & release a distribution like jquelin

use Dist::Zilla::PluginBundle::Git;
use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
    my ($self, $section) = @_;
    my $class = ref($self) || $self;
    my $arg   = $section->{payload};

    # params for AutoVersion
    my $major_version  = defined $arg->{major_version} ? $arg->{major_version} : 1;
    my $version_format =
          q<{{ $major }}.{{ cldr('yyDDD') }}>
        . sprintf('%01u', ($ENV{N} || 0))
        . ($ENV{DEV} ? (sprintf '_%03u', $ENV{DEV}) : '');

    # long list of plugins
    my @wanted = (
        # -- static meta-information
        [   AutoVersion => {
                major     => $major_version,
                format    => $version_format,
                time_zone => 'Europe/Paris',
            }
        ],

        # -- fetch & generate files
        [ AllFiles     => {} ],
        [ CompileTests => {} ],
        [ CriticTests  => {} ],
        [ MetaTests    => {} ],
        [ PodTests     => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        [ AutoPrereq => {} ],

        # -- munge files
        [ ExtraTests  => {} ],
        [ NextRelease => {} ],
        [ PkgVersion  => {} ],
        [ PodWeaver   => {} ],
        [ Prepender   => { copyright => 1 } ],

        # -- dynamic meta-information
        [ InstallDirs             => {} ],
        [ 'MetaProvides::Package' => {} ],

        # -- generate meta files
        [ License     => {} ],
        [ ModuleBuild => {} ],
        [ MetaYAML    => {} ],
        [ Readme      => {} ],
        [ Manifest    => {} ], # should come last

        # -- release
        [ CheckChangeLog => {} ],
        #[ @Git],
        [ UploadToCPAN   => {} ],
    );

    # create list of plugins
    my $prefix = 'Dist::Zilla::Plugin::';
    my @plugins =
        map { [ "$class/$prefix$_->[0]" => "$prefix$_->[0]" => $_->[1] ] }
        @wanted;

    # add git plugins
    my @gitplugins = Dist::Zilla::PluginBundle::Git->bundle_config( {
        name    => "$class/Git",
        payload => { },
    } );
    push @plugins, @gitplugins;

    # make sure all plugins exist
    eval "require $_->[1]" or die for @plugins; ## no critic ProhibitStringyEval

    return @plugins;
}


__PACKAGE__->meta->make_immutable;
no Moose;
1;
__END__

=for Pod::Coverage::TrustPod
    bundle_config

=head1 SYNOPSIS

In your F<dist.ini>:

    [@JQUELIN]
    major_version = 1        ; this is the default

=head1 DESCRIPTION

This is a plugin bundle to load all plugins that I am using. It is
equivalent to:

    [AutoVersion]

    ; -- fetch & generate files
    [AllFiles]
    [CompileTests]
    [CriticTests]
    [MetaTests]
    [PodTests]

    ; -- remove some files
    [PruneCruft]
    [ManifestSkip]

    ; -- get prereqs
    [AutoPrereq]

    ; -- munge files
    [ExtraTests]
    [NextRelease]
    [PkgVersion]
    [PodWeaver]
    [Prepender]
    copyright = 1

    ; -- dynamic meta-information
    [InstallDirs]
    [MetaProvides::Package]

    ; -- generate meta files
    [License]
    [ModuleBuild]
    [MetaYAML]
    [Readme]
    [Manifest] ; should come last

    ; -- release
    [CheckChangeLog]
    [@Git]
    [UploadToCPAN]

The C<major_version> option is passed as C<major> option to the
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> plugin.


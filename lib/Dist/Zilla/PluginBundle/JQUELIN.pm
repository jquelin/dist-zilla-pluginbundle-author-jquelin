use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::JQUELIN;
# ABSTRACT: build & release a distribution like jquelin

use Moose;
use Moose::Autobox;

with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
    my ($self, $section) = @_;
    my $class = ( ref $self ) || $self;
    my $arg   = $section->{payload};

    # bundle all git plugins
    my @classes =
        map { "Dist::Zilla::Plugin::Git::$_" }
        qw{ Check Commit Tag Push };

    # make sure all plugins exist
    eval "require $_; 1" or die for @classes; ## no critic ProhibitStringyEval

    return @classes->map(sub { [ "$class/$_" => $_ => $arg ] })->flatten;
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
    major = 1        ; this is the default

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

The C<major> option is passed to the
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> plugin.


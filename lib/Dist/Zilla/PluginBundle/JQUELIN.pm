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

    # params for autoprereq
    my $prereq_params = defined $arg->{skip_prereq}
        ? { skip => $arg->{skip_prereq} }
        : {};

    # params for pod weaver
    $arg->{weaver} ||= 'pod';

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
        [ AutoPrereq => $prereq_params ],

        # -- munge files
        [ ExtraTests  => {} ],
        [ NextRelease => {} ],
        [ PkgVersion  => {} ],
        [ ( $arg->{weaver} eq 'task' ? 'TaskWeaver' : 'PodWeaver' ) => {} ],
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
    major_version = 1          ; this is the default
    weaver        = pod        ; default, can also be 'task'
    skip_prereq   = ::Test$    ; no default


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

The following options are accepted:

=over 4

=item * C<major_version> - passed as C<major> option to the
L<AutoVersion|Dist::Zilla::Plugin::AutoVersion> plugin. Default to 1.

=item * C<weaver> - can be either C<pod> (default) or C<task>, to load
respectively either L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> or
L<TaskWeaver|Dist::Zilla::Plugin::TaskWeaver>.

=item * C<skip_prereq> - passed as C<skip> option to the
L<AutoPrereq|Dist::Zilla::Plugin::AutoPrereq> plugin if set. No default.

=back


=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * Search CPAN

L<http://search.cpan.org/dist/Dist-Zilla-PluginBundle-JQUELIN>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-JQUELIN>

=item * Mailing-list (same as dist-zilla)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-pluginbundle-jquelin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-JQUELIN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-JQUELIN>

=back

See also: L<Dist::Zilla::PluginBundle>.

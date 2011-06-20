use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::JQUELIN;
# ABSTRACT: build & release a distribution like jquelin

use Class::MOP;
use Moose;
use Moose::Autobox;

# plugins used
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::AutoVersion;
use Dist::Zilla::Plugin::Bugtracker;
use Dist::Zilla::Plugin::CheckChangeLog;
use Dist::Zilla::Plugin::CompileTests 1.100220;
#use Dist::Zilla::Plugin::CriticTests;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::ExtraTests;
use Dist::Zilla::Plugin::GatherDir;
use Dist::Zilla::Plugin::HasVersionTests;
use Dist::Zilla::Plugin::Homepage;
#use Dist::Zilla::Plugin::InstallGuide;
use Dist::Zilla::Plugin::KwaliteeTests;
use Dist::Zilla::Plugin::License;
use Dist::Zilla::Plugin::Manifest;
use Dist::Zilla::Plugin::ManifestSkip;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaYAML;
#use Dist::Zilla::Plugin::MetaTests;
use Dist::Zilla::Plugin::ModuleBuild;
use Dist::Zilla::Plugin::MinimumVersionTests;
use Dist::Zilla::Plugin::NextRelease 2.101230;  # time_zone param
use Dist::Zilla::Plugin::PkgVersion;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PodWeaver;
#use Dist::Zilla::Plugin::PortabilityTests;
use Dist::Zilla::Plugin::Prepender 1.100130;
use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::PruneFiles;
use Dist::Zilla::Plugin::Readme;
use Dist::Zilla::Plugin::ReportVersions::Tiny;
use Dist::Zilla::Plugin::Repository;
use Dist::Zilla::Plugin::ShareDir;
use Dist::Zilla::Plugin::TaskWeaver;
#use Dist::Zilla::Plugin::UnusedVarsTests;
use Dist::Zilla::Plugin::UploadToCPAN;
use Dist::Zilla::PluginBundle::Git;

with 'Dist::Zilla::Role::PluginBundle';

sub bundle_config {
    my ($self, $section) = @_;
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

    # params for compiletests
    my $compile_params = {};
    $compile_params->{fake_home} = $arg->{fake_home}
        if defined $arg->{fake_home};
    $compile_params->{skip} = $arg->{skip_compile}
        if defined $arg->{skip_compile};

    # params for pod weaver
    $arg->{weaver} ||= 'pod';

    my $release_branch = 'releases';

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
        [ GatherDir              => {} ],
        [ CompileTests           => $compile_params ],
        #[ CriticTests            => {} ],
        [ HasVersionTests        => {} ],
        [ KwaliteeTests          => {} ],
        #[ MetaTests              => {} ],
        [ MinimumVersionTests    => {} ],
        [ PodCoverageTests       => {} ],
        [ PodSyntaxTests         => {} ],
        #[ PortabilityTests       => {} ],
        [ 'ReportVersions::Tiny' => {} ],
        #[ UnusedVarsTests        => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ PruneFiles   => { match => '~$' } ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        [ AutoPrereqs => $prereq_params ],

        # -- munge files
        [ ExtraTests  => {} ],
        [ NextRelease => { time_zone => 'Europe/Paris' } ],
        [ PkgVersion  => {} ],
        [ ( $arg->{weaver} eq 'task' ? 'TaskWeaver' : 'PodWeaver' ) => {} ],
        [ Prepender   => {} ],

        # -- dynamic meta-information
        [ ExecDir                 => {} ],
        [ ShareDir                => {} ],
        [ Bugtracker              => {} ],
        [ Homepage                => {} ],
        [ Repository              => {} ],
        [ 'MetaProvides::Package' => {} ],
        [ MetaConfig              => {} ],

        # -- generate meta files
        [ License      => {} ],
        [ MetaYAML     => {} ],
        [ MetaJSON     => {} ],
        [ ModuleBuild  => {} ],
        #[ InstallGuide => {} ],
        [ Readme       => {} ],
        [ Manifest     => {} ], # should come last

        # -- release
        [ CheckChangeLog => {} ],
        [ "Git::Check"   => {} ],
        [ "Git::Commit"  => {} ],
        [ "Git::CommitBuild" => {
                branch         => '',
                release_branch => $release_branch,
            } ],
        [ "Git::Tag"     => "TagMaster"  => {} ],
        [ "Git::Tag"     => "TagRelease" => {
                tag_format => 'cpan-v%v',
                branch     => $release_branch,
            } ],
        [ "Git::Push"    => {} ],

        #[ @Git],
        [ UploadToCPAN   => {} ],
    );

    # create list of plugins
    my @plugins;
    for my $wanted (@wanted) {
        my ($plugin, $name, $arg);
        if ( scalar(@$wanted) == 2 ) {
            ($plugin, $arg) = @$wanted;
            $name = $plugin;
        } else {
            ($plugin, $name, $arg) = @$wanted;
        }
        my $class = "Dist::Zilla::Plugin::$plugin";
        Class::MOP::load_class($class); # make sure plugin exists
        push @plugins, [ "$section->{name}/$name" => $class => $arg ];
    }

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
    skip_compile  = bin/       ; no default


=head1 DESCRIPTION

This is a plugin bundle to load all plugins that I am using. It is
equivalent to:

    [AutoVersion]

    ; -- fetch & generate files
    [GatherDir]
    [CompileTests]
    [HasVersionTests]
    [KwaliteeTests]
    [MinimumVersionTests]
    [PodCoverageTests]
    [PodSyntaxTests]
    [ReportVersions::Tiny]

    ; -- remove some files
    [PruneCruft]
    [PruneFiles]
    match = ~$
    [ManifestSkip]

    ; -- get prereqs
    [AutoPrereqs]

    ; -- munge files
    [ExtraTests]
    [NextRelease]
    [PkgVersion]
    [PodWeaver]
    [Prepender]

    ; -- dynamic meta-information
    [ExecDir]
    [ShareDir]
    [Bugtracker]
    [Homepage]
    [Repository]
    [MetaProvides::Package]
    [MetaConfig]

    ; -- generate meta files
    [License]
    [ModuleBuild]
    [MetaYAML]
    [MetaJSON]
    [Readme]
    [Manifest] ; should come last

    ; -- release
    [CheckChangeLog]
    [Git::Check],
    [Git::Commit],
    [Git::CommitBuild]
    branch =
    release_branch = releases
    [Git::Tag / TagMaster]
    [Git::Tag / TagRelease]
    tag_format = cpan-v%v
    branch     = releases
    [Git::Push],
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

=item * C<skip_compile> - passed as C<skip> option to the
L<CompileTests|Dist::Zilla::Plugin::CompileTests> plugin if set. No
default.

=item * C<fake_home> - passed to
L<CompileTests|Dist::Zilla::Plugin::CompileTests> to control whether
to fake home.

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

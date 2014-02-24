use 5.008;
use strict;
use warnings;

package Dist::Zilla::PluginBundle::Author::JQUELIN;
# ABSTRACT: Build & release a distribution like jquelin

use Class::MOP;
use Moose;
use Moose::Autobox;

# plugins used
use Dist::Zilla::Plugin::AutoPrereqs;
use Dist::Zilla::Plugin::Bugtracker;
use Dist::Zilla::Plugin::CheckChangeLog;
use Dist::Zilla::Plugin::Covenant;
use Dist::Zilla::Plugin::ExecDir;
use Dist::Zilla::Plugin::ExtraTests;
use Dist::Zilla::Plugin::GatherDir;
use Dist::Zilla::Plugin::Git::Check;
use Dist::Zilla::Plugin::Git::Commit;
use Dist::Zilla::Plugin::Git::NextVersion;
use Dist::Zilla::Plugin::Git::Tag;
use Dist::Zilla::Plugin::Git::Push;
use Dist::Zilla::Plugin::HelpWanted;
use Dist::Zilla::Plugin::Homepage;
use Dist::Zilla::Plugin::License;
use Dist::Zilla::Plugin::Manifest;
use Dist::Zilla::Plugin::ManifestSkip;
use Dist::Zilla::Plugin::MetaConfig;
use Dist::Zilla::Plugin::MetaJSON;
use Dist::Zilla::Plugin::MetaProvides::Package;
use Dist::Zilla::Plugin::MetaYAML;
use Dist::Zilla::Plugin::ModuleBuild;
use Dist::Zilla::Plugin::NextRelease 2.101230;  # time_zone param
use Dist::Zilla::Plugin::PkgVersion;
use Dist::Zilla::Plugin::PodCoverageTests;
use Dist::Zilla::Plugin::PodSyntaxTests;
use Dist::Zilla::Plugin::PodWeaver;
use Dist::Zilla::Plugin::Prepender 1.100130;
use Dist::Zilla::Plugin::PruneCruft;
use Dist::Zilla::Plugin::PruneFiles;
use Dist::Zilla::Plugin::Readme;
use Dist::Zilla::Plugin::ReadmeMarkdownFromPod;
use Dist::Zilla::Plugin::ReportVersions::Tiny;
use Dist::Zilla::Plugin::Repository;
use Dist::Zilla::Plugin::ShareDir;
use Dist::Zilla::Plugin::TaskWeaver;
use Dist::Zilla::Plugin::Test::Compile 1.100220;
use Dist::Zilla::Plugin::TestRelease;
use Dist::Zilla::Plugin::UploadToCPAN;

with 'Dist::Zilla::Role::PluginBundle';
with 'Dist::Zilla::Role::PluginBundle::Config::Slicer';

sub bundle_config {
    my ($self, $section) = @_;
    my $arg   = $section->{payload};

    # params for pod weaver
    $arg->{weaver} ||= 'pod';

    my @dirty = ( "Changes", "dist.ini", "README.mkdn" );
    my @allow_dirty = ( allow_dirty => \@dirty );

    # long list of plugins
    my @wanted = (
        # -- static meta-information
        [ 'Git::NextVersion' => {} ],

        # -- fetch & generate files
        [ GatherDir              => {} ],
        [ 'Test::Compile'        => {} ],
        [ PodCoverageTests       => {} ],
        [ PodSyntaxTests         => {} ],
        [ 'ReportVersions::Tiny' => {} ],

        # -- remove some files
        [ PruneCruft   => {} ],
        [ PruneFiles   => { match => '~$' } ],
        [ ManifestSkip => {} ],

        # -- get prereqs
        [ AutoPrereqs => {} ],

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
        [ HelpWanted       => {} ],
        [ License          => {} ],
        [ Covenant         => {} ],
        [ MetaYAML         => {} ],
        [ MetaJSON         => {} ],
        [ ModuleBuild      => {} ],
        [ Readme           => {} ],
        [ ReadmeAnyFromPod => { location => "root", type => "markdown" } ],
        [ Manifest         => {} ], # should come last

        # -- release
        [ CheckChangeLog => {} ],
        [ TestRelease    => {} ],
        [ "Git::Check"   => { @allow_dirty } ],
        [ "Git::Commit"  => { @allow_dirty } ],
        [ "Git::Tag"     => {} ],
        [ "Git::Push"    => {} ],

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

    [@Author::JQUELIN]


=head1 DESCRIPTION

This is a plugin bundle to load all plugins that I am using. Check the
code to see exactly what are those plugins.

The following options are accepted:

=over 4

=item * C<weaver> - can be either C<pod> (default) or C<task>, to load
respectively either L<PodWeaver|Dist::Zilla::Plugin::PodWeaver> or
L<TaskWeaver|Dist::Zilla::Plugin::TaskWeaver>.

=back

B<NOTE:> This bundle consumes
L<Dist::Zilla::Role::PluginBundle::Config::Slicer> so you can also
specify attributes for any of the bundled plugins. The option should be
the plugin name and the attribute separated by a dot:

    [@JQUELIN]
    AutoPrereqs.skip = Bad::Module

See L<Config::MVP::Slicer/CONFIGURATION SYNTAX> for more information.


=head1 SEE ALSO

You can look for information on this module at:

=over 4

=item * CPAN

L<http://metacpan.org/release/Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * See open / report bugs

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * Mailing-list (same as dist-zilla)

L<http://www.listbox.com/subscribe/?list_id=139292>

=item * Git repository

L<http://github.com/jquelin/dist-zilla-pluginbundle-author-jquelin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dist-Zilla-PluginBundle-Author-JQUELIN>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dist-Zilla-PluginBundle-Author-JQUELIN>

=back

See also: L<Dist::Zilla::PluginBundle>.

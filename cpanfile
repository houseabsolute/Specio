requires "B" => "0";
requires "Carp" => "0";
requires "Class::Load" => "0";
requires "Class::Method::Modifiers" => "0";
requires "Devel::PartialDump" => "0";
requires "Devel::StackTrace" => "0";
requires "Eval::Closure" => "0";
requires "Exporter" => "0";
requires "Lingua::EN::Inflect" => "0";
requires "List::Util" => "1.33";
requires "Module::Runtime" => "0";
requires "Params::Util" => "0";
requires "Role::Tiny" => "0";
requires "Role::Tiny::With" => "0";
requires "Scalar::Util" => "0";
requires "Storable" => "0";
requires "Sub::Quote" => "0";
requires "Test::More" => "0.96";
requires "Try::Tiny" => "0";
requires "mro" => "0";
requires "overload" => "0";
requires "parent" => "0";
requires "perl" => "v5.10.0";
requires "re" => "0";
requires "strict" => "0";
requires "warnings" => "0";

on 'test' => sub {
  requires "ExtUtils::MakeMaker" => "0";
  requires "File::Spec" => "0";
  requires "IO::File" => "0";
  requires "Moo" => "0";
  requires "Test::Fatal" => "0";
  requires "Test::More" => "0.96";
  requires "Test::Requires" => "0";
  requires "lib" => "0";
  requires "namespace::autoclean" => "0";
  requires "open" => "0";
  requires "utf8" => "0";
};

on 'test' => sub {
  recommends "CPAN::Meta" => "2.120900";
};

on 'configure' => sub {
  requires "ExtUtils::MakeMaker" => "0";
};

on 'develop' => sub {
  requires "Code::TidyAll::Plugin::Test::Vars" => "0.02";
  requires "File::Spec" => "0";
  requires "IO::Handle" => "0";
  requires "IPC::Open3" => "0";
  requires "Moo" => "0";
  requires "Moose" => "2.1207";
  requires "Perl::Critic" => "1.126";
  requires "Perl::Tidy" => "20160302";
  requires "Pod::Coverage::TrustPod" => "0";
  requires "Pod::Wordlist" => "0";
  requires "Test::CPAN::Changes" => "0.19";
  requires "Test::CPAN::Meta::JSON" => "0.16";
  requires "Test::Code::TidyAll" => "0.24";
  requires "Test::EOL" => "0";
  requires "Test::Mojibake" => "0";
  requires "Test::More" => "0.96";
  requires "Test::NoTabs" => "0";
  requires "Test::Pod" => "1.41";
  requires "Test::Pod::Coverage" => "1.08";
  requires "Test::Pod::LinkCheck" => "0";
  requires "Test::Spelling" => "0.12";
  requires "Test::Vars" => "0.009";
  requires "Test::Version" => "1";
  requires "blib" => "1.01";
};

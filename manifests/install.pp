class homebrew::install {
  # based on: https://github.com/Homebrew/install/blob/932004ac080139249e8329eba639dce30c34d8d8/install
  $homebrew_prefix = "/usr/local"
  $homebrew_repository = "/usr/local/Homebrew"
  $brew_repo = "https://github.com/Homebrew/brew"
  $core_tap = "$homebrew_prefix/Homebrew/Library/Taps/homebrew/homebrew-core"
  $core_tap_repo = "https://github.com/Homebrew/homebrew-core"

  $directories = [ "$homebrew_repository",
                   '/usr/local/bin',
                   '/usr/local/etc',
                   '/usr/local/Cellar',
                   '/usr/local/Frameworks',
                   '/usr/local/include',
                   '/usr/local/lib',
                   '/usr/local/lib/pkgconfig',
                   '/usr/local/Library',
                   '/usr/local/sbin',
                   '/usr/local/share',
                   '/usr/local/var',
                   '/usr/local/var/log',
                   '/usr/local/share/locale',
                   '/usr/local/share/man',
                   '/usr/local/share/man/man1',
                   '/usr/local/share/man/man2',
                   '/usr/local/share/man/man3',
                   '/usr/local/share/man/man4',
                   '/usr/local/share/man/man5',
                   '/usr/local/share/man/man6',
                   '/usr/local/share/man/man7',
                   '/usr/local/share/man/man8',
                   '/usr/local/share/info',
                   '/usr/local/share/doc',
                   '/usr/local/share/aclocal' ]

  file { $directories:
    ensure   => directory,
    owner    => $homebrew::user,
    group    => 'admin',
    mode     => 0775,
  }

  exec { 'install-homebrew':
    cwd       => "$homebrew_repository",
    command   => "/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL $brew_repo/tarball/master | /usr/bin/tar xz -m --strip 1\"",
    creates   => "$homebrew_repository/bin/brew",
    logoutput => on_failure,
    timeout   => 0,
    require   => File[$directories],
    user      => "$homebrew::user",
  }

  file { [ "$homebrew_prefix/Homebrew/Library",
           "$homebrew_prefix/Homebrew/Library/Taps",
           "$homebrew_prefix/Homebrew/Library/Taps/homebrew",
           "$core_tap" ],
    ensure   => directory,
    owner    => $homebrew::user,
    group    => 'admin',
    mode     => 0775,
    require   => Exec['install-homebrew'],
  }

  exec { 'install-homebrew-core-tap':
    cwd       => "$core_tap",
    command   => "/bin/bash -o pipefail -c \"/usr/bin/curl -skSfL $core_tap_repo/tarball/master | /usr/bin/tar xz -m --strip 1\"",
    creates   => "$core_tap/README.md",
    logoutput => on_failure,
    timeout   => 0,
    require   => File["$core_tap"],
    user => "$homebrew::user",
  }

  file { '/usr/local/bin/brew':
    owner     => $homebrew::user,
    group     => 'admin',
    mode      => 0775,
    ensure    => link,
    target    => "$homebrew_repository/bin/brew",
    require   => Exec['install-homebrew-core-tap'],
  }
}

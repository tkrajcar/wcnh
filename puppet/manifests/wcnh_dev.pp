$ruby_version = "ruby-1.9.3"
group { "puppet":
   ensure => "present",
}
file { '/etc/motd':
  content => "WCNH MUSH Dev Box. To be used FOR GREAT JUSTICE.\n"
}

class { 'apt':
  always_apt_update => true
}

package { "pennmush": # dependencies for pennmush, JSON server, etc.
  ensure => installed,
  name => [
    'libyajl-dev',
    'git-core',
    'libpcre3-dev',
    'gdb',
    'gperf'
  ]
}

class installrvm {
  include rvm
  rvm::system_user { vagrant: ; }
}
class installruby {
    rvm_system_ruby {
      $ruby_version:
        ensure => 'present'
    }
    rvm_gemset {
      "${ruby_version}@wcnh_dev":
        ensure => present,
        require => Rvm_system_ruby[$ruby_version]
    }
}


class { 'mongodb':
  enable_10gen => true,
}

class { installrvm: }
class { installruby: require => Class[Installrvm] }

group { "puppet":
   ensure => "present",
}
file { '/etc/motd':
  content => "WCNH MUSH Dev Box. To be used FOR GREAT JUSTICE.\n"
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


package { "ruby": # dependencies for ruby
  ensure => installed,
  name => [
    'curl'
  ]
}

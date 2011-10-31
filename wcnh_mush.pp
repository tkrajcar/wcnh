group { "puppet":
   ensure => "present",
}
file { '/etc/motd':
  content => "WCNH MUSH Dev Box. To be used FOR GREAT JUSTICE.\n"
}
package { "git-core": 
  ensure => installed 
}
package { "vim":
  ensure => installed
}
package { "libpcre3-dev":
  ensure => installed
}
package { "gdb":
  ensure => installed
}
package { "libmysqlclient-dev":
  ensure => installed
}
package { "gperf":
  ensure => installed
}

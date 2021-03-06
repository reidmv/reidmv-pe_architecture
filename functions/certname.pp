function peadm::certname(
  Variant[Target, Array[Target,0,1], String] $target,
) >> Variant[String, Undef] {
  case $target {
    Target: {
      $target.vars['certname'] ? {
        default => $target.vars['certname'],
        undef   => $target.name
      }
    }
    Array[Target,1,1]: {
      $target[0].vars['certname'] ? {
        default => $target[0].vars['certname'],
        undef   => $target[0].name
      }
    }
    Array[Target,0,0]: {
      undef
    }
    String: {
      $target
    }
    default: {
      fail('Unexpected input type to peadm::certname function')
    }
  }
}

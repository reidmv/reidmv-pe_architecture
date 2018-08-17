plan pe_xl::configure (

  String[1]           $version = '2018.1.2',
  String[1]           $console_password,
  Hash                $r10k_sources = { },

  String[1]           $primary_master_host,
  String[1]           $puppetdb_database_host,
  Array[String[1]]    $compile_master_hosts = [ ],
  Array[String[1]]    $dns_alt_names = [ ],

  Optional[String[1]] $primary_master_replica_host = undef,
  Optional[String[1]] $puppetdb_database_replica_host = undef,

  Optional[String[1]] $load_balancer_host = undef,

  String[1]           $stagingdir = '/tmp',
) {

  $control_repo = $r10k_sources.reduce |$memo, $value| {
    $string = "${memo[0]}${value[0]}"
  }

  if $control_repo {
    run_task('pe_xl::code_manager', $primary_master_host,
      action => 'deploy',
      environment => $deploy_environment,
    )

  } else {
  
    $nm_module_tarball = 'WhatsARanjit-node_manager-0.7.1.tar.gz'
  
    # Download module tar files
    run_task('pe_xl::download', $primary_master_host,
      source => "https://forge.puppet.com/v3/files/${nm_module_tarball}", 
      path   => "/tmp/${nm_module_tarball}",
    )
  
    $pexl_module_tarball = 'reidmv-pe_xl-master.tar.gz'
  
    # Download module tar files
    run_task('pe_xl::download', $primary_master_host,
      source => 'https://github.com/reidmv/reidmv-pe_xl/archive/master.tar.gz', 
      path   => "/tmp/${pexl_module_tarball}",
    )
  
    run_command("/opt/puppetlabs/bin/puppet module install /tmp/${nm_module_tarball}", $primary_master_host)
    run_command("/opt/puppetlabs/bin/puppet module install /tmp/${pexl_module_tarball}", $primary_master_host)
    run_command('chown -R pe-puppet:pe-puppet /etc/puppetlabs/code', $primary_master_host)
  }

  run_task('pe_xl::configure_node_groups', $primary_master_host,
    primary_master_host => $primary_master_host,
  )

  run_task('pe_xl::puppet_runonce', [
    $primary_master_host,
    $puppetdb_database_host,
    $primary_master_replica_host,
    $puppetdb_database_replica_host,
  ])

  # Run the PE Replica Provision
  run_task('pe_xl::provision_replica', $primary_master_host,
    primary_master_replica => $primary_master_replica_host,
  )

  run_task('pe_xl::puppet_runonce', [
    $primary_master_host,
    $primary_master_replica_host,
  ])

  run_task(pe_xl::configure_replica_db_node_group, $primary_master_host,
    puppetdb_database_replica_host => $puppetdb_database_replica_host,
  )
  if $compile_master_hosts {
    run_task('pe_xl::puppet_runonce', $compile_master_hosts)
  }

  if $load_balancer_host {
    run_task('pe_xl::puppet_runonce', $load_balancer_host)
  }

  if $compile_master_hosts {
    run_task('pe_xl::puppet_runonce', $compile_master_hosts)
  }

  return('Configuration of Puppet Enterprise with replica succeeded.')
}

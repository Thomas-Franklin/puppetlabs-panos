#!/opt/puppetlabs/puppet/bin/ruby

# work around the fact that bolt (for now, see BOLT-132) is not able to transport additional code from the module
# this requires that the panos module is pluginsynced to the node executing the task
require 'puppet'
Puppet.settings.initialize_app_defaults(
  Puppet::Settings.app_defaults_for_run_mode(
    Puppet::Util::RunMode[:agent],
  ),
)
$LOAD_PATH.unshift(Puppet[:plugindest])

# setup logging to stdout/stderr which will be available to task executors
Puppet::Util::Log.newdestination(:console)
Puppet[:log_level] = 'debug'

#### the real task ###

require 'json'

def add_plugin_paths(install_dir)
  Dir.glob(File.join([install_dir, '*'])).each do |mod|
    $LOAD_PATH << File.join([mod, "lib"])
  end
end

require 'puppet/resource_api/transport/wrapper'

params = JSON.parse(ENV['PARAMS'] || STDIN.read)

add_plugin_paths(params['_installdir'])

credentials = params['_target'].each_with_object({}) { |(k, v), h| h[k.to_sym] = v }

wrapper = Puppet::ResourceApi::Transport::Wrapper.new('panos', params['credentials_file'])
api = Puppet::Transport::Panos::API.new(wrapper.transport.instance_variable_get(:@connection_info))

puts JSON.generate(apikey: api.apikey)

parameters = CloudConductorUtils::Consul.read_parameters[:cloudconductor]
roles = ENV['ROLE'].split(',')
hosts_paths_privileges_by_role(roles, parameters).each do |role, role_config|
  role_config[:paths].each do |path_config|
    config = amanda_config(role, path_config[:path])
    ruby_block "amrecover_#{config[:name]}" do
      block do
        require 'pty'
        require 'expect'
        sequence = [
          "setdisk #{path_config[:path]}",
          "lcd #{path_config[:path]}",
          'add *',
          'extract',
          'quit'
        ]
        amrecover = ['amrecover', '-C', "#{config[:name]}"].join(' ')
        PTY.getpty(amrecover) do |reader, writer, _pid|
          writer.sync = true
          reader.expect(/> $/, 60) do |match|
            exit 1 unless match
            writer.puts 'listhost'
          end
          reader.expect(/\n(201- .*)\n/, 60) do |match|
            exit 1 unless match
            sequence.unshift("sethost #{match[1].split(' ')[1]}")
          end
          until sequence.empty? || reader.eof?
            reader.expect(/(>|\?) $/, 60) do |match|
              exit 1 unless match
              case match[1]
              when />/
                command = sequence.shift
                writer.puts command
              when /\?/
                writer.puts 'Y'
              end
            end
          end
        end
      end
      only_if { path_config[:restore_enabled] }
    end
  end
end

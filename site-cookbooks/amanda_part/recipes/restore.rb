roles = ENV['ROLE'].split(',')
roles.each do |role|
  host_config[role.to_sym][:paths].each do |path_config|
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
          until sequence.empty? || reader.eof?
            reader.expect(/(>|\?) $/, 60) do |match|
              break unless match
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
    end
  end
end

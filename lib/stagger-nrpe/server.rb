
config_dir = ARGV[0] || '/etc/stagger-nrpe.d'

puts "Locading config from #{config_dir}"

$DEFS = CheckDefinitions.new
Dir.glob("#{config_dir}/*.rb").each do |f|
  begin
    Kernel.load(f)
  rescue => e
    p e
    puts e.backtrace.join("\n")
    something_useful e
  end
end

puts "Loaded #{$DEFS.count} definitions"

stagger_client = StaggerClient.new('localhost', '8990')

EM.run {
  EM.start_server "0.0.0.0", 5667, NrpeConnection, $DEFS, stagger_client
}

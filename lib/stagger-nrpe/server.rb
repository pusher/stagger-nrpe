config_dir = ARGV[0] || '/etc/stagger-nrpe.d'

Raven.configure do |config|
  config.dsn = 'https://d379ccf06e5540a8a7f256239f6b287a:5cf0b7edb57d436cb67d25721a02d9c9@app.getsentry.com/10704'
end
RAVEN_TAGS = {
    tags: {
      service: "stagger-nrpe",
      cluster: ENV['ENVIRONMENT'] || "development"
    })
  }

EM.error_handler { |e|
  Raven.capture_exception(e, RAVEN_TAGS)
}

puts "Loading config from #{config_dir}"

$DEFS = CheckDefinitions.new
Dir.glob("#{config_dir}/*.rb").each do |f|
  begin
    Kernel.load(f)
  rescue => e
    Raven.capture_exception(e, RAVEN_TAGS)
  end
end

puts "Loaded #{$DEFS.count} definitions"

stagger_client = StaggerClient.new('localhost', '8990')

EM.run {
  EM.start_server "0.0.0.0", 5667, NrpeConnection, $DEFS, stagger_client
}

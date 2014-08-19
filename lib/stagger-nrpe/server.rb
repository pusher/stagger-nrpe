config_dir = ARGV[0] || '/etc/stagger-nrpe.d'

unless ENVIRONMENT == 'development'
  Raven.configure do |config|
    config.dsn = 'https://d379ccf06e5540a8a7f256239f6b287a:5cf0b7edb57d436cb67d25721a02d9c9@app.getsentry.com/10704'
  end
end

def error_handler(e)
  Log.error e
  Log.error e.backtrace.join("\n")
  Raven.capture_exception(e, {
    tags: {
      service: "stagger-nrpe",
      cluster: ENVIRONMENT
    }
  })
end

EM.error_handler { |e|
  error_handler(e)
}

Log.info "Loading config from #{config_dir}"

$DEFS = CheckDefinitions.new
Dir.glob("#{config_dir}/*.rb").each do |f|
  begin
    if File.readable?(f)
      Log.info "Loading #{f}"
      Kernel.load(f)
    else
      Log.error "File #{f} unreadable, #{File.stat(f).inspect}"
    end
  rescue => e
    error_handler(e)
  end
end

Log.info "Loaded #{$DEFS.count} definitions"

stagger_client = StaggerClient.new('localhost', '8990')

EM.run {
  EM.start_server "0.0.0.0", 5667, NrpeConnection, $DEFS, stagger_client
}

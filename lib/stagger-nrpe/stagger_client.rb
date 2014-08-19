require 'em-http-request'
require 'json'

class StaggerClient

  def initialize(host, port)
    @host = host
    @port = port
  end

  def get(names)
    df = EM::DefaultDeferrable.new

    refresh_if_stale.callback {
      df.succeed(names.map { |name| @all[name].to_f })
    }.errback { |e|
      Log.warn("Failed to refresh values from stagger: #{e}")
      df.fail
    }

    df
  end

  private

  def refresh_if_stale
    if @refreshed.nil? || @refreshed < Time.now.to_i - 2
      refresh_metrics.callback { |all|
        @all = all
        @refreshed = Time.now.to_i
      }
    else
      df = EM::DefaultDeferrable.new
      df.succeed
      df
    end
  end

  def refresh_metrics
    df = EM::DefaultDeferrable.new

    http = EM::HttpRequest.new(URI("http://#{@host}:#{@port}/snapshot.json")).get
    http.callback {
      json = JSON.load(http.response)
      if json
        if json["Counters"]
          json["Counters"]["stagger.timestamp"] = json["Timestamp"]
          df.succeed(
            # Return a map of metric to something with yields a value from to_f
            json["Counters"].merge!(
              Hash[json["Dists"].map{ |k, v| [k, Distribution.from_json(v)] }]
            )
          )
        else
          df.fail("No 'Counters' in stagger response [#{json.inspect}]")
        end
      else
        df.fail('No JSON returned from stagger')
      end
    }.errback {
      df.fail
    }

    df
  end
end

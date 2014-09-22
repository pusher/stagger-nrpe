class NrpeConnection < EM::Connection

  def initialize(check_definitions, stagger_client)
    @check_definitions = check_definitions
    @stagger_client = stagger_client
    @data = ''
  end

  def receive_data(data)
    @data << data
    # Conveniently, NRPE is a fixed size request
    if @data.bytesize == NrpePacket::MAX_PACKET_SIZE
      process
    end
  end

  def process
    query = NrpePacket.read(@data)

    # ensure it doesn't specify any commands
    if query.buffer =~ /!/
      send_response(:critical, "Arguments not allowed")
      return
    end

    # find the command
    def_name = query.buffer

    # ensure it exists
    definition = @check_definitions.get(def_name)
    unless definition
      send_response(:unknown, "unknown definition #{def_name}")
      return
    end

    # get the value
    @stagger_client.get(definition[:metrics]).callback { |values|
      if values.compact.size != values.size
        send_response(:unknown, "Missing metrics in: #{definition[:metrics]}")
      else
        # test it
        begin
          status, desc = definition[:block].call(*values)
        rescue Exception => ex
          send_response(:unknown, "#{ex.to_s}\n#{ex.backtrace.join(%Q{\n})}")
        else
          send_response(status, desc)
        end
      end
    }.errback {
      send_response(:warning, "unable to connect to stagger")
    }
  rescue Exception => e
    send_response(:critical, "Error encountered while processing: #{e.message}")
  end

  private

  def send_response(code, message)
    send_data(NrpePacket.to_response(code, message))
    close_connection_after_writing
  end

end

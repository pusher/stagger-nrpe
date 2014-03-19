class NrpeConnection < EM::Connection

  def initialize(check_definitions, stagger_client)
    @check_definitions = check_definitions
    @stagger_client = stagger_client
  end

  def receive_data(data)
    query = NrpePacket.read(data)

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
    @stagger_client.get(definition[:metric]).callback { |value|
      unless value
        send_response(:unknown, "no such metric #{definition[:metric]}")
        return
      end

      # test it
      status, desc = definition[:block].call(value.to_f)
      send_response(status, desc)
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
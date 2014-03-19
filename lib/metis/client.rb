# Apache licenced original at from https://github.com/krobertson/metis/blob/master/lib/metis/client.rb

require 'timeout'

class NrpeClientConnection < EM::Connection

  def process
    query = NrpePacket.read(@socket)

    # ensure it doesn't specify any commands
    if query.buffer =~ /!/
      send_response(STATUS_CRITICAL, "Arguments not allowed")
      return
    end

    # find the command
    check_name = query.buffer.to_sym
    check_definition = @context.definitions[check_name]

    # ensure it exists
    unless check_definition
      send_response(STATUS_WARNING, "Command #{query.buffer} not found")
      return
    end

    # run it
    provider = Provider.new(check_definition, @context)
    provider.run
    send_response(provider.response_code, provider.response_message)

  rescue Exception => e
    send_response(STATUS_CRITICAL, "Error encountered while processing: #{e.message}")

  ensure
    @socket.close
  end

  private

  def send_response(result_code, message)
    response = NrpePacket.new
    response.packet_type = :response
    response.result_code = result_code
    response.buffer = message
    @socket.write(response.to_bytes)
    true
  end

end
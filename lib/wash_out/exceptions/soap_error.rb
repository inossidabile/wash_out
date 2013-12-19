module WashOut
  # A SOAPError exception can be raised to return a correct SOAP error
  # response.
  class SOAPError < Exception
    attr_accessor :code
    def initialize(message, code=nil)
      super(message)
      @code = code
    end
  end
end

# Backward compatibility hack
class SOAPError < WashOut::SOAPError; end
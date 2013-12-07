module WashOut
  #
  # An exception reflecting expected logical error
  #
  # Such exception (or its descendants) will be intercepted and rendered
  # into proper SOAP error XML response.
  #
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
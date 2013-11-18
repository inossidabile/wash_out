module WashOut
  class SoapFault < StandardError
    include ActiveModel::MassAssignmentSecurity

    @attrs = [ :faultCode, :faultString, :errors]
    attr_accessor *@attrs
    attr_accessible *@attrs

    alias message faultString

    def initialize(faultCode , faultString, error_messages = [])
      @faultCode = faultCode
      @faultString = faultString
      @errors = []
      if  !error_messages.blank? and error_messages.is_a?(Array)
        error_messages.each do |hash|
          @errors << {:related => hash.try(:[], :related), :message => hash.try(:[], :message), :arguments => hash.try(:[], :arguments)}
        end
      end
    end

    # returns a hash
    def to_h
      {"faultCode" => @faultCode, "faultString" => @faultString, "errors" => @errors}
    end

  end
end
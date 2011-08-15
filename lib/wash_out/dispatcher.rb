module WashOut
  module Dispatcher
    def wsdl
      @map       = self.class.wash_with_soap_map
      @name      = controller_path.gsub('/', '_')
      @namespace = 'urn:WashOut'
      
      render :template => 'wash_with_soap/wsdl'
    end
    
    def soap
      @map     = self.class.wash_with_soap_map
      @method  = request.env['HTTP_SOAPACTION'].gsub(/^\"(.*)\"$/, '\1')
      @current = @map[@method] || @map[@method.to_sym]
      
      wash_out_error("Method does not exist") and return if @current.blank?
      
      data = Crack::XML.parse(request.raw_post).values.first.select{|k,v| k[-4,4] == "Body"}.values.first[@method]
      
      @soap   = @current[:in].load(data)
      @result = @current[:out].load(send @method.to_sym)
      
      render :template => 'wash_with_soap/response'
    end
    
  private
    
    def wash_out_error(description)
      @error = description and render :template => 'wash_with_soap/error'
    end
  end
end
xml.instruct!
xml.definitions 'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema', 
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/', 
                'xmlns:soapenc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:typens' => @namespace,
                'targetNamespace' => @namespace,
                'xmlns' => 'http://schemas.xmlsoap.org/wsdl/' do
  xml.types do
    xml.tag! "xsd:schema", :xmlns => 'http://www.w3.org/2001/XMLSchema', :targetNamespace => @namespace
    
    @map.each do |operation, formats|
      formats.each do |kind, params|
        if params.struct?
          params.value.each{|foo, p| wsdl_type xml, p}
        end
      end
    end
  end
  
  @map.each do |operation, formats|
    xml.message :name => "#{operation}" do
      if formats[:in].struct?
        formats[:in].value.each do |name, p|
          xml.part wsdl_occurence(p, :name => p.name, :type => p.namespaced_type)
        end
      else
        xml.part wsdl_occurence(formats[:in], :name => operation, :type => formats[:in].namespaced_type)
      end
    end
    xml.message :name => "#{operation}_responce" do
      if formats[:out].struct?
        formats[:out].value.each do |name, p|
          xml.part wsdl_occurence(p, :name => p.name, :type => p.namespaced_type)
        end
      else
        xml.part wsdl_occurence(formats[:out], :name => operation, :type => formats[:out].namespaced_type)
      end
    end
  end
  
  xml.portType :name => "#{@name}_port" do
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.input :message => "typens:#{operation}"
        xml.otput :message => "typens:#{operation}_responce"
      end
    end
  end
  
  xml.binding :name => "#{@name}_binding", :type => "typens:#{@name}_port" do
    xml.tag! "soap:binding", :style => 'rpc', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.tag! "soap:operation", :soapAction => operation
        xml.input do
          xml.tag! "soap:body", 
            :use => "encoded", :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/',
            :namespace => @namespace
        end
        xml.output do
          xml.tag! "soap:body", 
            :use => "encoded", :encodingStyle => 'http://schemas.xmlsoap.org/soap/encoding/',
            :namespace => @namespace
        end
      end
    end
  end
  
  xml.service :name => "service" do
    xml.port :name => "#{@name}_port", :binding => "#{@name}_binding" do
      xml.tag! "soap:address", :location => url_for(:action => :soap, :only_path => false)
    end
  end
end
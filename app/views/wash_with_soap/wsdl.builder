xml.instruct!
xml.definitions 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'name' => @name,
                'targetNamespace' => @namespace do
  xml.types do
    xml.tag! "xsd:schema", :targetNamespace => @namespace do
      @map.each do |operation, formats|
        formats[:in].each do |p|
          wsdl_type xml, p
        end
      end
    end
  end

  xml.portType :name => "#{@name}_port" do
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}"
        xml.output :message => "tns:#{operation}_response"
      end
    end
  end

  xml.binding :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
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
    xml.port :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :location => url_for(:action => '_action', :only_path => false)
    end
  end
  
  @map.each do |operation, formats|
    xml.message :name => "#{operation}" do
      formats[:in].each do |p|
        xml.part wsdl_occurence(p, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.message :name => "#{operation}_response" do
      formats[:out].each do |p|
        xml.part wsdl_occurence(p, :name => p.name, :type => p.namespaced_type)
      end
    end
  end
end
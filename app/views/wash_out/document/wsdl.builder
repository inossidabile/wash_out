xml.instruct!
xml.definitions 'xmlns' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:tns' => @namespace,
                'xmlns:soap' => 'http://schemas.xmlsoap.org/wsdl/soap/',
                'xmlns:xsd' => 'http://www.w3.org/2001/XMLSchema',
                'xmlns:soap-enc' => 'http://schemas.xmlsoap.org/soap/encoding/',
                'xmlns:wsdl' => 'http://schemas.xmlsoap.org/wsdl/',
                'xmlns:wsam' => 'http://www.w3.org/2007/05/addressing/metadata',
                'xmlns:wsx' => 'http://schemas.xmlsoap.org/ws/2004/09/mex',
                'xmlns:wsap' => 'http://schemas.xmlsoap.org/ws/2004/08/addressing/policy',
                'xmlns:msc' => 'http://schemas.microsoft.com/ws/2005/12/wsdl/contract',
                'xmlns:wsp' => 'http://schemas.xmlsoap.org/ws/2004/09/policy',
                'xmlns:wsu' => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd',
                'xmlns:soap12' => 'http://schemas.xmlsoap.org/wsdl/soap12/',
                'xmlns:wsa10' => 'http://www.w3.org/2005/08/addressing',
                'xmlns:wsaw' => 'http://www.w3.org/2006/05/addressing/wsdl',
                'xmlns:wsa' => 'http://schemas.xmlsoap.org/ws/2004/08/addressing',
                'name' => @name,
                'targetNamespace' => @namespace do

  xml.types do
    xml.tag! "schema", :targetNamespace => @namespace, :xmlns => 'http://www.w3.org/2001/XMLSchema' do
      defined = []
      @map.each do |operation, formats|
        (formats[:in] + formats[:out]).each do |p|
          wsdl_type xml, p, defined
        end
      end
    end
  end

  xml.portType :name => "#{@name}_port" do
    @map.each do |operation, formats|
      xml.operation :name => operation do
        xml.input :message => "tns:#{operation}"
        xml.output :message => "tns:#{formats[:response_tag]}"
      end
    end
  end

  xml.binding :name => "#{@name}_binding", :type => "tns:#{@name}_port" do
    xml.tag! "soap:binding", :style => 'document', :transport => 'http://schemas.xmlsoap.org/soap/http'
    @map.keys.each do |operation|
      xml.operation :name => operation do
        xml.tag! "soap:operation", :soapAction => operation
        xml.input do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
        xml.output do
          xml.tag! "soap:body",
            :use => "literal",
            :namespace => @namespace
        end
      end
    end
  end

  xml.service :name => "service" do
    xml.port :name => "#{@name}_port", :binding => "tns:#{@name}_binding" do
      xml.tag! "soap:address", :location => send("#{@name}_action_url")
    end
  end

  @map.each do |operation, formats|
    xml.message :name => "#{operation}" do
      formats[:in].each do |p|
        xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
    xml.message :name => formats[:response_tag] do
      formats[:out].each do |p|
        xml.part wsdl_occurence(p, false, :name => p.name, :type => p.namespaced_type)
      end
    end
  end
end

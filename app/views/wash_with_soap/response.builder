xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
                          "xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema',
                          "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
                          "xmlns:tns" => @namespace do
  xml.tag! "soap:Body" do
    key = "#{@operation}#{WashOut::Engine.camelize_wsdl ? 'Response' : '_response'}"

    xml.tag! key, "xmlns" => @namespace do
      wsdl_data xml, result
    end
  end
end

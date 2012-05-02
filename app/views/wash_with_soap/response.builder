xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
                          "xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema',
                          "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
                          "xmlns:tns" => @namespace do
  xml.tag! "soap:Body" do
    key = "tns:#{@operation}#{WashOut::Engine.camelize_wsdl ? 'Response' : '_response'}"

    xml.tag! key do
      wsdl_data xml, result
    end
  end
end
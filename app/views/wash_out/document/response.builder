xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
                          "xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema',
                          "xmlns:tns" => @namespace do
  xml.tag! "soap:Body" do
    key = "tns:#{@operation}#{controller.soap_config.camelize_wsdl ? 'Response' : '_response'}"

    xml.tag! @action_spec[:response_tag] || key do
      wsdl_data xml, result
    end
  end
end

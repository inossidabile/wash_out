xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
                          "xmlns:xsd" => 'http://www.w3.org/2001/XMLSchema',
                          "xmlns:ns2" => @namespace do
  if !header.nil?
    xml.tag! "soap:Header" do
      xml.tag! "ns2:#{@action_spec[:response_tag]}" do
        wsdl_data xml, header
      end
    end
  end
  xml.tag! "soap:Body" do
    xml.tag! "ns2:#{@action_spec[:response_tag]}" do
      wsdl_data xml, result
    end
  end
end

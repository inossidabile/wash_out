xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/',
             "xmlns:xsi" => 'http://www.w3.org/2001/XMLSchema-instance',
             "xmlns:tns" => @namespace do
  xml.tag! "soap:Body" do
    xml.tag! "tns:#{@operation}_response" do
      wsdl_data xml, result
    end
  end
end
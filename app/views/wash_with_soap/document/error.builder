xml.instruct!
xml.tag! "soap:Envelope", "xmlns:soap" => 'http://schemas.xmlsoap.org/soap/envelope/' do
  xml.tag! "soap:Body" do
    xml.tag! "soap:Fault" do
      xml.faultcode "soap:Server"
      xml.faultstring error_message
    end
  end
end
